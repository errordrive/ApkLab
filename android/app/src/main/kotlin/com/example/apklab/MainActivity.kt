package com.example.apklab

import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.apklab/native_pipeline"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
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
                "signAndZipalign" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    if (inputPath != null && outputPath != null) {
                        try {
                            val signResult = NativePipeline.signAndZipalign(this, inputPath, outputPath)
                            result.success(signResult)
                        } catch (e: Exception) {
                            result.error("SIGN_ERROR", e.message, e.stackTraceToString())
                        }
                    } else {
                        result.error("INVALID_ARGS", "inputPath and outputPath are required", null)
                    }
                }
                "getDefaultStoragePath" -> {
                    val base = Environment.getExternalStorageDirectory()?.absolutePath ?: "/storage/emulated/0"
                    result.success(base)
                }
                else -> result.notImplemented()
            }
        }
    }
}
