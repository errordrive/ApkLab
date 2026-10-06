package com.apklab.app

import android.Manifest
import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.OpenableColumns
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.apklab.app.ui.Screen
import com.apklab.engine.Detection
import com.apklab.engine.Engine
import com.apklab.engine.PatchReport
import com.apklab.engine.ScanResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

data class RecentPatch(
    val name: String,
    val path: String,
    val methods: Int,
    val hooks: Int,
    val ts: Long,
)

data class UiState(
    val screen: Screen = Screen.PermissionGate,
    val permissionDenied: Boolean = false,
    val darkMode: Boolean = false,
    val apkChoices: List<File> = emptyList(),
    val pickedApk: File? = null,
    val pickedName: String = "",
    val scanning: Boolean = false,
    val scanLog: List<String> = emptyList(),
    val scanResult: ScanResult? = null,
    val selected: Set<String> = emptySet(),
    val scanError: String? = null,
    val report: PatchReport? = null,
    val patching: Boolean = false,
    val patchLog: List<String> = emptyList(),
    val patchOutput: File? = null,
    val patchError: String? = null,
    val recent: List<RecentPatch> = emptyList(),
    val infoMessage: String? = null,
)

class AppViewModel(app: Application) : AndroidViewModel(app) {

    private val prefs: SharedPreferences =
        app.getSharedPreferences("apklab", Context.MODE_PRIVATE)

    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state

    init {
        _state.update { it.copy(darkMode = prefs.getBoolean("dark", false)) }
        loadRecent()
        if (hasStoragePermission()) {
            Workspace.ensure()
            _state.update { it.copy(screen = Screen.Home) }
            refreshApkChoices()
        }
    }

    // ---------- permissions ----------

    fun hasStoragePermission(): Boolean =
        if (Build.VERSION.SDK_INT >= 30) {
            Environment.isExternalStorageManager()
        } else {
            getApplication<Application>().checkSelfPermission(
                Manifest.permission.READ_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }

    fun onPermissionResult(granted: Boolean) {
        if (granted) {
            Workspace.ensure()
            _state.update { it.copy(screen = Screen.Home, permissionDenied = false) }
            refreshApkChoices()
        } else {
            _state.update { it.copy(permissionDenied = true) }
        }
    }

    /** Re-check when returning from Settings. */
    fun onResumeCheck() {
        if (_state.value.screen == Screen.PermissionGate && hasStoragePermission()) {
            onPermissionResult(true)
        }
    }

    fun toggleDark() {
        val next = !_state.value.darkMode
        prefs.edit().putBoolean("dark", next).apply()
        _state.update { it.copy(darkMode = next) }
    }

    fun clearInfo() = _state.update { it.copy(infoMessage = null) }

    fun goHome() {
        _state.update {
            it.copy(
                screen = Screen.Home,
                scanResult = null, report = null, patchOutput = null,
                scanError = null, patchError = null,
            )
        }
        refreshApkChoices()
    }

    fun goBackFrom(screen: Screen) {
        when (screen) {
            Screen.Analyze -> goHome()
            Screen.Report -> _state.update { it.copy(screen = Screen.Analyze) }
            Screen.Patch -> { /* block back while patching */ }
            Screen.Result -> goHome()
            else -> {}
        }
    }

    // ---------- APK picking ----------

    fun refreshApkChoices() {
        viewModelScope.launch(Dispatchers.IO) {
            val dl = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val list = dl?.listFiles { f -> f.isFile && f.name.endsWith(".apk", ignoreCase = true) }
                ?.sortedByDescending { it.lastModified() }
                ?.take(25) ?: emptyList()
            _state.update { it.copy(apkChoices = list) }
        }
    }

    /** Local file chosen from the Download list. */
    fun pickLocalApk(file: File) {
        onApkChosen(file, file.name)
    }

    /** SAF uri chosen via "Browse files…": stage into cache, then scan. */
    fun importSafApk(uri: Uri) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val ctx = getApplication<Application>()
                var name = "picked.apk"
                ctx.contentResolver.query(uri, null, null, null, null)?.use { c ->
                    val idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (c.moveToFirst() && idx >= 0) {
                        c.getString(idx)?.let { if (it.isNotBlank()) name = it }
                    }
                }
                if (!name.endsWith(".apk", true)) name += ".apk"
                val dest = File(ctx.cacheDir, "import-$name")
                ctx.contentResolver.openInputStream(uri)?.use { input ->
                    dest.outputStream().use { input.copyTo(it) }
                }
                withContext(Dispatchers.Main) { onApkChosen(dest, name) }
            } catch (e: Exception) {
                _state.update { it.copy(infoMessage = "Import failed: ${e.message}") }
            }
        }
    }

    private fun onApkChosen(file: File, displayName: String) {
        _state.update {
            it.copy(
                pickedApk = file,
                pickedName = displayName,
                screen = Screen.Analyze,
                scanning = true,
                scanLog = emptyList(),
                scanResult = null,
                scanError = null,
                selected = emptySet(),
                report = null,
                patchOutput = null,
                patchLog = emptyList(),
                patchError = null,
            )
        }
        startScan(file)
    }

    // ---------- analyze ----------

    private fun startScan(file: File) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val result = Engine.scan(file) { line ->
                    _state.update { it.copy(scanLog = (it.scanLog + line).takeLast(200)) }
                }
                // Defensive: one card per class, even if a dex quirk ever
                // produced the same class twice.
                val deduped = result.copy(
                    detections = result.detections.distinctBy { it.classType }
                )
                _state.update {
                    it.copy(
                        scanning = false,
                        scanResult = deduped,
                        selected = deduped.detections.map { d -> d.classType }.toSet(),
                    )
                }
            } catch (e: Exception) {
                _state.update { it.copy(scanning = false, scanError = e.message ?: "Scan failed") }
            }
        }
    }

    fun retryScan() {
        val file = _state.value.pickedApk ?: return
        _state.update { it.copy(scanning = true, scanLog = emptyList(), scanError = null) }
        startScan(file)
    }

    fun toggleDetection(classType: String) {
        _state.update {
            val s = it.selected.toMutableSet()
            if (!s.add(classType)) s.remove(classType)
            it.copy(selected = s)
        }
    }

    // ---------- report ----------

    fun generateReport() {
        val result = _state.value.scanResult ?: return
        val filtered = result.copy(
            detections = result.detections.filter { it.classType in _state.value.selected }
        )
        try {
            val report = Engine.buildReport(filtered)
            _state.update { it.copy(report = report, screen = Screen.Report) }
        } catch (e: Exception) {
            _state.update { it.copy(infoMessage = "Report failed: ${e.message}") }
        }
    }

    fun reportText(): String? = _state.value.report?.toText()

    fun saveReport(): File? {
        val report = _state.value.report ?: return null
        return try {
            val dir = Workspace.reports().apply { mkdirs() }
            val base = _state.value.pickedName.substringBeforeLast('.').ifBlank { "report" }
            val f = Workspace.uniqueFile(dir, "$base-report.txt")
            f.writeText(report.toText())
            _state.update { it.copy(infoMessage = "Report saved to ${f.name}") }
            f
        } catch (e: Exception) {
            _state.update { it.copy(infoMessage = "Save failed: ${e.message}") }
            null
        }
    }

    // ---------- patch ----------

    private fun ensureKeystore(): File {
        val ctx = getApplication<Application>()
        val f = File(ctx.filesDir, "apklab.keystore")
        if (!f.exists()) {
            ctx.assets.open("apklab.keystore").use { input ->
                f.outputStream().use { input.copyTo(it) }
            }
        }
        return f
    }

    fun startPatch() {
        val report = _state.value.report ?: return
        val src = _state.value.pickedApk ?: return
        if (report.detections.isEmpty()) {
            _state.update { it.copy(infoMessage = "Nothing selected to patch.") }
            return
        }
        _state.update {
            it.copy(
                screen = Screen.Patch,
                patching = true,
                patchLog = emptyList(),
                patchError = null,
                patchOutput = null,
            )
        }
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val ks = ensureKeystore()
                val outDir = Workspace.patched().apply { mkdirs() }
                val base = _state.value.pickedName.substringBeforeLast('.').ifBlank { "app" }
                val out = Workspace.uniqueFile(outDir, "$base-patched.apk")
                val file = Engine.patch(
                    src, report.detections, out, ks,
                    "android", "apklab", "android",
                ) { line ->
                    _state.update { it.copy(patchLog = (it.patchLog + line).takeLast(300)) }
                }
                val methods = report.detections.sumOf { it.methodsToGut.size }
                val hooks = report.detections.sumOf { it.hookSites.size }
                addRecent(RecentPatch(file.name, file.absolutePath, methods, hooks, System.currentTimeMillis()))
                _state.update { it.copy(patching = false, patchOutput = file, screen = Screen.Result) }
            } catch (e: Exception) {
                _state.update { it.copy(patching = false, patchError = e.message ?: "Patch failed") }
            }
        }
    }

    fun patchStepIndex(): Int {
        var step = 0
        for (line in _state.value.patchLog) {
            val l = line.lowercase()
            step = maxOf(
                step,
                when {
                    l.contains("sign") || l.contains("verif") -> 4
                    l.contains("repack") || l.contains("zipalign") || l.contains("align") -> 3
                    l.contains("patch") || l.contains("gut") || l.contains("nop") || l.contains("hook") -> 2
                    l.contains("scan") || l.contains("detect") || l.contains("analyz") -> 1
                    else -> 0
                }
            )
        }
        return step
    }

    // ---------- recent ----------

    private fun loadRecent() {
        val list = mutableListOf<RecentPatch>()
        try {
            val arr = JSONArray(prefs.getString("recent", "[]"))
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                val f = File(o.optString("path"))
                if (!f.exists()) continue
                list += RecentPatch(
                    o.optString("name"), o.optString("path"),
                    o.optInt("methods"), o.optInt("hooks"), o.optLong("ts"),
                )
            }
        } catch (e: Exception) { /* ignore */ }
        _state.update { it.copy(recent = list) }
    }

    private fun addRecent(r: RecentPatch) {
        val list = (_state.value.recent + r).takeLast(20)
        try {
            val arr = JSONArray()
            list.forEach {
                arr.put(
                    JSONObject().put("name", it.name).put("path", it.path)
                        .put("methods", it.methods).put("hooks", it.hooks).put("ts", it.ts)
                )
            }
            prefs.edit().putString("recent", arr.toString()).apply()
        } catch (e: Exception) { /* ignore */ }
        _state.update { it.copy(recent = list) }
    }
}
