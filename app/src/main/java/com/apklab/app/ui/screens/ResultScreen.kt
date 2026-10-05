package com.apklab.app.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.apklab.app.AppViewModel
import com.apklab.app.UiState
import com.apklab.app.formatBytes
import com.apklab.app.ui.Screen
import com.apklab.app.ui.components.AmberNote
import com.apklab.app.ui.components.ApkLabTopBar
import com.apklab.app.ui.components.AppCard
import com.apklab.app.ui.components.OutlineButton
import com.apklab.app.ui.components.PrimaryButton
import com.apklab.app.ui.theme.LocalApkLabColors
import java.io.File

@Composable
fun ResultScreen(vm: AppViewModel, state: UiState) {
    val c = LocalApkLabColors.current
    val context = LocalContext.current
    val output = state.patchOutput
    val report = state.report
    var showPath by remember { mutableStateOf(false) }

    val methods = report?.detections?.sumOf { it.methodsToGut.size } ?: 0
    val hooks = report?.detections?.sumOf { it.hookSites.size } ?: 0

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(c.paper)
            .padding(horizontal = 20.dp)
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.height(8.dp))
        ApkLabTopBar(
            title = "Result",
            onBack = { vm.goBackFrom(Screen.Result) },
            darkMode = state.darkMode,
            onToggleDark = vm::toggleDark,
        )

        // success card
        AppCard {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(c.successSoft),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.Check, null, tint = c.success, modifier = Modifier.size(34.dp))
                }
                Spacer(Modifier.height(14.dp))
                Text("Patch Successful!", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = c.ink, textAlign = TextAlign.Center)
                Spacer(Modifier.height(6.dp))
                Text("Dialog-free APK is ready", fontSize = 13.sp, color = c.muted, textAlign = TextAlign.Center)
                if (output != null) {
                    Spacer(Modifier.height(6.dp))
                    Text(output.name, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = c.inkSoft, textAlign = TextAlign.Center)
                }
            }
        }

        // stats
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(13.dp),
        ) {
            StatCard("$methods", "methods\ngutted", Modifier.weight(1f))
            StatCard("$hooks", "hooks\nnopped", Modifier.weight(1f))
            StatCard(
                if (output != null) formatBytes(output.length()).replace(" ", "\n") else "—",
                "size",
                Modifier.weight(1f),
            )
        }

        AmberNote(
            "Signed with a new signature. The original signature is lost — " +
                "apps with signature verification won't run.",
        )
        Spacer(Modifier.height(16.dp))

        PrimaryButton(
            text = "Install",
            icon = Icons.Filled.Download,
            onClick = { output?.let { installApk(context, it) } },
            enabled = output != null,
            modifier = Modifier.padding(bottom = 12.dp),
        )
        Row(
            modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlineButton(
                text = "Share",
                icon = Icons.Filled.Share,
                onClick = { output?.let { shareApk(context, it) } },
                modifier = Modifier.weight(1f),
            )
            OutlineButton(
                text = "View File",
                onClick = { showPath = true },
                modifier = Modifier.weight(1f),
            )
        }
        TextButton(
            onClick = vm::goHome,
            modifier = Modifier.align(Alignment.CenterHorizontally),
        ) {
            Text("Patch another", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = c.primary)
        }
        Spacer(Modifier.height(24.dp))
    }

    if (showPath && output != null) {
        AlertDialog(
            onDismissRequest = { showPath = false },
            title = { Text("Saved file", fontWeight = FontWeight.Bold) },
            text = { Text(output.absolutePath, fontSize = 13.sp) },
            confirmButton = {
                TextButton(onClick = {
                    val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    cm.setPrimaryClip(ClipData.newPlainText("path", output.absolutePath))
                    showPath = false
                }) { Text("Copy path") }
            },
            dismissButton = {
                TextButton(onClick = { showPath = false }) { Text("Close") }
            },
        )
    }
}

@Composable
private fun StatCard(value: String, label: String, modifier: Modifier = Modifier) {
    val c = LocalApkLabColors.current
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(c.card)
            .padding(vertical = 14.dp, horizontal = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(value, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = c.primary, textAlign = TextAlign.Center, lineHeight = 24.sp)
        Spacer(Modifier.height(3.dp))
        Text(label, fontSize = 11.sp, color = c.muted, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center, lineHeight = 15.sp)
    }
}

private fun apkUri(context: Context, file: File) =
    FileProvider.getUriForFile(context, "com.apklab.app.fileprovider", file)

fun installApk(context: Context, file: File) {
    val intent = Intent(Intent.ACTION_VIEW).apply {
        setDataAndType(apkUri(context, file), "application/vnd.android.package-archive")
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    context.startActivity(intent)
}

fun shareApk(context: Context, file: File) {
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "application/vnd.android.package-archive"
        putExtra(Intent.EXTRA_STREAM, apkUri(context, file))
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(Intent.createChooser(intent, "Share APK"))
}
