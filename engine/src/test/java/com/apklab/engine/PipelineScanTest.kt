package com.apklab.engine

import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/**
 * End-to-end through [Engine.scan] on a multi-dex fake APK:
 * Tier B helper in classes.dex, Tier C inline dialog in classes2.dex.
 * Validates the one-dex-at-a-time orchestration (pass 1 + pass 2).
 */
class PipelineScanTest {

    private fun fakeApk(): File {
        val helper = DexFixtures.TestClass(
            "Lcom/app/WelcomeDialog;", listOf(DexFixtures.offlineDialogMethod())
        )
        val main = DexFixtures.TestClass(
            "Lcom/app/MainActivity;", listOf(
                DexFixtures.mainOnCreateCalling("Lcom/app/WelcomeDialog;", "showWelcome")
            )
        )
        val settings = DexFixtures.TestClass(
            "Lcom/app/SettingsActivity;", listOf(DexFixtures.mainOnCreateInlineDialog())
        )
        val clean = DexFixtures.TestClass(
            "Lcom/app/Clean;", listOf(
                DexFixtures.TestMethod(
                    "doWork", impl = DexFixtures.implOf(DexFixtures.returnVoid())
                )
            )
        )
        val dex1 = DexFixtures.buildDex(listOf(helper, main, clean))
        val dex2 = DexFixtures.buildDex(listOf(settings))

        val dexFile1 = File.createTempFile("e2e1", ".dex")
        val dexFile2 = File.createTempFile("e2e2", ".dex")
        dexFile1.deleteOnExit(); dexFile2.deleteOnExit()
        Patcher.writeDex(dex1, dexFile1)
        Patcher.writeDex(dex2, dexFile2)

        val apk = File.createTempFile("e2e", ".apk")
        apk.deleteOnExit()
        ZipOutputStream(apk.outputStream()).use { zos ->
            zos.putNextEntry(ZipEntry("classes.dex"))
            dexFile1.inputStream().copyTo(zos)
            zos.closeEntry()
            zos.putNextEntry(ZipEntry("classes2.dex"))
            dexFile2.inputStream().copyTo(zos)
            zos.closeEntry()
        }
        return apk
    }

    @Test
    fun `engine scan finds tier B and tier C across dex files`() {
        val apk = fakeApk()
        val logs = mutableListOf<String>()
        val result = Engine.scan(apk) { logs.add(it) }

        assertEquals(2, result.apkInfo.dexCount)
        val dets = result.detections
        assertEquals(2, dets.size)

        val tierB = dets.first { it.classType == "Lcom/app/WelcomeDialog;" }
        assertTrue(tierB.badges.contains(Badge.STARTUP))
        assertEquals(1, tierB.scopedNops.size)
        assertEquals("onCreate", tierB.scopedNops[0].callerMethod)

        val tierC = dets.first { it.classType == "Lcom/app/SettingsActivity;" }
        assertTrue(tierC.badges.contains(Badge.STARTUP))
        assertEquals(1, tierC.scopedNops.size)
        assertEquals("show", tierC.scopedNops[0].targetMethod)
    }

    @Test
    fun `engine scan on clean apk finds nothing`() {
        val clean = DexFixtures.TestClass(
            "Lcom/app/Clean;", listOf(
                DexFixtures.TestMethod(
                    "doWork", impl = DexFixtures.implOf(DexFixtures.returnVoid())
                )
            )
        )
        val dexFile = File.createTempFile("e2eclean", ".dex")
        dexFile.deleteOnExit()
        Patcher.writeDex(DexFixtures.buildDex(listOf(clean)), dexFile)
        val apk = File.createTempFile("e2eclean", ".apk")
        apk.deleteOnExit()
        ZipOutputStream(apk.outputStream()).use { zos ->
            zos.putNextEntry(ZipEntry("classes.dex"))
            dexFile.inputStream().copyTo(zos)
            zos.closeEntry()
        }
        val result = Engine.scan(apk) {}
        assertTrue(result.detections.isEmpty())
    }
}
