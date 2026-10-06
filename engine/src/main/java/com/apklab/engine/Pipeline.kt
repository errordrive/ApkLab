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
            // Pass 1: dialog detection, ONE dex at a time. Big APKs (100MB+)
            // would otherwise hold every dex file in memory simultaneously.
            val signals = mutableMapOf<String, Detector.ClassSignals>()
            for (dexName in dexNames) {
                log("Scanning $dexName...")
                val dexFile = File(tmp, dexName)
                ApkIO.extractDex(apkFile, dexName, dexFile)
                val dex = DexFileFactory.loadDexFile(dexFile, Opcodes.getDefault())
                Detector.collectSignals(dex, dexName, signals)
                dexFile.delete() // drop bytes; let GC reclaim the parsed dex before the next one
            }
            val candidates = Detector.confirmCandidates(signals)
            // Tier B targets (offline dialog helpers) — excluded if already Tier A.
            val targetsB = Detector.startupTargets(signals, candidates.keys.toSet())
            // Pass 2: hook sites + startup nops, ONE dex at a time (hooks may
            // live in a different classesN.dex than the injected class).
            val gutByClassName = Detector.gutIndex(candidates)
            val hookSites = mutableListOf<HookSite>()
            val startupNops = mutableListOf<ScopedNop>()
            val inlineNops = mutableListOf<ScopedNop>()
            for (dexName in dexNames) {
                log("Searching hooks in $dexName...")
                val dexFile = File(tmp, dexName)
                ApkIO.extractDex(apkFile, dexName, dexFile)
                val dex = DexFileFactory.loadDexFile(dexFile, Opcodes.getDefault())
                if (candidates.isNotEmpty()) {
                    hookSites += Detector.findHookSites(dex, gutByClassName)
                }
                if (targetsB.isNotEmpty()) {
                    startupNops += Detector.findStartupNops(dex, targetsB)
                }
                inlineNops += Detector.findInlineNops(dex)
                dexFile.delete()
            }
            val detections = Detector.buildDetections(candidates, hookSites) +
                Detector.buildStartupDetections(signals, startupNops, inlineNops)
            log("Scanning ${dexNames.size} dex file(s)... done")
            for (d in detections) {
                log("Suspicious: ${d.classType} [${d.badges.joinToString(",")}] " +
                    "(${d.methodsToGut.size} method(s), ${d.totalNops} nop(s))")
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
            // Tier B/C: scoped startup nops (applied per caller method, every dex).
            val allScopedNops: Set<ScopedNop> = detections
                .flatMap { d -> d.scopedNops }
                .toSet()

            var totalGutted = 0
            var totalNopped = 0
            for (dexName in ApkIO.listDexNames(apkFile)) {
                val gutTargets = gutByDex[dexName] ?: emptyList()
                if (gutTargets.isEmpty() && allHookKeys.isEmpty() && allScopedNops.isEmpty()) continue
                val dexFile = File(apkDir, dexName)
                if (!dexFile.exists()) {
                    log("WARNING: $dexName not found in APK, skipping")
                    continue
                }
                log("Patching $dexName...")
                val dex = DexFileFactory.loadDexFile(dexFile, Opcodes.getDefault())
                val patched = Patcher.patchDex(dex, gutTargets, allHookKeys, allScopedNops)
                if (patched === dex) {
                    // Nothing to change here — skip the expensive DexPool
                    // rewrite entirely. This is the big win on 100MB+ APKs
                    // where only 1-2 dex files contain the injected code.
                    log("$dexName: no targets, skipping rewrite")
                    continue
                }
                val tmpDex = File(work, "$dexName.patched")
                Patcher.writeDex(patched, tmpDex)
                // Sanity: the rewritten DEX must still parse.
                DexFileFactory.loadDexFile(tmpDex, Opcodes.getDefault())
                tmpDex.copyTo(dexFile, overwrite = true)
                totalGutted += gutTargets.size
            }
            totalNopped = detections.sumOf { it.totalNops }
            log("Gutted $totalGutted method(s), nopped $totalNopped call(s)")

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
