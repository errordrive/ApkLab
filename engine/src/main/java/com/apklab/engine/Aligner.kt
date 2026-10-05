package com.apklab.engine

import java.io.File
import java.io.FileOutputStream
import java.io.FilterOutputStream
import java.io.OutputStream
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/**
 * Repacks an unpacked APK directory into a zip with proper data alignment
 * (4-byte general, 4096-byte page alignment for .so), as required for
 * APK Signature Scheme v2.
 */
object Aligner {

    fun repackAligned(srcDir: File, outApk: File) {
        val files = srcDir.walkTopDown()
            .filter { it.isFile }
            .map { it.relativeTo(srcDir).path.replace(File.separatorChar, '/') to it }
            .sortedBy { it.first }
            .toList()

        CountingOutputStream(FileOutputStream(outApk).buffered()).use { cos ->
            ZipOutputStream(cos).use { zos ->
                for ((name, file) in files) {
                    val stored = name.endsWith(".so") || name == "resources.arsc"
                    val entry = ZipEntry(name)
                    entry.time = file.lastModified()
                    if (stored) {
                        val (size, crc) = sizeAndCrc(file)
                        val align = if (name.endsWith(".so")) 4096 else 4
                        entry.method = ZipEntry.STORED
                        entry.size = size
                        entry.crc = crc
                        // Local header = 30 + name bytes + extra bytes.
                        val nameLen = name.toByteArray(Charsets.UTF_8).size
                        val headerLen = 30 + nameLen
                        val padding = ((align - ((cos.count + headerLen) % align)) % align).toInt()
                        entry.extra = ByteArray(padding)
                        zos.putNextEntry(entry)
                        file.inputStream().buffered().use { it.copyTo(zos) }
                        zos.closeEntry()
                    } else {
                        entry.method = ZipEntry.DEFLATED
                        zos.putNextEntry(entry)
                        file.inputStream().buffered().use { it.copyTo(zos) }
                        zos.closeEntry()
                    }
                }
            }
        }
    }

    private fun sizeAndCrc(file: File): Pair<Long, Long> {
        val crc = CRC32()
        var size = 0L
        val buf = ByteArray(65536)
        file.inputStream().buffered().use { ins ->
            while (true) {
                val n = ins.read(buf)
                if (n < 0) break
                crc.update(buf, 0, n)
                size += n
            }
        }
        return size to crc.value
    }

    private class CountingOutputStream(out: OutputStream) : FilterOutputStream(out) {
        var count: Long = 0
            private set

        override fun write(b: Int) {
            out.write(b)
            count++
        }

        override fun write(b: ByteArray, off: Int, len: Int) {
            out.write(b, off, len)
            count += len
        }
    }
}
