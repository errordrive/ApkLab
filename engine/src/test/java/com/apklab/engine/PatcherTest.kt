package com.apklab.engine

import org.jf.dexlib2.DexFileFactory
import org.jf.dexlib2.Opcode
import org.jf.dexlib2.Opcodes
import org.jf.dexlib2.iface.DexFile
import org.junit.Assert.*
import org.junit.Test
import java.io.File

/**
 * Patcher test corpus: gut + nop must produce a valid, re-parseable DEX
 * where the dialog code is dead and a re-scan finds nothing.
 */
class PatcherTest {

    private fun evilAndHook(): Pair<DexFile, List<Detection>> {
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
                ),
                // untouched control method
                DexFixtures.TestMethod(
                    "helper",
                    impl = DexFixtures.implOf(DexFixtures.returnVoid())
                )
            )
        )
        val builder = DexFixtures.buildDex(listOf(evil, hook))
        val tmp = File.createTempFile("prepatch", ".dex")
        tmp.deleteOnExit()
        Patcher.writeDex(builder, tmp)
        val dex = DexFileFactory.loadDexFile(tmp, Opcodes.getDefault())
        return dex to Detector.scanDex(dex, "classes.dex")
    }

    @Test
    fun `patch guts dialog method and nops hook, dex stays valid`() {
        val (dex, dets) = evilAndHook()
        assertEquals(1, dets.size)

        val beforeClasses = dex.classes.count()
        val patched = Patcher.patchDex(dex, dets)
        val out = File.createTempFile("patched", ".dex")
        out.deleteOnExit()
        Patcher.writeDex(patched, out)

        // Re-parseable = structurally valid DEX.
        val reloaded = DexFileFactory.loadDexFile(out, Opcodes.getDefault())
        assertEquals(beforeClasses, reloaded.classes.count())

        // Gutted method body is exactly one return-void.
        val evilClass = reloaded.classes.first { it.type == "Lcom/evil/Update;" }
        val m = evilClass.methods.first { it.name == "checkAndShow" }
        val insns = m.implementation!!.instructions.toList()
        assertEquals(1, insns.size)
        assertEquals(Opcode.RETURN_VOID, insns[0].opcode)

        // Hook invoke replaced with NOP; control method untouched.
        val hookClass = reloaded.classes.first { it.type == "Lcom/app/Main;" }
        val onCreate = hookClass.methods.first { it.name == "onCreate" }
        val hinsns = onCreate.implementation!!.instructions.toList()
        assertEquals(2, hinsns.size)
        assertEquals(Opcode.NOP, hinsns[0].opcode)
        assertEquals(Opcode.RETURN_VOID, hinsns[1].opcode)

        val helper = hookClass.methods.first { it.name == "helper" }
        assertEquals(1, helper.implementation!!.instructions.toList().size)

        // Re-scan finds nothing — the injected dialog is fully dead.
        assertTrue(Detector.scanDex(reloaded, "classes.dex").isEmpty())
    }

    @Test
    fun `hook in another dex gets nopped when patching all dexes`() {
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
        // evil in dex1, hook in dex2 — like a real multi-dex APK
        val dex1 = DexFixtures.buildDex(listOf(evil))
        val dex2 = DexFixtures.buildDex(listOf(hook))
        val dets = Detector.scanMultiDex(mapOf("classes.dex" to dex1, "classes2.dex" to dex2))
        assertEquals(1, dets.size)
        assertEquals(1, dets[0].hookSites.size)

        // Engine-style: gut targets per-dex, hook keys global
        val gutByDex = dets.flatMap { d -> d.methodsToGut.map { it to d.sourceDex } }
            .groupBy({ it.second }, { it.first })
        val allHookKeys = dets
            .flatMap { d -> d.hookSites.map { it.target.declaringClass to it.target.name } }
            .toSet()

        val patched2 = Patcher.patchDex(dex2, gutByDex["classes2.dex"] ?: emptyList(), allHookKeys)
        val out = File.createTempFile("patched2", ".dex")
        out.deleteOnExit()
        Patcher.writeDex(patched2, out)
        val reloaded = DexFileFactory.loadDexFile(out, Opcodes.getDefault())
        val onCreate = reloaded.classes.first { it.type == "Lcom/app/Main;" }
            .methods.first { it.name == "onCreate" }
        val insns = onCreate.implementation!!.instructions.toList()
        assertEquals(Opcode.NOP, insns[0].opcode)
        assertFalse(insns.any { it.opcode == Opcode.INVOKE_STATIC })
    }

    @Test
    fun `patch with no detections leaves dex untouched`() {
        val clean = DexFixtures.TestClass(
            "Lcom/app/Ui;", listOf(
                DexFixtures.TestMethod(
                    "showInfo",
                    impl = DexFixtures.implOf(DexFixtures.returnVoid())
                )
            )
        )
        val builder = DexFixtures.buildDex(listOf(clean))
        val pre = File.createTempFile("cleanpre", ".dex")
        pre.deleteOnExit()
        Patcher.writeDex(builder, pre)
        val dex = DexFileFactory.loadDexFile(pre, Opcodes.getDefault())
        val patched = Patcher.patchDex(dex, emptyList())
        val out = File.createTempFile("cleanpatched", ".dex")
        out.deleteOnExit()
        Patcher.writeDex(patched, out)
        val reloaded = DexFileFactory.loadDexFile(out, Opcodes.getDefault())
        assertEquals(1, reloaded.classes.count())
        val m = reloaded.classes.first().methods.first()
        assertEquals(Opcode.RETURN_VOID, m.implementation!!.instructions.toList()[0].opcode)
    }
}
