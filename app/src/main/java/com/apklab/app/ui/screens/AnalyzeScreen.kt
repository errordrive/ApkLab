package com.apklab.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apklab.app.AppViewModel
import com.apklab.app.UiState
import com.apklab.app.formatBytes
import com.apklab.app.prettyClass
import com.apklab.app.ui.components.AmberNote
import com.apklab.app.ui.components.ApkLabTopBar
import com.apklab.app.ui.components.AppCard
import com.apklab.app.ui.components.PrimaryButton
import com.apklab.app.ui.components.SectionTitle
import com.apklab.app.ui.components.StatusPill
import com.apklab.app.ui.theme.LocalApkLabColors
import com.apklab.engine.Badge

@Composable
fun AnalyzeScreen(vm: AppViewModel, state: UiState) {
    val c = LocalApkLabColors.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(c.paper)
            .padding(horizontal = 20.dp)
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.height(8.dp))
        ApkLabTopBar(
            title = "Scan Results",
            onBack = { vm.goBackFrom(com.apklab.app.ui.Screen.Analyze) },
            darkMode = state.darkMode,
            onToggleDark = vm::toggleDark,
        )

        when {
            state.scanning -> {
                AppCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(color = c.primary, modifier = Modifier.size(28.dp), strokeWidth = 3.dp)
                        Spacer(Modifier.width(16.dp))
                        Column {
                            Text("Scanning APK…", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = c.ink)
                            Text("Looking for injected dialog code", fontSize = 13.sp, color = c.muted)
                        }
                    }
                }
                if (state.scanLog.isNotEmpty()) {
                    Spacer(Modifier.height(4.dp))
                    AppCard {
                        state.scanLog.takeLast(8).forEach {
                            Text(it, fontSize = 12.sp, color = c.muted, modifier = Modifier.padding(bottom = 4.dp))
                        }
                    }
                }
            }
            state.scanError != null -> {
                AppCard {
                    Text("Scan failed", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = c.danger)
                    Spacer(Modifier.height(6.dp))
                    Text(state.scanError, fontSize = 13.sp, color = c.muted, lineHeight = 19.sp)
                }
                Spacer(Modifier.height(12.dp))
                PrimaryButton(text = "Retry", onClick = vm::retryScan)
            }
            else -> {
                val result = state.scanResult
                if (result == null) {
                    AppCard {
                        Text("No scan data.", fontSize = 14.sp, color = c.muted)
                    }
                } else {
                    val info = result.apkInfo
                    // APK info card
                    AppCard {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(52.dp)
                                    .clip(RoundedCornerShape(14.dp))
                                    .background(c.purple),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(
                                    (info.packageName?.firstOrNull() ?: info.fileName.firstOrNull() ?: '?')
                                        .uppercaseChar().toString(),
                                    fontSize = 24.sp, fontWeight = FontWeight.Bold,
                                    color = androidx.compose.ui.graphics.Color.White,
                                )
                            }
                            Spacer(Modifier.width(14.dp))
                            Column {
                                Text(
                                    info.packageName ?: info.fileName,
                                    fontSize = 16.sp, fontWeight = FontWeight.Bold, color = c.ink,
                                )
                                Text(
                                    info.versionName?.let { "v$it" } ?: "unknown version",
                                    fontSize = 12.sp, color = c.muted,
                                )
                            }
                        }
                    }
                    // meta pills
                    Row(modifier = Modifier.padding(bottom = 14.dp)) {
                        MetaPill(formatBytes(info.sizeBytes))
                        Spacer(Modifier.width(8.dp))
                        MetaPill("${info.dexCount} dex files")
                        Spacer(Modifier.width(8.dp))
                        MetaPill(if (info.sigSchemes.isEmpty()) "unsigned" else info.sigSchemes.joinToString("+"))
                    }

                    if (result.detections.isEmpty()) {
                        AppCard {
                            Text(
                                "No suspicious dialog code found.",
                                fontSize = 15.sp, fontWeight = FontWeight.Bold, color = c.ink,
                            )
                            Spacer(Modifier.height(6.dp))
                            Text(
                                "This APK shows no injected remote-controlled dialog patterns. " +
                                    "Nothing to patch.",
                                fontSize = 13.sp, color = c.muted, lineHeight = 19.sp,
                            )
                        }
                    } else {
                        SectionTitle("Suspicious classes (${result.detections.size})")
                        result.detections.forEach { d ->
                            val checked = d.classType in state.selected
                            AppCard(
                                modifier = Modifier
                                    .padding(bottom = 12.dp)
                                    .clickable { vm.toggleDetection(d.classType) },
                            ) {
                                Row(verticalAlignment = Alignment.Top) {
                                    Checkbox(
                                        checked = checked,
                                        onCheckedChange = { vm.toggleDetection(d.classType) },
                                        colors = CheckboxDefaults.colors(
                                            checkedColor = c.primary,
                                            uncheckedColor = c.faint,
                                            checkmarkColor = androidx.compose.ui.graphics.Color.White,
                                        ),
                                        modifier = Modifier.size(26.dp),
                                    )
                                    Spacer(Modifier.width(12.dp))
                                    Column(Modifier.weight(1f)) {
                                        Text(
                                            prettyClass(d.classType),
                                            fontSize = 12.sp, fontWeight = FontWeight.Bold,
                                            color = c.ink, fontFamily = FontFamily.Monospace,
                                            lineHeight = 17.sp,
                                        )
                                        Row(modifier = Modifier.padding(top = 8.dp)) {
                                            if (Badge.DIALOG in d.badges) {
                                                StatusPill("DIALOG", c.primarySoft, c.primary)
                                                Spacer(Modifier.width(7.dp))
                                            }
                                            if (Badge.REMOTE in d.badges) {
                                                StatusPill("REMOTE", c.amberSoft, c.amber)
                                                Spacer(Modifier.width(7.dp))
                                            }
                                            if (Badge.STARTUP in d.badges) {
                                                StatusPill("STARTUP", c.purpleSoft, c.purple)
                                            }
                                        }
                                        Text(
                                            if (d.methodsToGut.isNotEmpty())
                                                "${d.methodsToGut.size} methods • ${d.totalNops} hook calls"
                                            else
                                                "${d.totalNops} startup call(s) silenced",
                                            fontSize = 12.sp, color = c.muted,
                                            modifier = Modifier.padding(top = 8.dp),
                                        )
                                    }
                                }
                            }
                        }
                        AmberNote(
                            "Only checked classes will be patched. Uncheck if you are not sure.",
                        )
                        Spacer(Modifier.height(14.dp))
                        PrimaryButton(
                            text = "Generate Report",
                            onClick = vm::generateReport,
                            enabled = state.selected.isNotEmpty(),
                        )
                    }
                }
            }
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun MetaPill(text: String) {
    val c = LocalApkLabColors.current
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(c.card)
            .padding(horizontal = 13.dp, vertical = 6.dp),
    ) {
        Text(text, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = c.inkSoft)
    }
}
