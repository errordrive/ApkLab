package com.example.apklab

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import androidx.core.content.FileProvider
import com.android.apksig.ApkSigner
import com.android.apksig.ApkVerifier
import java.io.File
import java.io.InputStream
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.X509Certificate

object NativePipeline {
    private const val KEYSTORE_PASS = "apklab123"
    private const val KEY_ALIAS = "apklab"

    fun installApk(context: Context, path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("APK file does not exist at: $path")
        }
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun shareApk(context: Context, path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("APK file does not exist at: $path")
        }
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
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

    fun openFile(context: Context, path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("File does not exist at: $path")
        }
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "*/*")
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

        // Load PKCS12 keystore from assets
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

        // Verify with ApkVerifier
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
