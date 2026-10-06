package com.apklab.engine

/** Metadata about an APK, read without full decode. */
data class ApkInfo(
    val fileName: String,
    val packageName: String?,
    val versionName: String?,
    val versionCode: Long,
    val sizeBytes: Long,
    val dexCount: Int,
    val sigSchemes: List<String>
)

enum class Badge { DIALOG, REMOTE, STARTUP }

/** A method selected for gutting (body replaced with return-void). */
data class MethodTarget(
    val declaringClass: String,
    val name: String,
    val descriptor: String
)

/** A call site that invokes a gutted method — the invoke is replaced with NOP. */
data class HookSite(
    val callerClass: String,
    val callerMethod: String,
    val target: MethodTarget
)

/**
 * A precisely-scoped invoke to NOP: only inside [callerClass].[callerMethod],
 * only invokes to [targetClass].[targetMethod]. Used for startup dialogs
 * (Tier B/C) where gutting the whole method would be too invasive — we just
 * silence the single call that shows the dialog at startup.
 */
data class ScopedNop(
    val callerClass: String,
    val callerMethod: String,
    val targetClass: String,
    val targetMethod: String
)

/** One injected-dialog class found in the APK. */
data class Detection(
    val classType: String,
    val badges: Set<Badge>,
    val methodsToGut: List<MethodTarget>,
    val hookSites: List<HookSite>,
    val confidence: Double,
    val sourceDex: String = "",
    val scopedNops: List<ScopedNop> = emptyList()
) {
    /** Total invoke sites that will be silenced (global hooks + scoped nops). */
    val totalNops: Int get() = hookSites.size + scopedNops.size
}

data class ScanResult(
    val apkInfo: ApkInfo,
    val detections: List<Detection>
)

data class PatchReport(
    val apkInfo: ApkInfo,
    val detections: List<Detection>,
    val generatedAt: Long
) {
    fun toText(): String = buildString {
        appendLine("ApkLab Patch Report")
        appendLine("Generated: ${java.util.Date(generatedAt)}")
        appendLine()
        appendLine("APK: ${apkInfo.fileName}")
        appendLine("Package: ${apkInfo.packageName ?: "?"}")
        appendLine("Version: ${apkInfo.versionName ?: "?"} (${apkInfo.versionCode})")
        appendLine("Size: ${"%.1f".format(apkInfo.sizeBytes / 1048576.0)} MB")
        appendLine("DEX files: ${apkInfo.dexCount}")
        appendLine("Signature: ${apkInfo.sigSchemes.joinToString("+")}")
        appendLine()
        appendLine("Findings (${detections.size}):")
        detections.forEachIndexed { i, d ->
            appendLine()
            appendLine("${i + 1}. ${d.classType}")
            appendLine("   Badges: ${d.badges.joinToString(", ")} | DEX: ${d.sourceDex} | Confidence: ${"%.0f".format(d.confidence * 100)}%")
            appendLine("   Methods gutted (${d.methodsToGut.size}):")
            d.methodsToGut.forEach { appendLine("     - ${it.name}${it.descriptor}") }
            appendLine("   Hook calls nopped (${d.hookSites.size}):")
            d.hookSites.forEach { appendLine("     - ${it.callerClass} -> ${it.callerMethod}() calls ${it.target.name}()") }
            if (d.scopedNops.isNotEmpty()) {
                appendLine("   Startup calls silenced (${d.scopedNops.size}):")
                d.scopedNops.forEach {
                    appendLine("     - ${it.callerClass} -> ${it.callerMethod}() calls ${it.targetMethod}() [startup only]")
                }
            }
        }
        appendLine()
        appendLine("Note: the patched APK is signed with a new debug key. Apps that")
        appendLine("verify their own signature will refuse to run — this is expected.")
    }
}
