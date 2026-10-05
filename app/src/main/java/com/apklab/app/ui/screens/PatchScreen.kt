package com.apklab.app.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apklab.app.AppViewModel
import com.apklab.app.UiState
import com.apklab.app.ui.Screen
import com.apklab.app.ui.components.AmberNote
import com.apklab.app.ui.components.ApkLabTopBar
import com.apklab.app.ui.components.AppCard
import com.apklab.app.ui.components.PrimaryButton
import com.apklab.app.ui.theme.LocalApkLabColors

private val STEPS = listOf("Read", "Scan", "Patch", "Repack", "Sign")
private val STEP_SUBS = listOf(
    "Loading APK & dex files",
    "Detecting dialog code",
    "Gutting methods & nopping hooks",
    "Repacking APK",
    "Aligning & signing",
)

@Composable
fun PatchScreen(vm: AppViewModel, state: UiState) {
    val c = LocalApkLabColors.current
    val step = vm.patchStepIndex()
    val pct = ((step + 1) * 100) / STEPS.size

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(c.paper)
            .padding(horizontal = 20.dp)
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.height(8.dp))
        ApkLabTopBar(
            title = "Patching",
            onBack = if (state.patching) null else ({ vm.goBackFrom(Screen.Patch) }),
            darkMode = state.darkMode,
            onToggleDark = vm::toggleDark,
        )

        if (state.patchError != null) {
            AppCard {
                Text("Patch failed", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = c.danger)
                Spacer(Modifier.height(6.dp))
                Text(state.patchError, fontSize = 13.sp, color = c.muted, lineHeight = 19.sp)
            }
            Spacer(Modifier.height(12.dp))
            PrimaryButton(text = "Back to Report", onClick = { vm.goBackFrom(Screen.Report) })
        } else {
            // progress card
            AppCard {
                Text("$pct%", fontSize = 34.sp, fontWeight = FontWeight.Bold, color = c.primary)
                Spacer(Modifier.height(10.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(10.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(c.line),
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth((step + 1) / STEPS.size.toFloat())
                            .height(10.dp)
                            .clip(RoundedCornerShape(999.dp))
                            .background(c.primary),
                    )
                }
                Spacer(Modifier.height(10.dp))
                Text(
                    if (state.patching) "${STEP_SUBS[step]}…" else "Finishing…",
                    fontSize = 13.sp, color = c.muted, fontWeight = FontWeight.SemiBold,
                )
            }

            // steps card
            AppCard {
                STEPS.forEachIndexed { i, label ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(bottom = if (i < STEPS.size - 1) 14.dp else 0.dp),
                    ) {
                        when {
                            i < step -> StepIconDone(c.successSoft, c.success)
                            i == step && state.patching -> StepIconActive()
                            i == step -> StepIconDone(c.successSoft, c.success)
                            else -> StepIconPending()
                        }
                        Spacer(Modifier.width(12.dp))
                        Column {
                            Text(
                                label, fontSize = 14.sp, fontWeight = FontWeight.Bold,
                                color = if (i <= step) c.ink else c.faint,
                            )
                            Text(
                                STEP_SUBS[i], fontSize = 12.sp,
                                color = if (i <= step) c.muted else c.faint,
                            )
                        }
                    }
                }
            }

            // log card (dark)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFF0F1B2D))
                    .padding(16.dp),
            ) {
                Column {
                    Text(
                        "LOG", fontSize = 12.sp, fontWeight = FontWeight.Bold,
                        color = Color(0xFF8B9BB8), modifier = Modifier.padding(bottom = 10.dp),
                    )
                    if (state.patchLog.isEmpty()) {
                        Text("Starting…", fontSize = 11.sp, fontFamily = FontFamily.Monospace, color = Color(0xFFC3D0E6))
                    } else {
                        state.patchLog.takeLast(12).forEach {
                            Text(
                                it, fontSize = 11.sp, fontFamily = FontFamily.Monospace,
                                color = Color(0xFFC3D0E6), lineHeight = 17.sp,
                                modifier = Modifier.padding(bottom = 2.dp),
                            )
                        }
                    }
                    if (state.patching) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(top = 8.dp),
                        ) {
                            CircularProgressIndicator(
                                color = Color(0xFF4D8DFF),
                                modifier = Modifier.size(14.dp), strokeWidth = 2.dp,
                            )
                            Spacer(Modifier.width(8.dp))
                            Text("Working…", fontSize = 11.sp, color = Color(0xFF8B9BB8))
                        }
                    }
                }
            }

            if (!state.patchLog.isEmpty()) {
                Spacer(Modifier.height(12.dp))
                AmberNote("Do not close the app while patching is in progress.")
            }
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun StepIconDone(bg: Color, fg: Color) {
    Box(
        modifier = Modifier
            .size(30.dp)
            .clip(RoundedCornerShape(999.dp))
            .background(bg),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Filled.Check, null, tint = fg, modifier = Modifier.size(14.dp))
    }
}

@Composable
private fun StepIconActive() {
    val c = LocalApkLabColors.current
    Box(
        modifier = Modifier
            .size(30.dp)
            .clip(RoundedCornerShape(999.dp))
            .background(c.primarySoft),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .clip(RoundedCornerShape(999.dp))
                .background(c.primary),
        )
    }
}

@Composable
private fun StepIconPending() {
    val c = LocalApkLabColors.current
    Box(
        modifier = Modifier
            .size(30.dp)
            .clip(RoundedCornerShape(999.dp))
            .background(c.paper),
    )
}
