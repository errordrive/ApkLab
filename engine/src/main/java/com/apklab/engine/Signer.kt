package com.apklab.engine

import com.android.apksig.ApkSigner
import com.android.apksig.ApkVerifier
import java.io.File
import java.io.FileInputStream
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.Certificate
import java.security.cert.X509Certificate

/** Signs an (aligned) APK with v1+v2 schemes using a JKS keystore, then verifies. */
object Signer {

    fun sign(
        inputApk: File,
        outputApk: File,
        keystoreFile: File,
        storePass: String,
        alias: String,
        keyPass: String
    ) {
        val ks = KeyStore.getInstance(KeyStore.getDefaultType())
        FileInputStream(keystoreFile).use { ks.load(it, storePass.toCharArray()) }
        val key = ks.getKey(alias, keyPass.toCharArray()) as PrivateKey
        val chain: List<X509Certificate> = ks.getCertificateChain(alias).map { it as X509Certificate }

        val signerConfig = ApkSigner.SignerConfig.Builder(alias, key, chain).build()
        ApkSigner.Builder(listOf(signerConfig))
            .setInputApk(inputApk)
            .setOutputApk(outputApk)
            .setV1SigningEnabled(true)
            .setV2SigningEnabled(true)
            .build()
            .sign()

        val result = ApkVerifier.Builder(outputApk).build().verify()
        if (!result.isVerified) {
            throw IllegalStateException("APK signature verification failed after signing")
        }
    }
}
