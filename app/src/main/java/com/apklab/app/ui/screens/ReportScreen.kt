package com.apklab.app.ui.screens

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apklab.app.AppViewModel
import com.apklab.app.UiState
import com.apklab.app.formatBytes
import com.apklab.app.formatTime
import com.apklab.app.prettyClass
import com.apklab.app.ui.Screen
import com.apklab.app.ui.components.ApkLabTopBar
import com.apklab.app.ui.components.AppCard
import com.apklab.app.ui.components.OutlineButton
import com.apklab.app.ui.components.PrimaryButton
import com.apklab.app.ui.components.SectionTitle
import com.apklab.app.ui.components.StatusPill
import com.apklab.app.ui.theme.LocalApkLabColors
import com.apklab.engine.Badge

@Composable
fun ReportScreen(vm: AppViewModel, state: UiState) {
    val c = LocalApkLabColors.current
    val context = LocalContext.current
    val report = state.report

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(c.paper)
            .padding(horizontal = 20.dp)
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.height(8.dp))
        ApkLabTopBar(
            title = "Patch Report",
            onBack = { vm.goBackFrom(Screen.Report) },
            darkMode = state.darkMode,
            onToggleDark = vm::toggleDark,
        )

        if (report == null) {
            AppCard { Text("No report generated.", fontSize = 14.sp, color = c.muted) }
        } else {
            val info = report.apkInfo
            // header card
            AppCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(46.dp)
                            .clip(RoundedCornerShape(14.dp))
                            .background(c.primarySoft),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Description, null, tint = c.primary, modifier = Modifier.size(22.dp))
                    }
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(state.pickedName.ifBlank { info.fileName }, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = c.ink)
                        Text(
                            "Generated ${formatTime(report.generatedAt)}",
                            fontSize = 11.sp, color = c.muted, modifier = Modifier.padding(top = 3.dp),
                        )
                    }
                }
            }

            SectionTitle("APK Information")
            AppCard {
                InfoRow("Package", info.packageName ?: "unknown")
                InfoRow("Version", info.versionName?.let { "v$it (${info.versionCode})" } ?: "unknown")
                InfoRow("Size", formatBytes(info.sizeBytes))
                InfoRow("DEX files", info.dexCount.toString())
                InfoRow("Signature", if (info.sigSchemes.isEmpty()) "unsigned" else info.sigSchemes.joinToString(" + "), last = true)
            }

            SectionTitle("Findings (${report.detections.size})")
            report.detections.forEach { d ->
                AppCard(modifier = Modifier.padding(bottom = 12.dp)) {
                    CodeLine(prettyClass(d.classType), bold = true)
                    Row(modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)) {
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
                    if (d.methodsToGut.isNotEmpty()) {
                        Text("Methods to gut", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = c.inkSoft, modifier = Modifier.padding(top = 8.dp, bottom = 6.dp))
                        d.methodsToGut.forEach { m ->
                            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(bottom = 6.dp)) {
                                Box(Modifier.size(8.dp).clip(RoundedCornerShape(999.dp)).background(c.danger))
                                Spacer(Modifier.width(10.dp))
                                CodeLine("${m.name}(${m.descriptor.substringAfter('(')}")
                            }
                        }
                    }
                    Text("Hook calls to nop", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = c.inkSoft, modifier = Modifier.padding(top = 6.dp, bottom = 6.dp))
                    if (d.hookSites.isEmpty() && d.scopedNops.isEmpty()) {
                        Text("None", fontSize = 12.sp, color = c.muted)
                    } else {
                        d.hookSites.forEach { h ->
                            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(bottom = 6.dp)) {
                                Box(Modifier.size(8.dp).clip(RoundedCornerShape(999.dp)).background(c.amber))
                                Spacer(Modifier.width(10.dp))
                                CodeLine("${prettyClass(h.callerClass).substringAfterLast('.')}.${h.callerMethod} → ${h.target.name}()")
                            }
                        }
                        d.scopedNops.forEach { s ->
                            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(bottom = 6.dp)) {
                                Box(Modifier.size(8.dp).clip(RoundedCornerShape(999.dp)).background(c.purple))
                                Spacer(Modifier.width(10.dp))
                                CodeLine("${prettyClass(s.callerClass).substringAfterLast('.')}.${s.callerMethod} → ${s.targetMethod}() [startup]")
                            }
                        }
                    }
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlineButton(
                    text = "Share",
                    icon = Icons.Filled.Share,
                    onClick = {
                        vm.reportText()?.let { text ->
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_SUBJECT, "ApkLab patch report")
                                putExtra(Intent.EXTRA_TEXT, text)
                            }
                            context.startActivity(Intent.createChooser(intent, "Share report"))
                        }
                    },
                    modifier = Modifier.weight(1f),
                )
                OutlineButton(
                    text = "Save .txt",
                    icon = Icons.Filled.Download,
                    onClick = { vm.saveReport() },
                    modifier = Modifier.weight(1f),
                )
            }

            PrimaryButton(text = "Patch Now", onClick = vm::startPatch)
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun InfoRow(label: String, value: String, last: Boolean = false) {
    val c = LocalApkLabColors.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, fontSize = 13.sp, color = c.muted, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
        Text(value, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = c.ink)
    }
    if (!last) Divider(color = c.line, thickness = 1.dp)
}

/**
 * Single-line monospace code text that scrolls horizontally instead of
 * wrapping mid-token (long JNI-style signatures stay readable).
 */
@Composable
private fun CodeLine(text: String, bold: Boolean = false) {
    val c = LocalApkLabColors.current
    Text(
        text,
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        fontSize = 11.5.sp,
        fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
        color = c.ink,
        fontFamily = FontFamily.Monospace,
        lineHeight = 17.sp,
        softWrap = false,
        maxLines = 1,
    )
}
