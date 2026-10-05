package com.apklab.engine

import java.io.File
import java.util.zip.ZipFile

/** ZIP-level helpers: dex listing, extraction, full unzip, signature-scheme detection. */
object ApkIO {

    private val DEX_NAME = Regex("classes\\d*\\.dex")

    fun listDexNames(apk: File): List<String> {
        ZipFile(apk).use { zf ->
            return zf.entries().asSequence()
                .map { it.name }
                .filter { DEX_NAME.matches(it) }
                .sorted()
                .toList()
        }
    }

    fun extractDex(apk: File, dexName: String, out: File) {
        ZipFile(apk).use { zf ->
            val e = zf.getEntry(dexName)
                ?: throw IllegalArgumentException("Entry $dexName not found in APK")
            zf.getInputStream(e).use { ins ->
                out.outputStream().use { outs -> ins.copyTo(outs) }
            }
        }
    }

    fun unzipApk(apk: File, dir: File) {
        ZipFile(apk).use { zf ->
            for (e in zf.entries()) {
                if (e.isDirectory) continue
                val out = dir.resolve(e.name)
                out.parentFile.mkdirs()
                zf.getInputStream(e).use { ins ->
                    out.outputStream().use { outs -> ins.copyTo(outs) }
                }
            }
        }
    }

    fun detectSigSchemes(apk: File): List<String> {
        val schemes = mutableListOf<String>()
        ZipFile(apk).use { zf ->
            val names = zf.entries().asSequence().map { it.name }.toList()
            if (names.any { n ->
                    n.startsWith("META-INF/") &&
                            (n.endsWith(".SF") || n.endsWith(".RSA") || n.endsWith(".DSA"))
                }
            ) schemes.add("v1")
        }
        if (hasApkSigningBlock(apk)) schemes.add("v2")
        if (schemes.isEmpty()) schemes.add("unsigned")
        return schemes
    }

    /**
     * Checks for the APK Signing Block magic ("APK Sig Block 42") located
     * immediately before the central directory.
     */
    private fun hasApkSigningBlock(apk: File): Boolean {
        val raf = java.io.RandomAccessFile(apk, "r")
        try {
            val len = raf.length()
            if (len < 22) return false
            val tailSize = minOf(len, 65557L).toInt()
            val tail = ByteArray(tailSize)
            raf.seek(len - tailSize)
            raf.readFully(tail)
            var eocdPos = -1L
            for (i in tailSize - 22 downTo 0) {
                if (tail[i] == 0x50.toByte() && tail[i + 1] == 0x4b.toByte() &&
                    tail[i + 2] == 0x05.toByte() && tail[i + 3] == 0x06.toByte()
                ) {
                    eocdPos = len - tailSize + i
                    break
                }
            }
            if (eocdPos < 0) return false
            raf.seek(eocdPos + 16)
            val cdOffset = Integer.toUnsignedLong(readIntLE(raf))
            if (cdOffset < 24) return false
            // Signing block footer: [u64 size][16-byte magic] right before central dir.
            val footer = ByteArray(24)
            raf.seek(cdOffset - 24)
            raf.readFully(footer)
            val magic = String(footer, 8, 16, Charsets.US_ASCII)
            return magic == "APK Sig Block 42"
        } catch (_: Exception) {
            return false
        } finally {
            raf.close()
        }
    }

    private fun readIntLE(raf: java.io.RandomAccessFile): Int {
        val b = ByteArray(4)
        raf.readFully(b)
        return (b[0].toInt() and 0xFF) or
                ((b[1].toInt() and 0xFF) shl 8) or
                ((b[2].toInt() and 0xFF) shl 16) or
                ((b[3].toInt() and 0xFF) shl 24)
    }
}
