package com.example.apklab

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.apklab/native_pipeline"
    private var pendingFolderResult: MethodChannel.Result? = null
    private val REQUEST_CODE_PICK_FOLDER = 9001
    private val backgroundExecutor = Executors.newFixedThreadPool(4)

    override fun onDestroy() {
        super.onDestroy()
        backgroundExecutor.shutdown()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickOutputDirectory" -> {
                    pendingFolderResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        addFlags(
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                            Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                        )
                    }
                    startActivityForResult(intent, REQUEST_CODE_PICK_FOLDER)
                }
                "getPersistedOutputDirectory" -> {
                    val info = NativePipeline.getPersistedOutputDirectory(this)
                    result.success(info)
                }
                "getPrivateWorkspaceDir" -> {
                    val path = NativePipeline.getPrivateWorkspaceDir(this)
                    result.success(path)
                }
                "exportApkToSaf" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    val treeUri = call.argument<String>("treeUri")
                    if (sourcePath != null && fileName != null) {
                        backgroundExecutor.execute {
                            try {
                                val exportResult = NativePipeline.exportApkToSaf(this@MainActivity, sourcePath, fileName, treeUri)
                                runOnUiThread { result.success(exportResult) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("EXPORT_ERROR", e.message, e.stackTraceToString()) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "sourcePath and fileName are required", null)
                    }
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            NativePipeline.installApk(this, path)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, e.stackTraceToString())
                        }
                    } else {
                        result.error("INVALID_ARGS", "Path is required", null)
                    }
                }
                "shareApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            NativePipeline.shareApk(this, path)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SHARE_ERROR", e.message, e.stackTraceToString())
                        }
                    } else {
                        result.error("INVALID_ARGS", "Path is required", null)
                    }
                }
                "openFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            NativePipeline.openFile(this, path)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_ERROR", e.message, e.stackTraceToString())
                        }
                    } else {
                        result.error("INVALID_ARGS", "Path is required", null)
                    }
                }
                "zipalign" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    if (inputPath != null && outputPath != null) {
                        backgroundExecutor.execute {
                            try {
                                val res = NativePipeline.zipalignApk(inputPath, outputPath)
                                runOnUiThread { result.success(res) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("ZIPALIGN_ERROR", e.message, e.stackTraceToString()) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "inputPath and outputPath are required", null)
                    }
                }
                "verifyZipAlignment" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath != null) {
                        backgroundExecutor.execute {
                            try {
                                val res = NativePipeline.verifyZipAlignment(apkPath)
                                runOnUiThread { result.success(res) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("ALIGN_VERIFY_ERROR", e.message, e.stackTraceToString()) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "apkPath is required", null)
                    }
                }
                "signApk" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    val customKeystorePath = call.argument<String>("customKeystorePath")
                    val customKeystorePass = call.argument<String>("customKeystorePass")
                    val customKeyAlias = call.argument<String>("customKeyAlias")
                    if (inputPath != null && outputPath != null) {
                        backgroundExecutor.execute {
                            try {
                                val signResult = NativePipeline.signApk(
                                    this@MainActivity, inputPath, outputPath,
                                    customKeystorePath, customKeystorePass, customKeyAlias
                                )
                                runOnUiThread { result.success(signResult) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("SIGN_ERROR", e.message, e.stackTraceToString()) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "inputPath and outputPath are required", null)
                    }
                }
                "verifySignature" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath != null) {
                        backgroundExecutor.execute {
                            try {
                                val res = NativePipeline.verifySignature(apkPath)
                                runOnUiThread { result.success(res) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("VERIFY_ERROR", e.message, e.stackTraceToString()) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "apkPath is required", null)
                    }
                }
                "captureRuntimeDiagnostics" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    backgroundExecutor.execute {
                        try {
                            val res = NativePipeline.captureRuntimeDiagnostics(packageName)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("DIAGNOSTIC_ERROR", e.message, e.stackTraceToString()) }
                        }
                    }
                }
                "signAndZipalign" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    if (inputPath != null && outputPath != null) {
                        backgroundExecutor.execute {
                            try {
                                val signResult = NativePipeline.signAndZipalign(this@MainActivity, inputPath, outputPath)
                                runOnUiThread { result.success(signResult) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("SIGN_ERROR", e.message, e.stackTraceToString()) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "inputPath and outputPath are required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_FOLDER) {
            val res = pendingFolderResult
            pendingFolderResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    val uri = data.data!!
                    val info = NativePipeline.savePersistedOutputDirectory(this, uri, data.flags)
                    res?.success(info)
                } catch (e: Exception) {
                    res?.error("PICK_ERROR", e.message, e.stackTraceToString())
                }
            } else {
                res?.success(null)
            }
        }
    }
}
