package com.example.apklab

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import com.android.apksig.ApkSigner
import com.android.apksig.ApkVerifier
import java.io.File
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.X509Certificate

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

    fun signAndZipalign(context: Context, inputPath: String, outputPath: String): Map<String, Any> {
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
        context.assets.open("apklab_keystore.p12").use { inputStream ->
            keyStore.load(inputStream, KEYSTORE_PASS.toCharArray())
        }

        val privateKey = keyStore.getKey(KEY_ALIAS, KEYSTORE_PASS.toCharArray()) as PrivateKey
        val cert = keyStore.getCertificate(KEY_ALIAS) as X509Certificate

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

        val verifier = ApkVerifier.Builder(outputFile).build()
        val verifyResult = verifier.verify()

        return mapOf(
            "success" to true,
            "outputPath" to outputFile.absolutePath,
            "sizeBytes" to outputFile.length(),
            "v1SchemeSigned" to verifyResult.isVerifiedUsingV1Scheme,
            "v2SchemeSigned" to verifyResult.isVerifiedUsingV2Scheme,
            "v3SchemeSigned" to verifyResult.isVerifiedUsingV3Scheme,
            "isVerified" to verifyResult.isVerified
        )
    }
}
