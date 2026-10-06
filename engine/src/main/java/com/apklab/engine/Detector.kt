package com.apklab.engine

import org.jf.dexlib2.Opcode
import org.jf.dexlib2.iface.DexFile
import org.jf.dexlib2.iface.Method
import org.jf.dexlib2.iface.instruction.ReferenceInstruction
import org.jf.dexlib2.iface.reference.MethodReference
import org.jf.dexlib2.iface.reference.StringReference
import org.jf.dexlib2.iface.reference.TypeReference

/**
 * Detects injected remote-controlled dialog classes.
 *
 * A class is flagged ONLY when BOTH hold in the same class:
 *  - Tier 1: references android.app.Dialog (type or method refs)
 *  - Tier 2: remote-fetch signals (HttpURLConnection/OkHttp types,
 *    JSONObject.optBoolean/optString, pastebin/isVisible/updateUrl strings)
 *
 * Framework packages are never flagged (allowlist).
 */
object Detector {

    private val ALLOWLIST_PREFIXES = listOf(
        "Landroid/", "Landroidx/",
        "Lcom/google/android/", "Lcom/google/",
        "Lkotlin/", "Lkotlinx/",
        "Ljava/", "Ljavax/", "Ldalvik/",
        "Lorg/xmlpull/", "Lcom/android/"
    )

    /**
     * Known legitimate third-party SDKs (ad networks, analytics, attribution).
     * These ALWAYS use Dialog + network legitimately (interstitials, banners,
     * remote config) and must NEVER be flagged — gutting them breaks the host
     * app (crash on launch). An injected update-dialog lives in the app's own
     * package or a shady new package, never inside these SDK namespaces.
     */
    private val SDK_DENYLIST_PREFIXES = listOf(
        "Lcom/mbridge/",                 // Mbridge (Mintegral) ads
        "Lcom/google/android/gms/ads/",  // AdMob / Google Mobile Ads
        "Lcom/google/ads/",
        "Lcom/facebook/ads/",            // Meta Audience Network
        "Lcom/facebook/appevents/",
        "Lcom/unity3d/ads/",             // Unity Ads
        "Lcom/applovin/",               // AppLovin MAX
        "Lcom/chartboost/",
        "Lcom/inmobi/",
        "Lcom/vungle/",
        "Lcom/ironsource/",              // ironSource / Unity LevelPlay
        "Lcom/tapjoy/",
        "Lcom/startapp/",
        "Lcom/mopub/",
        "Lcom/amazon/device/ads/",
        "Lcom/smaato/",
        "Lcom/fyber/",
        "Lcom/audiencenetwork/",
        "Lcom/bytedance/sdk/",           // Pangle
        "Lcom/kwai/sdk/",               // Kwai ads
        "Lcom/liftoff/",
        "Lcom/mintegral/",
        "Lcom/yeahmobi/",
        // Analytics / attribution / crash reporting (defensive)
        "Lcom/google/firebase/",
        "Lcom/appsflyer/",
        "Lcom/adjust/",
        "Lcom/singular/",
        "Lcom/branch/",
        "Lio/sentry/",
        "Lcom/amplitude/",
        "Lcom/mixpanel/",
        "Lcom/crashlytics/",
        "Lcom/flurry/",
    )

    private const val DIALOG_TYPE = "Landroid/app/Dialog;"

    private val TIER1_DIALOG_METHODS = setOf(
        "show", "dismiss", "setContentView", "setCancelable",
        "setCanceledOnTouchOutside", "requestWindowFeature",
        "getWindow", "isShowing"
    )

    private val TIER2_TYPES = setOf(
        "Ljava/net/HttpURLConnection;",
        "Lokhttp3/OkHttpClient;",
        "Lokhttp3/Request;"
    )

    private val TIER2_METHOD_NAMES = setOf("optBoolean", "optString")

    private val TIER2_STRING_SUBS = listOf("pastebin", "isvisible", "updateurl")

    /**
     * Lifecycle entry points where a "startup dialog" hook lives.
     * A custom dialog invoked from one of these = shown at app start.
     */
    private val LIFECYCLE_METHODS = setOf("onCreate", "onStart", "onResume")

    /**
     * Direct "show the dialog now" targets for inline startup dialogs
     * (dialog code written directly inside onCreate, no helper method).
     */
    private val INLINE_SHOW_TARGETS = setOf(
        "Landroid/app/Dialog;" to "show",
        "Landroid/app/AlertDialog\$Builder;" to "show",
        "Landroidx/appcompat/app/AlertDialog\$Builder;" to "show"
    )

    fun isAllowlisted(type: String): Boolean =
        ALLOWLIST_PREFIXES.any { type.startsWith(it) }

    /** Known legitimate SDK (ad/analytics) — never flag, never patch. */
    fun isKnownSdk(type: String): Boolean =
        SDK_DENYLIST_PREFIXES.any { type.startsWith(it) }

    /** Framework or known-SDK class: skip entirely. */
    private fun isSkipped(type: String): Boolean =
        isAllowlisted(type) || isKnownSdk(type)

    fun methodDescriptor(method: Method): String {
        val params = method.parameters.joinToString("") { it.type }
        return "($params)${method.returnType}"
    }

    internal class ClassSignals(val dexName: String) {
        var tier1: Boolean = false
        var tier2: Boolean = false
        val methodsToGut: MutableList<MethodTarget> = mutableListOf()
        /** Names of lifecycle methods (onCreate/…) that themselves show a dialog. */
        val lifecycleDialogMethods: MutableSet<String> = mutableSetOf()
    }

    /** Dialog-shower methods that are NOT lifecycle methods (i.e. helpers). */
    internal fun helperDialogMethods(s: ClassSignals): List<MethodTarget> =
        s.methodsToGut.filter { it.name !in LIFECYCLE_METHODS }

    /** Single-dex scan (used by tests). */
    fun scanDex(dexFile: DexFile, dexName: String): List<Detection> =
        scanMultiDex(mapOf(dexName to dexFile))

    /**
     * Pass 1 (one dex): collect per-class tier signals + gut targets.
     * Merges into [out] so callers can process huge APKs one dex at a time
     * instead of holding every dex file in memory simultaneously.
     */
    internal fun collectSignals(
        dexFile: DexFile,
        dexName: String,
        out: MutableMap<String, ClassSignals>
    ) {
        for (classDef in dexFile.classes) {
            val type = classDef.type
            if (isSkipped(type)) continue
            val sig = out.getOrPut(type) { ClassSignals(dexName) }
            for (method in classDef.methods) {
                val impl = method.implementation ?: continue
                var dialogShow = false
                for (insn in impl.instructions) {
                    if (insn !is ReferenceInstruction) continue
                    when (val ref = insn.reference) {
                        is TypeReference -> {
                            if (ref.type == DIALOG_TYPE) {
                                sig.tier1 = true
                                if (insn.opcode == Opcode.NEW_INSTANCE) dialogShow = true
                            }
                            if (ref.type in TIER2_TYPES) sig.tier2 = true
                        }
                        is MethodReference -> {
                            if (ref.definingClass == DIALOG_TYPE && ref.name in TIER1_DIALOG_METHODS) {
                                sig.tier1 = true
                                if (ref.name == "show") dialogShow = true
                            }
                            if (ref.name in TIER2_METHOD_NAMES) sig.tier2 = true
                        }
                        is StringReference -> {
                            val s = ref.string.lowercase()
                            if (TIER2_STRING_SUBS.any { s.contains(it) }) sig.tier2 = true
                        }
                    }
                }
                if (dialogShow) {
                    val desc = methodDescriptor(method)
                    // Only void methods are safe to gut.
                    if (desc.endsWith(")V")) {
                        sig.methodsToGut.add(MethodTarget(type, method.name, desc))
                        if (method.name in LIFECYCLE_METHODS) {
                            sig.lifecycleDialogMethods.add(method.name)
                        }
                    }
                }
            }
        }
    }

    /** Keep only classes where Tier 1 AND Tier 2 both fired with guttable methods. */
    internal fun confirmCandidates(
        signals: Map<String, ClassSignals>
    ): Map<String, ClassSignals> =
        signals.filter { (_, s) -> s.tier1 && s.tier2 && s.methodsToGut.isNotEmpty() }

    /** Gut-target lookup: (declaringClass, methodName) -> MethodTarget. */
    internal fun gutIndex(candidates: Map<String, ClassSignals>): Map<Pair<String, String>, MethodTarget> =
        candidates.flatMap { (cls, s) ->
            s.methodsToGut.map { (cls to it.name) to it }
        }.toMap()

    /**
     * Pass 2 (one dex): find hook call sites — void invokes to gutted methods
     * from any non-allowlisted class in this dex file.
     */
    fun findHookSites(
        dexFile: DexFile,
        gutByClassName: Map<Pair<String, String>, MethodTarget>
    ): List<HookSite> {
        if (gutByClassName.isEmpty()) return emptyList()
        val hookSites = mutableListOf<HookSite>()
        for (classDef in dexFile.classes) {
            val callerType = classDef.type
            if (isSkipped(callerType)) continue
            for (method in classDef.methods) {
                val impl = method.implementation ?: continue
                val insns = impl.instructions.toList()
                for (i in insns.indices) {
                    val insn = insns[i]
                    if (insn !is ReferenceInstruction) continue
                    val ref = insn.reference
                    if (ref !is MethodReference) continue
                    if (ref.returnType != "V") continue
                    val target = gutByClassName[ref.definingClass to ref.name] ?: continue
                    val next = insns.getOrNull(i + 1)
                    if (next != null && next.opcode.name.startsWith("MOVE_RESULT")) continue
                    hookSites.add(HookSite(callerType, method.name, target))
                }
            }
        }
        return hookSites
    }

    /**
     * Pass 2b (one dex): Tier B — startup hooks. Finds invokes to offline
     * dialog-helper methods from lifecycle methods (onCreate/onStart/onResume).
     * A custom dialog invoked there = shown at app start.
     */
    fun findStartupNops(
        dexFile: DexFile,
        helperTargets: Map<Pair<String, String>, MethodTarget>
    ): List<ScopedNop> {
        if (helperTargets.isEmpty()) return emptyList()
        val nops = mutableListOf<ScopedNop>()
        for (classDef in dexFile.classes) {
            val callerType = classDef.type
            if (isSkipped(callerType)) continue
            for (method in classDef.methods) {
                if (method.name !in LIFECYCLE_METHODS) continue
                val impl = method.implementation ?: continue
                val insns = impl.instructions.toList()
                for (i in insns.indices) {
                    val insn = insns[i]
                    if (insn !is ReferenceInstruction) continue
                    val ref = insn.reference
                    if (ref !is MethodReference) continue
                    if (ref.returnType != "V") continue
                    if ((ref.definingClass to ref.name) !in helperTargets) continue
                    val next = insns.getOrNull(i + 1)
                    if (next != null && next.opcode.name.startsWith("MOVE_RESULT")) continue
                    nops.add(ScopedNop(callerType, method.name, ref.definingClass, ref.name))
                }
            }
        }
        return nops
    }

    /**
     * Pass 2c (one dex): Tier C — inline startup dialogs. Finds direct
     * `Dialog.show()` / `AlertDialog.Builder.show()` invokes inside lifecycle
     * methods (dialog code written inline in onCreate, no helper method).
     * Only the show call is silenced; everything else in onCreate is untouched.
     */
    fun findInlineNops(dexFile: DexFile): List<ScopedNop> {
        val nops = mutableListOf<ScopedNop>()
        for (classDef in dexFile.classes) {
            val callerType = classDef.type
            if (isSkipped(callerType)) continue
            for (method in classDef.methods) {
                if (method.name !in LIFECYCLE_METHODS) continue
                val impl = method.implementation ?: continue
                val insns = impl.instructions.toList()
                for (i in insns.indices) {
                    val insn = insns[i]
                    if (insn !is ReferenceInstruction) continue
                    val ref = insn.reference
                    if (ref !is MethodReference) continue
                    if ((ref.definingClass to ref.name) !in INLINE_SHOW_TARGETS) continue
                    val next = insns.getOrNull(i + 1)
                    if (next != null && next.opcode.name.startsWith("MOVE_RESULT")) continue
                    nops.add(ScopedNop(callerType, method.name, ref.definingClass, ref.name))
                }
            }
        }
        return nops
    }

    /** (class, method) -> target for Tier B offline dialog helpers. */
    internal fun startupTargets(
        signals: Map<String, ClassSignals>,
        excludeClasses: Set<String>
    ): Map<Pair<String, String>, MethodTarget> =
        signals
            .filterKeys { it !in excludeClasses }
            .flatMap { (cls, s) -> helperDialogMethods(s).map { (cls to it.name) to it } }
            .toMap()

    /** Assemble Tier B/C detections from scoped nops, grouped by dialog class. */
    internal fun buildStartupDetections(
        signals: Map<String, ClassSignals>,
        startupNops: List<ScopedNop>,
        inlineNops: List<ScopedNop>
    ): List<Detection> {
        // Tier B: group startup nops by the helper (target) class.
        val byHelper = startupNops.groupBy { it.targetClass }
        val tierB = byHelper.map { (helperCls, nops) ->
            val dex = signals[helperCls]?.dexName ?: ""
            Detection(
                classType = helperCls,
                badges = setOf(Badge.DIALOG, Badge.STARTUP),
                methodsToGut = emptyList(),
                hookSites = emptyList(),
                confidence = 0.9,
                sourceDex = dex,
                scopedNops = nops.distinct()
            )
        }
        // Tier C: group inline nops by the caller (activity) class.
        val byCaller = inlineNops.groupBy { it.callerClass }
        val tierC = byCaller
            .filterKeys { it !in byHelper.keys }
            .map { (callerCls, nops) ->
                Detection(
                    classType = callerCls,
                    badges = setOf(Badge.DIALOG, Badge.STARTUP),
                    methodsToGut = emptyList(),
                    hookSites = emptyList(),
                    confidence = 0.85,
                    sourceDex = "",
                    scopedNops = nops.distinct()
                )
            }
        return tierB + tierC
    }

    /** Assemble final detections from confirmed candidates + collected hook sites. */
    internal fun buildDetections(
        candidates: Map<String, ClassSignals>,
        hookSites: List<HookSite>
    ): List<Detection> =
        candidates.map { (cls, s) ->
            val hooks = hookSites.filter { it.target.declaringClass == cls }
            val confidence = when {
                hooks.isNotEmpty() -> 0.95
                s.methodsToGut.size >= 2 -> 0.9
                else -> 0.85
            }
            Detection(
                classType = cls,
                badges = setOf(Badge.DIALOG, Badge.REMOTE),
                methodsToGut = s.methodsToGut.toList(),
                hookSites = hooks,
                confidence = confidence,
                sourceDex = s.dexName
            )
        }

    /**
     * Multi-dex scan with three tiers:
     *  - Tier A (REMOTE): dialog + network signals (injected update-dialog).
     *  - Tier B (STARTUP): offline dialog helper invoked from onCreate/onStart/onResume.
     *  - Tier C (STARTUP): dialog shown inline inside onCreate/onStart/onResume.
     *
     * NOTE: for large APKs prefer the one-dex-at-a-time passes via [Engine.scan]
     * to bound memory.
     */
    fun scanMultiDex(dexFiles: Map<String, DexFile>): List<Detection> {
        val signals = mutableMapOf<String, ClassSignals>()
        for ((dexName, dexFile) in dexFiles) {
            collectSignals(dexFile, dexName, signals)
        }
        // Tier A: remote-controlled.
        val candidatesA = confirmCandidates(signals)
        val gutByClassName = gutIndex(candidatesA)
        val hookSites = dexFiles.flatMap { (_, dexFile) -> findHookSites(dexFile, gutByClassName) }
        val detectionsA = buildDetections(candidatesA, hookSites)
        // Tier B: offline helper hooked at startup (skip classes already Tier A).
        val targetsB = startupTargets(signals, candidatesA.keys)
        val startupNops = dexFiles.flatMap { (_, dexFile) -> findStartupNops(dexFile, targetsB) }
        // Tier C: inline dialog.show() at startup.
        val inlineNops = dexFiles.flatMap { (_, dexFile) -> findInlineNops(dexFile) }
        val detectionsBC = buildStartupDetections(signals, startupNops, inlineNops)
        return detectionsA + detectionsBC
    }
}
