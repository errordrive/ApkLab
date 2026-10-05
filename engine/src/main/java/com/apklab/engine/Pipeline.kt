package com.apklab.engine

import net.dongliu.apk.parser.ApkFile
import org.jf.dexlib2.DexFileFactory
import org.jf.dexlib2.Opcodes
import java.io.File
import java.nio.file.Files

/**
 * High-level engine API consumed by the app.
 *
 * scan()  -> analyze APK, return detections (report-first step)
 * buildReport() -> human-readable PatchReport
 * patch() -> gut + nop + repack + align + sign, returns signed APK file
 */
object Engine {

    fun scan(apkFile: File, log: (String) -> Unit = {}): ScanResult {
        val info = readApkInfo(apkFile)
        val dexNames = ApkIO.listDexNames(apkFile)
        if (dexNames.isEmpty()) {
            log("No classes.dex found in APK")
            return ScanResult(info, emptyList())
        }
        val tmp = Files.createTempDirectory("apklab-scan").toFile()
        try {
            // Load all dex files first, then scan jointly so hooks in a
            // different classesN.dex than the injected class are still found.
            val dexFiles = mutableMapOf<String, org.jf.dexlib2.iface.DexFile>()
            for (dexName in dexNames) {
                log("Loading $dexName...")
                val dexFile = File(tmp, dexName)
                ApkIO.extractDex(apkFile, dexName, dexFile)
                dexFiles[dexName] =
                    DexFileFactory.loadDexFile(dexFile, Opcodes.getDefault())
            }
            log("Scanning ${dexFiles.size} dex file(s)...")
            val detections = Detector.scanMultiDex(dexFiles)
            for (d in detections) {
                log("Suspicious: ${d.classType} [${d.badges.joinToString(",")}] " +
                    "(${d.methodsToGut.size} method(s), ${d.hookSites.size} hook(s))")
            }
            if (detections.isEmpty()) log("No suspicious dialog code found")
            return ScanResult(info, detections)
        } finally {
            tmp.deleteRecursively()
        }
    }

    fun buildReport(result: ScanResult): PatchReport =
        PatchReport(result.apkInfo, result.detections, System.currentTimeMillis())

    fun patch(
        apkFile: File,
        detections: List<Detection>,
        outApk: File,
        keystoreFile: File,
        storePass: String,
        alias: String,
        keyPass: String,
        log: (String) -> Unit = {}
    ): File {
        require(detections.isNotEmpty()) { "Nothing to patch" }
        val work = Files.createTempDirectory("apklab-patch").toFile()
        try {
            val apkDir = File(work, "apk")
            log("Unpacking APK...")
            ApkIO.unzipApk(apkFile, apkDir)
            // Drop old signatures; apksig regenerates everything.
            File(apkDir, "META-INF").deleteRecursively()

            // Gut targets are per-dex; hook keys are global so hooks in a
            // different classesN.dex than the injected class still get nopped.
            val gutByDex: Map<String, List<MethodTarget>> = detections
                .flatMap { d -> d.methodsToGut.map { it to d.sourceDex } }
                .groupBy({ it.second }, { it.first })
            val allHookKeys: Set<Pair<String, String>> = detections
                .flatMap { d -> d.hookSites.map { it.target.declaringClass to it.target.name } }
                .toSet()

            var totalGutted = 0
            var totalNopped = 0
            for (dexName in ApkIO.listDexNames(apkFile)) {
                val gutTargets = gutByDex[dexName] ?: emptyList()
                if (gutTargets.isEmpty() && allHookKeys.isEmpty()) continue
                val dexFile = File(apkDir, dexName)
                if (!dexFile.exists()) {
                    log("WARNING: $dexName not found in APK, skipping")
                    continue
                }
                log("Patching $dexName...")
                val dex = DexFileFactory.loadDexFile(dexFile, Opcodes.getDefault())
                val patched = Patcher.patchDex(dex, gutTargets, allHookKeys)
                val tmpDex = File(work, "$dexName.patched")
                Patcher.writeDex(patched, tmpDex)
                // Sanity: the rewritten DEX must still parse.
                DexFileFactory.loadDexFile(tmpDex, Opcodes.getDefault())
                tmpDex.copyTo(dexFile, overwrite = true)
                totalGutted += gutTargets.size
            }
            totalNopped = detections.sumOf { it.hookSites.size }
            log("Gutted $totalGutted method(s), nopped $totalNopped hook call(s)")

            log("Repacking + aligning...")
            val aligned = File(work, "aligned.apk")
            Aligner.repackAligned(apkDir, aligned)

            log("Signing (v1+v2)...")
            Signer.sign(aligned, outApk, keystoreFile, storePass, alias, keyPass)
            log("Done: ${outApk.name}")
            return outApk
        } finally {
            work.deleteRecursively()
        }
    }

    private fun readApkInfo(apkFile: File): ApkInfo {
        var pkg: String? = null
        var vName: String? = null
        var vCode: Long = 0
        try {
            ApkFile(apkFile.absolutePath).use { af ->
                val meta = af.apkMeta
                pkg = meta.packageName
                vName = meta.versionName
                vCode = meta.versionCode
            }
        } catch (_: Exception) {
            // leave nulls; size/dex/sig info still reported
        }
        return ApkInfo(
            fileName = apkFile.name,
            packageName = pkg,
            versionName = vName,
            versionCode = vCode,
            sizeBytes = apkFile.length(),
            dexCount = ApkIO.listDexNames(apkFile).size,
            sigSchemes = ApkIO.detectSigSchemes(apkFile)
        )
    }
}
