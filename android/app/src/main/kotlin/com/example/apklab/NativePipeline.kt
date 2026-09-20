package com.example.apklab

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import com.android.apksig.ApkSigner
import com.android.apksig.ApkVerifier
import java.io.BufferedReader
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

object NativePipeline {
    private const val KEYSTORE_PASS = "apklab123"
    private const val KEY_ALIAS = "apklab"
    private const val PREFS_NAME = "apklab_prefs"
    private const val PREF_TREE_URI = "selected_tree_uri"
    private const val PREF_TREE_NAME = "selected_tree_name"

    fun getPrivateWorkspaceDir(context: Context): String {
        val dir = File(context.cacheDir, "apklab_workspace")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir.absolutePath
    }

    fun getPersistedOutputDirectory(context: Context): Map<String, String>? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val uriStr = prefs.getString(PREF_TREE_URI, null) ?: return null
        val treeUri = Uri.parse(uriStr)

        val hasPerm = context.contentResolver.persistedUriPermissions.any {
            it.uri == treeUri && it.isWritePermission
        }
        if (!hasPerm) return null

        val doc = DocumentFile.fromTreeUri(context, treeUri)
        val name = prefs.getString(PREF_TREE_NAME, null) ?: doc?.name ?: treeUri.lastPathSegment ?: "Selected Folder"
        return mapOf(
            "uri" to uriStr,
            "displayName" to name
        )
    }

    fun savePersistedOutputDirectory(context: Context, uri: Uri, flags: Int): Map<String, String> {
        val takeFlags = flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            context.contentResolver.takePersistableUriPermission(uri, takeFlags)
        } catch (_: Exception) {}

        val doc = DocumentFile.fromTreeUri(context, uri)
        val name = doc?.name ?: uri.lastPathSegment ?: "Selected Folder"

        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(PREF_TREE_URI, uri.toString())
            .putString(PREF_TREE_NAME, name)
            .apply()

        return mapOf(
            "uri" to uri.toString(),
            "displayName" to name
        )
    }

    fun exportApkToSaf(
        context: Context,
        sourceFilePath: String,
        targetFileName: String,
        treeUriString: String?
    ): Map<String, Any> {
        val sourceFile = File(sourceFilePath)
        if (!sourceFile.exists() || sourceFile.length() == 0L) {
            throw IllegalArgumentException("Source APK file does not exist or is empty: $sourceFilePath")
        }

        val resolvedUriStr = if (!treeUriString.isNullOrBlank()) {
            treeUriString
        } else {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.getString(PREF_TREE_URI, null)
        }

        if (resolvedUriStr.isNullOrBlank()) {
            throw IllegalStateException("Please choose an output folder first.")
        }

        val treeUri = Uri.parse(resolvedUriStr)
        val targetDir = DocumentFile.fromTreeUri(context, treeUri)
            ?: throw IllegalStateException("Android did not grant access to the selected folder.")

        if (!targetDir.canWrite()) {
            throw IllegalStateException("Android did not grant access to the selected folder.")
        }

        val existing = targetDir.findFile(targetFileName)
        if (existing != null && existing.exists()) {
            try {
                existing.delete()
            } catch (_: Exception) {}
        }

        val newDoc = targetDir.createFile("application/vnd.android.package-archive", targetFileName)
            ?: throw IllegalStateException("Failed to create document file '$targetFileName' in selected folder.")

        context.contentResolver.openOutputStream(newDoc.uri)?.use { outStream ->
            sourceFile.inputStream().use { inStream ->
                inStream.copyTo(outStream)
            }
        } ?: throw IllegalStateException("Failed to open output stream for document: ${newDoc.uri}")

        val exportedSize = newDoc.length()
        if (exportedSize == 0L) {
            throw IllegalStateException("APK was built successfully but export failed.")
        }

        val displayPath = "${targetDir.name ?: "Output"}/$targetFileName"

        return mapOf(
            "success" to true,
            "uri" to newDoc.uri.toString(),
            "fileName" to targetFileName,
            "sizeBytes" to exportedSize,
            "displayPath" to displayPath
        )
    }

    fun installApk(context: Context, pathOrUri: String) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            if (pathOrUri.startsWith("content://")) {
                val uri = Uri.parse(pathOrUri)
                setDataAndType(uri, "application/vnd.android.package-archive")
            } else {
                val file = File(pathOrUri)
                if (!file.exists()) {
                    throw IllegalArgumentException("APK file does not exist at: $pathOrUri")
                }
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                setDataAndType(uri, "application/vnd.android.package-archive")
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun shareApk(context: Context, pathOrUri: String) {
        val uri = if (pathOrUri.startsWith("content://")) {
            Uri.parse(pathOrUri)
        } else {
            val file = File(pathOrUri)
            if (!file.exists()) {
                throw IllegalArgumentException("APK file does not exist at: $pathOrUri")
            }
            FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        }

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/vnd.android.package-archive"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(intent, "Share Patched APK").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(chooser)
    }

    fun openFile(context: Context, pathOrUri: String) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            if (pathOrUri.startsWith("content://")) {
                val uri = Uri.parse(pathOrUri)
                setDataAndType(uri, "*/*")
            } else {
                val file = File(pathOrUri)
                if (!file.exists()) {
                    throw IllegalArgumentException("File does not exist at: $pathOrUri")
                }
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                setDataAndType(uri, "*/*")
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    /**
     * Performs standard Android zipalign on an APK archive:
     * - Preserves STORED (uncompressed) compression for resources.arsc and lib/**\/*.so
     * - Aligns uncompressed .so libraries to 4096-byte (4KB) page boundaries
     * - Aligns all other uncompressed entries (resources.arsc, assets) to 4-byte boundaries
     */
    fun zipalignApk(inputPath: String, outputPath: String): Map<String, Any> {
        val inputFile = File(inputPath)
        if (!inputFile.exists() || inputFile.length() == 0L) {
            throw IllegalArgumentException("Input APK for zipalign does not exist: $inputPath")
        }

        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) {
            outputFile.delete()
        }

        var uncompressedCount = 0
        var alignedCount = 0

        ZipFile(inputFile).use { zipIn ->
            val countingOut = CountingOutputStream(FileOutputStream(outputFile))
            ZipOutputStream(countingOut).use { zipOut =
                // Set compression level
                zipOut.setLevel(java.util.zip.Deflater.BEST_COMPRESSION)

                val entries = zipIn.entries()
                while (entries.hasMoreElements()) {
                    val entry = entries.nextElement()
                    val entryName = entry.name

                    // Skip old signature files in META-INF
                    if (entryName.startsWith("META-INF/") &&
                        (entryName.endsWith(".SF") || entryName.endsWith(".RSA") ||
                         entryName.endsWith(".DSA") || entryName.endsWith(".EC") ||
                         entryName == "META-INF/MANIFEST.MF")) {
                        continue
                    }

                    val isStored = entry.method == ZipEntry.STORED ||
                                   entryName == "resources.arsc" ||
                                   entryName.startsWith("lib/") && entryName.endsWith(".so")

                    val newEntry = ZipEntry(entryName)
                    newEntry.comment = entry.comment

                    val dataBytes = zipIn.getInputStream(entry).use { it.readBytes() }

                    if (isStored) {
                        uncompressedCount++
                        newEntry.method = ZipEntry.STORED
                        newEntry.size = dataBytes.size.toLong()
                        newEntry.compressedSize = dataBytes.size.toLong()

                        val crc = CRC32()
                        crc.update(dataBytes)
                        newEntry.crc = crc.value

                        // Compute alignment: 4096 for .so, 4 for other uncompressed
                        val alignment = if (entryName.endsWith(".so")) 4096 else 4
                        val headerFixedSize = 30
                        val nameLength = entryName.toByteArray(Charsets.UTF_8).size
                        val existingExtra = entry.extra ?: ByteArray(0)

                        val currentOffset = countingOut.bytesWritten
                        val dataOffset = currentOffset + headerFixedSize + nameLength + existingExtra.size
                        val padding = ((alignment - (dataOffset % alignment)) % alignment).toInt()

                        val finalExtra = if (padding > 0) {
                            ByteArray(existingExtra.size + padding).also {
                                System.arraycopy(existingExtra, 0, it, 0, existingExtra.size)
                            }
                        } else {
                            existingExtra
                        }
                        newEntry.extra = finalExtra
                        alignedCount++
                    } else {
                        newEntry.method = ZipEntry.DEFLATED
                        newEntry.extra = entry.extra
                    }

                    zipOut.putNextEntry(newEntry)
                    zipOut.write(dataBytes)
                    zipOut.closeEntry()
                }
            }
        }

        // Verify alignment
        val verifyRes = verifyZipAlignment(outputPath)

        return mapOf(
            "success" to true,
            "outputPath" to outputFile.absolutePath,
            "sizeBytes" to outputFile.length(),
            "uncompressedCount" to uncompressedCount,
            "alignedCount" to alignedCount,
            "isAligned" to (verifyRes["isAligned"] as? Boolean ?: false),
            "alignmentReport" to verifyRes
        )
    }

    /**
     * Verifies 4-byte and 4096-byte alignment of uncompressed entries in an APK
     */
    fun verifyZipAlignment(apkPath: String): Map<String, Any> {
        val apkFile = File(apkPath)
        if (!apkFile.exists() || apkFile.length() < 22) {
            return mapOf("isAligned" to false, "error" to "File does not exist or too small")
        }

        val misaligned = mutableListOf<String>()
        var verifiedCount = 0

        RandomAccessFile(apkFile, "r").use { raf ->
            val fileLength = raf.length()
            // Find EOCD (search backwards in last 1024 bytes)
            val searchLen = Math.min(fileLength, 1024L).toInt()
            val buffer = ByteArray(searchLen)
            raf.seek(fileLength - searchLen)
            raf.readFully(buffer)

            var eocdOffset = -1L
            for (i in (searchLen - 22) downTo 0) {
                if (buffer[i] == 0x50.toByte() && buffer[i + 1] == 0x4b.toByte() &&
                    buffer[i + 2] == 0x05.toByte() && buffer[i + 3] == 0x06.toByte()) {
                    eocdOffset = fileLength - searchLen + i
                    break
                }
            }

            if (eocdOffset == -1L) {
                return mapOf("isAligned" to false, "error" to "Cannot find End of Central Directory")
            }

            // Read CD start offset and entries count
            raf.seek(eocdOffset + 10)
            val numEntries = readShortLittleEndian(raf)
            raf.seek(eocdOffset + 16)
            val cdOffset = readIntLittleEndian(raf)

            raf.seek(cdOffset)
            for (entryIdx in 0 until numEntries) {
                val sig = readIntLittleEndian(raf)
                if (sig != 0x02014b50L) break

                raf.seek(raf.filePointer + 6) // skip version made by & version needed
                val method = readShortLittleEndian(raf)
                raf.seek(raf.filePointer + 16) // skip time, date, crc, compSize, uncompSize
                val nameLen = readShortLittleEndian(raf)
                val extraLen = readShortLittleEndian(raf)
                val commentLen = readShortLittleEndian(raf)
                raf.seek(raf.filePointer + 8) // skip disk start, int attr, ext attr
                val localHeaderOffset = readIntLittleEndian(raf)

                val nameBytes = ByteArray(nameLen)
                raf.readFully(nameBytes)
                val entryName = String(nameBytes, Charsets.UTF_8)

                raf.seek(raf.filePointer + extraLen + commentLen) // skip extra & comment in CD

                if (method == 0) { // STORED (uncompressed)
                    val curPos = raf.filePointer
                    raf.seek(localHeaderOffset)
                    val localSig = readIntLittleEndian(raf)
                    if (localSig == 0x04034b50L) {
                        raf.seek(localHeaderOffset + 26)
                        val localNameLen = readShortLittleEndian(raf)
                        val localExtraLen = readShortLittleEndian(raf)
                        val dataOffset = localHeaderOffset + 30 + localNameLen + localExtraLen

                        val alignment = if (entryName.endsWith(".so")) 4096 else 4
                        if (dataOffset % alignment != 0L) {
                            misaligned.add("$entryName (offset $dataOffset, expected % $alignment == 0)")
                        } else {
                            verifiedCount++
                        }
                    }
                    raf.seek(curPos)
                }
            }
        }

        return mapOf(
            "isAligned" to misaligned.isEmpty(),
            "verifiedCount" to verifiedCount,
            "misalignedCount" to misaligned.size,
            "misalignedEntries" to misaligned
        )
    }

    /**
     * Signs an APK using ApkSigner with v1, v2, and v3 schemes.
     * Supports either the bundled ApkLab keystore or a user-specified keystore.
     */
    fun signApk(
        context: Context,
        inputPath: String,
        outputPath: String,
        customKeystorePath: String? = null,
        customKeystorePass: String? = null,
        customKeyAlias: String? = null
    ): Map<String, Any> {
        val inputFile = File(inputPath)
        if (!inputFile.exists() || inputFile.length() == 0L) {
            throw IllegalArgumentException("Unsigned APK does not exist or is empty: $inputPath")
        }

        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) {
            outputFile.delete()
        }

        val keyStore = KeyStore.getInstance("PKCS12")
        val pass = customKeystorePass ?: KEYSTORE_PASS
        val alias = customKeyAlias ?: KEY_ALIAS

        if (!customKeystorePath.isNullOrBlank() && File(customKeystorePath).exists()) {
            FileInputStream(customKeystorePath).use { inStream ->
                keyStore.load(inStream, pass.toCharArray())
            }
        } else {
            context.assets.open("apklab_keystore.p12").use { inStream ->
                keyStore.load(inStream, KEYSTORE_PASS.toCharArray())
            }
        }

        val privateKey = keyStore.getKey(alias, pass.toCharArray()) as? PrivateKey
            ?: throw IllegalStateException("Key alias '$alias' not found or not a PrivateKey in keystore.")
        val cert = keyStore.getCertificate(alias) as? X509Certificate
            ?: throw IllegalStateException("Certificate for alias '$alias' not found in keystore.")

        val signerConfig = ApkSigner.SignerConfig.Builder(
            "ApkLab",
            privateKey,
            listOf(cert)
        ).build()

        val signer = ApkSigner.Builder(listOf(signerConfig))
            .setInputApk(inputFile)
            .setOutputApk(outputFile)
            .setV1SigningEnabled(true)
            .setV2SigningEnabled(true)
            .setV3SigningEnabled(true)
            .build()

        signer.sign()

        if (!outputFile.exists() || outputFile.length() == 0L) {
            throw IllegalStateException("Signed APK was not generated at: $outputPath")
        }

        val verifyResult = verifySignature(outputFile.absolutePath)

        return mapOf(
            "success" to true,
            "outputPath" to outputFile.absolutePath,
            "sizeBytes" to outputFile.length(),
            "v1SchemeSigned" to (verifyResult["v1SchemeSigned"] as? Boolean ?: false),
            "v2SchemeSigned" to (verifyResult["v2SchemeSigned"] as? Boolean ?: false),
            "v3SchemeSigned" to (verifyResult["v3SchemeSigned"] as? Boolean ?: false),
            "isVerified" to (verifyResult["isVerified"] as? Boolean ?: false),
            "signerSubject" to (verifyResult["signerSubject"] as? String ?: "CN=ApkLab"),
            "verificationReport" to verifyResult
        )
    }

    /**
     * Verifies the cryptographic signature of an APK using ApkVerifier
     */
    fun verifySignature(apkPath: String): Map<String, Any> {
        val apkFile = File(apkPath)
        if (!apkFile.exists() || apkFile.length() == 0L) {
            return mapOf("isVerified" to false, "error" to "APK file does not exist or is empty")
        }

        val verifier = ApkVerifier.Builder(apkFile).build()
        val result = verifier.verify()

        var signerSubject = "Unknown Signer"
        val signerCerts = result.signerCertificates
        if (signerCerts.isNotEmpty()) {
            signerSubject = signerCerts.first().subjectX500Principal?.name ?: "Unknown Signer"
        }

        val errors = mutableListOf<String>()
        for (err in result.errors) {
            errors.add(err.toString())
        }
        for (signer in result.v1SchemeSigners) {
            for (err in signer.errors) errors.add("v1: $err")
        }
        for (signer in result.v2SchemeSigners) {
            for (err in signer.errors) errors.add("v2: $err")
        }
        for (signer in result.v3SchemeSigners) {
            for (err in signer.errors) errors.add("v3: $err")
        }

        return mapOf(
            "isVerified" to result.isVerified,
            "v1SchemeSigned" to result.isVerifiedUsingV1Scheme,
            "v2SchemeSigned" to result.isVerifiedUsingV2Scheme,
            "v3SchemeSigned" to result.isVerifiedUsingV3Scheme,
            "signerSubject" to signerSubject,
            "signersCount" to signerCerts.size,
            "errors" to errors
        )
    }

    /**
     * High-level complete sign and zipalign:
     * 1. Zipalign the unsigned APK to ensure 4-byte and 4096-byte alignment
     * 2. Sign the aligned APK with ApkSigner
     * 3. Verify the final signature with ApkVerifier
     */
    fun signAndZipalign(context: Context, inputPath: String, outputPath: String): Map<String, Any> {
        val inputFile = File(inputPath)
        if (!inputFile.exists() || inputFile.length() == 0L) {
            throw IllegalArgumentException("Unsigned APK does not exist or is empty: $inputPath")
        }

        // Temporary aligned APK path
        val alignedPath = "${inputFile.parentFile?.absolutePath}/temp_aligned_${System.currentTimeMillis()}.apk"

        try {
            // Stage 1: Zipalign
            val alignResult = zipalignApk(inputPath, alignedPath)
            if (alignResult["success"] != true) {
                throw IllegalStateException("Zipalign failed on input APK: $inputPath")
            }

            // Stage 2: Sign
            val signResult = signApk(context, alignedPath, outputPath)
            if (signResult["isVerified"] != true) {
                throw IllegalStateException("Signature verification failed after signing: ${signResult["verificationReport"]}")
            }

            return signResult
        } finally {
            // Clean up temporary aligned APK
            val tempAligned = File(alignedPath)
            if (tempAligned.exists()) {
                tempAligned.delete()
            }
        }
    }

    /**
     * Reads recent logcat entries to capture any immediate crash/fatal exception on app launch
     */
    fun captureRuntimeDiagnostics(packageName: String): Map<String, Any> {
        val crashPatterns = listOf(
            "FATAL EXCEPTION",
            "AndroidRuntime",
            "VerifyError",
            "ClassNotFoundException",
            "NoClassDefFoundError",
            "NoSuchMethodError",
            "Resources\$NotFoundException",
            "InflateException",
            "SecurityException",
            "UnsatisfiedLinkError",
            "IllegalAccessError",
            "NullPointerException",
            "ActivityNotFoundException",
            "INSTALL_FAILED",
            "LinkageError"
        )

        try {
            val process = Runtime.getRuntime().exec(arrayOf("logcat", "-d", "-t", "500", "-v", "time"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val lines = mutableListOf<String>()
            var foundCrash = false
            var rootException = ""
            var targetClass = ""
            var targetMethod = ""
            var cause = ""

            var line = reader.readLine()
            while (line != null) {
                lines.add(line)
                for (pattern in crashPatterns) {
                    if (line.contains(pattern, ignoreCase = true)) {
                        foundCrash = true
                        if (rootException.isEmpty()) {
                            rootException = pattern
                        }
                        if (line.contains("VerifyError", ignoreCase = true) ||
                            line.contains("ClassNotFoundException", ignoreCase = true) ||
                            line.contains("NoSuchMethodError", ignoreCase = true) ||
                            line.contains("UnsatisfiedLinkError", ignoreCase = true) ||
                            line.contains("Resources\$NotFoundException", ignoreCase = true)) {
                            rootException = line.trim()
                        }
                    }
                }
                if (line.contains("Caused by:", ignoreCase = true)) {
                    cause = line.trim()
                }
                line = reader.readLine()
            }

            return mapOf(
                "hasCrash" to foundCrash,
                "rootException" to rootException,
                "targetClass" to targetClass,
                "targetMethod" to targetMethod,
                "cause" to cause,
                "logcatSnippet" to lines.takeLast(60).joinToString("\n")
            )
        } catch (e: Exception) {
            return mapOf(
                "hasCrash" to false,
                "error" to (e.message ?: "Failed to read logcat")
            )
        }
    }

    private fun readShortLittleEndian(raf: RandomAccessFile): Int {
        val b1 = raf.read()
        val b2 = raf.read()
        return (b2 shl 8) or b1
    }

    private fun readIntLittleEndian(raf: RandomAccessFile): Long {
        val b1 = raf.read().toLong()
        val b2 = raf.read().toLong()
        val b3 = raf.read().toLong()
        val b4 = raf.read().toLong()
        return (b4 shl 24) or (b3 shl 16) or (b2 shl 8) or b1
    }

    private class CountingOutputStream(out: FileOutputStream) : java.io.FilterOutputStream(out) {
        var bytesWritten: Long = 0
            private set

        override fun write(b: Int) {
            out.write(b)
            bytesWritten++
        }

        override fun write(b: ByteArray, off: Int, len: Int) {
            out.write(b, off, len)
            bytesWritten += len
        }
    }
}
