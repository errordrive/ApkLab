package com.apklab.engine

import org.jf.dexlib2.DexFileFactory
import org.jf.dexlib2.Opcodes
import org.jf.dexlib2.iface.DexFile
import org.junit.Assert.*
import org.junit.Test
import java.io.File

/**
 * Detection test corpus.
 *
 * MUST STAY GREEN:
 *  - clean AlertDialog / custom Dialog / BottomSheet-style code -> ZERO hits
 *  - network-only code -> ZERO hits
 *  - allowlisted packages -> ZERO hits (even with dialog+network)
 *  - injected remote dialog (obfuscated or not) -> exact hits
 */
class DetectorTest {

    private fun scanOf(vararg classes: DexFixtures.TestClass, dexName: String = "classes.dex"): Pair<DexFile, List<Detection>> {
        val builder = DexFixtures.buildDex(classes.toList())
        val tmp = File.createTempFile("fixture", ".dex")
        tmp.deleteOnExit()
        Patcher.writeDex(builder, tmp)
        val dex = DexFileFactory.loadDexFile(tmp, Opcodes.getDefault())
        return dex to Detector.scanDex(dex, dexName)
    }

    @Test
    fun `injected remote dialog is detected`() {
        val evil = DexFixtures.TestClass("Lcom/evil/Update;", listOf(DexFixtures.evilShowMethod()))
        val (_, dets) = scanOf(evil)
        assertEquals(1, dets.size)
        val d = dets[0]
        assertEquals("Lcom/evil/Update;", d.classType)
        assertTrue(d.badges.containsAll(setOf(Badge.DIALOG, Badge.REMOTE)))
        assertEquals(1, d.methodsToGut.size)
        assertEquals("checkAndShow", d.methodsToGut[0].name)
        assertEquals("classes.dex", d.sourceDex)
    }

    @Test
    fun `obfuscated package injected dialog is detected`() {
        val evil = DexFixtures.TestClass(
            "La/b/c/d;",
            listOf(DexFixtures.evilShowMethod().copy(name = "a"))
        )
        val (_, dets) = scanOf(evil)
        assertEquals(1, dets.size)
        assertEquals("La/b/c/d;", dets[0].classType)
    }

    @Test
    fun `known ad SDK is never flagged even with dialog plus network`() {
        // Mbridge-style: same Tier1+Tier2 signals as an injected dialog,
        // but inside a known ad SDK namespace -> must be skipped.
        val adSdk = DexFixtures.TestClass(
            "Lcom/mbridge/msdk/foundation/d/a/a;",
            listOf(DexFixtures.evilShowMethod().copy(name = "a"))
        )
        val (_, dets) = scanOf(adSdk)
        assertEquals(0, dets.size)
    }

    @Test
    fun `hook caller inside known ad SDK is ignored`() {        val evil = DexFixtures.TestClass("Lcom/evil/Update;", listOf(DexFixtures.evilShowMethod()))
        val adCaller = DexFixtures.TestClass(
            "Lcom/mbridge/msdk/splash/c/c;", listOf(
                DexFixtures.TestMethod(
                    "viewClicked",
                    params = emptyList(),
                    access = 0x1,
                    impl = DexFixtures.implOf(
                        DexFixtures.invokeStatic(
                            "Lcom/evil/Update;", "checkAndShow", "V",
                            listOf("Landroid/app/Activity;")
                        ),
                        DexFixtures.returnVoid()
                    )
                )
            )
        )
        val (_, dets) = scanOf(evil, adCaller)
        assertEquals(1, dets.size)
        assertEquals(0, dets[0].hookSites.size)
    }

    @Test
    fun `clean AlertDialog usage is not flagged`() {
        val clean = DexFixtures.TestClass(
            "Lcom/app/Ui;", listOf(
                DexFixtures.TestMethod(
                    "showInfo",
                    impl = DexFixtures.implOf(
                        DexFixtures.newInstance("Landroid/app/AlertDialog\$Builder;"),
                        DexFixtures.invokeVirtual(
                            "Landroid/app/AlertDialog\$Builder;", "show",
                            "Landroid/app/AlertDialog;"
                        ),
                        DexFixtures.returnVoid()
                    )
                )
            )
        )
        val (_, dets) = scanOf(clean)
        assertTrue("false positive on AlertDialog: $dets", dets.isEmpty())
    }

    @Test
    fun `custom dialog without network is not flagged`() {
        val clean = DexFixtures.TestClass(
            "Lcom/app/MyDlg;", listOf(
                DexFixtures.TestMethod(
                    "showNow",
                    impl = DexFixtures.implOf(
                        DexFixtures.newInstance("Landroid/app/Dialog;"),
                        DexFixtures.invokeVirtual("Landroid/app/Dialog;", "show"),
                        DexFixtures.returnVoid()
                    )
                )
            )
        )
        val (_, dets) = scanOf(clean)
        assertTrue("false positive on legit custom dialog: $dets", dets.isEmpty())
    }

    @Test
    fun `network-only class is not flagged`() {
        val clean = DexFixtures.TestClass(
            "Lcom/app/Net;", listOf(
                DexFixtures.TestMethod(
                    "fetch",
                    impl = DexFixtures.implOf(
                        DexFixtures.constString("https://pastebin.com/raw/x"),
                        DexFixtures.invokeVirtual(
                            "Lorg/json/JSONObject;", "optBoolean", "Z",
                            listOf("Ljava/lang/String;")
                        ),
                        DexFixtures.returnVoid()
                    )
                )
            )
        )
        val (_, dets) = scanOf(clean)
        assertTrue("false positive on network code: $dets", dets.isEmpty())
    }

    @Test
    fun `allowlisted package is never flagged`() {
        val evil = DexFixtures.TestClass(
            "Landroidx/fake/Evil;", listOf(DexFixtures.evilShowMethod())
        )
        val (_, dets) = scanOf(evil)
        assertTrue("flagged allowlisted class: $dets", dets.isEmpty())
    }

    @Test
    fun `hook call site is detected`() {
        val evil = DexFixtures.TestClass("Lcom/evil/Update;", listOf(DexFixtures.evilShowMethod()))
        val hook = DexFixtures.TestClass(
            "Lcom/app/Main;", listOf(
                DexFixtures.TestMethod(
                    "onCreate",
                    params = listOf("Landroid/os/Bundle;"),
                    access = 0x1,
                    impl = DexFixtures.implOf(
                        DexFixtures.invokeStatic(
                            "Lcom/evil/Update;", "checkAndShow", "V",
                            listOf("Landroid/app/Activity;")
                        ),
                        DexFixtures.returnVoid()
                    )
                )
            )
        )
        val (_, dets) = scanOf(evil, hook)
        assertEquals(1, dets.size)
        assertEquals(1, dets[0].hookSites.size)
        val h = dets[0].hookSites[0]
        assertEquals("Lcom/app/Main;", h.callerClass)
        assertEquals("onCreate", h.callerMethod)
        assertEquals("checkAndShow", h.target.name)
    }

    @Test
    fun `hook in different dex than injected class is detected`() {
        val evil = DexFixtures.TestClass("Lcom/evil/Update;", listOf(DexFixtures.evilShowMethod()))
        val hook = DexFixtures.TestClass(
            "Lcom/app/Main;", listOf(
                DexFixtures.TestMethod(
                    "onCreate",
                    params = listOf("Landroid/os/Bundle;"),
                    access = 0x1,
                    impl = DexFixtures.implOf(
                        DexFixtures.invokeStatic(
                            "Lcom/evil/Update;", "checkAndShow", "V",
                            listOf("Landroid/app/Activity;")
                        ),
                        DexFixtures.returnVoid()
                    )
                )
            )
        )
        val dex1 = DexFixtures.buildDex(listOf(evil))
        val dex2 = DexFixtures.buildDex(listOf(hook))
        val dets = Detector.scanMultiDex(mapOf("classes.dex" to dex1, "classes2.dex" to dex2))
        assertEquals(1, dets.size)
        assertEquals("classes.dex", dets[0].sourceDex)
        assertEquals(1, dets[0].hookSites.size)
        assertEquals("Lcom/app/Main;", dets[0].hookSites[0].callerClass)
    }

    @Test
    fun `non-void dialog method is not gutted`() {
        // Gutting a non-void method with return-void would corrupt the DEX;
        // such methods must be excluded from gut targets.
        val odd = DexFixtures.TestClass(
            "Lcom/evil/Weird;", listOf(
                DexFixtures.TestMethod(
                    "makeDialog",
                    ret = "Landroid/app/Dialog;",
                    impl = DexFixtures.implOf(
                        DexFixtures.newInstance("Landroid/app/Dialog;"),
                        DexFixtures.constString("https://pastebin.com/raw/x"),
                        DexFixtures.returnVoid() // unrealistic body; detector must still skip it
                    )
                )
            )
        )
        val (_, dets) = scanOf(odd)
        assertTrue("non-void method must not be a gut target: $dets", dets.isEmpty())
    }

    // ---------- Tier B: startup-hooked offline dialog ----------

    @Test
    fun `offline dialog helper hooked from onCreate is flagged STARTUP`() {
        val helper = DexFixtures.TestClass(
            "Lcom/app/WelcomeDialog;", listOf(DexFixtures.offlineDialogMethod())
        )
        val main = DexFixtures.TestClass(
            "Lcom/app/MainActivity;",
            listOf(DexFixtures.mainOnCreateCalling("Lcom/app/WelcomeDialog;", "showWelcome"))
        )
        val (_, dets) = scanOf(helper, main)
        assertEquals(1, dets.size)
        val d = dets[0]
        assertEquals("Lcom/app/WelcomeDialog;", d.classType)
        assertTrue(d.badges.containsAll(setOf(Badge.DIALOG, Badge.STARTUP)))
        assertTrue("Tier B must not gut: $d", d.methodsToGut.isEmpty())
        assertEquals(1, d.scopedNops.size)
        val nop = d.scopedNops[0]
        assertEquals("Lcom/app/MainActivity;", nop.callerClass)
        assertEquals("onCreate", nop.callerMethod)
        assertEquals("showWelcome", nop.targetMethod)
    }

    @Test
    fun `offline dialog helper without startup hook is not flagged`() {
        val helper = DexFixtures.TestClass(
            "Lcom/app/WelcomeDialog;", listOf(DexFixtures.offlineDialogMethod())
        )
        // No caller at all -> nothing shown at startup -> no detection.
        val (_, dets) = scanOf(helper)
        assertTrue("unhooked helper must not be flagged: $dets", dets.isEmpty())
    }

    @Test
    fun `alertdialog helper hooked from onCreate is flagged STARTUP`() {
        // The AlertDialog pattern from the user's script: new AlertDialog + show.
        val helper = DexFixtures.TestClass(
            "Lcom/app/AlertHelper;", listOf(DexFixtures.alertDialogMethod())
        )
        val main = DexFixtures.TestClass(
            "Lcom/app/MainActivity;",
            listOf(DexFixtures.mainOnCreateCalling("Lcom/app/AlertHelper;", "showAlert"))
        )
        val (_, dets) = scanOf(helper, main)
        assertEquals(1, dets.size)
        assertTrue(dets[0].badges.contains(Badge.STARTUP))
        assertEquals(1, dets[0].scopedNops.size)
    }

    @Test
    fun `offline dialog called from click handler is not flagged`() {
        val helper = DexFixtures.TestClass(
            "Lcom/app/WelcomeDialog;", listOf(DexFixtures.offlineDialogMethod())
        )
        val main = DexFixtures.TestClass(
            "Lcom/app/MainActivity;", listOf(
                DexFixtures.TestMethod(
                    "onButtonClick",
                    params = emptyList(),
                    access = 0x1,
                    impl = DexFixtures.implOf(
                        DexFixtures.invokeStatic(
                            "Lcom/app/WelcomeDialog;", "showWelcome", "V",
                            listOf("Landroid/app/Activity;")
                        ),
                        DexFixtures.returnVoid()
                    )
                )
            )
        )
        val (_, dets) = scanOf(helper, main)
        assertTrue("non-startup hook must not be flagged: $dets", dets.isEmpty())
    }

    // ---------- Tier C: inline dialog in onCreate ----------

    @Test
    fun `inline dialog in onCreate is flagged STARTUP`() {
        val main = DexFixtures.TestClass(
            "Lcom/app/MainActivity;", listOf(DexFixtures.mainOnCreateInlineDialog())
        )
        val (_, dets) = scanOf(main)
        assertEquals(1, dets.size)
        val d = dets[0]
        assertEquals("Lcom/app/MainActivity;", d.classType)
        assertTrue(d.badges.containsAll(setOf(Badge.DIALOG, Badge.STARTUP)))
        assertTrue("Tier C must not gut onCreate: $d", d.methodsToGut.isEmpty())
        assertEquals(1, d.scopedNops.size)
        val nop = d.scopedNops[0]
        assertEquals("onCreate", nop.callerMethod)
        assertEquals("Landroid/app/Dialog;", nop.targetClass)
        assertEquals("show", nop.targetMethod)
    }
}
