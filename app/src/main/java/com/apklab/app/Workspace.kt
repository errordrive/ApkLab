package com.apklab.app

import android.os.Environment
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Shared-storage workspace: /storage/emulated/0/ApkLab — created once, reused, never deleted. */
object Workspace {
    fun base(): File = File(Environment.getExternalStorageDirectory(), "ApkLab")
    fun patched(): File = File(base(), "patched")
    fun reports(): File = File(base(), "reports")

    /** Creates base + subdirs if missing. Returns true when usable. */
    fun ensure(): Boolean {
        return try {
            patched().mkdirs()
            reports().mkdirs()
            patched().isDirectory && reports().isDirectory
        } catch (e: Exception) {
            false
        }
    }

    /** Unique file inside dir; appends timestamp on collision. */
    fun uniqueFile(dir: File, name: String): File {
        var f = File(dir, name)
        if (!f.exists()) return f
        val dot = name.lastIndexOf('.')
        val stem = if (dot > 0) name.substring(0, dot) else name
        val ext = if (dot > 0) name.substring(dot) else ""
        f = File(dir, "$stem-${System.currentTimeMillis()}$ext")
        var i = 1
        while (f.exists()) {
            f = File(dir, "$stem-${System.currentTimeMillis()}-$i$ext")
            i++
        }
        return f
    }
}

fun formatBytes(bytes: Long): String {
    if (bytes <= 0) return "0 KB"
    val mb = bytes / (1024.0 * 1024.0)
    return if (mb >= 1) "%.1f MB".format(Locale.US, mb) else "%d KB".format(bytes / 1024)
}

fun formatTime(ts: Long): String =
    SimpleDateFormat("MMM d, yyyy • HH:mm", Locale.US).format(Date(ts))

/** Lcom/a/B; -> com.a.B */
fun prettyClass(type: String): String =
    type.removePrefix("L").removeSuffix(";").replace('/', '.')
