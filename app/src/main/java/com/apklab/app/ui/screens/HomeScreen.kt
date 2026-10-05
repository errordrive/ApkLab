package com.apklab.app.ui.screens

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.FolderOpen
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apklab.app.AppViewModel
import com.apklab.app.UiState
import com.apklab.app.formatBytes
import com.apklab.app.formatTime
import com.apklab.app.ui.components.AppCard
import com.apklab.app.ui.components.PrimaryButton
import com.apklab.app.ui.components.SectionTitle
import com.apklab.app.ui.components.StatusPill
import com.apklab.app.ui.components.StepNumber
import com.apklab.app.ui.theme.LocalApkLabColors
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(vm: AppViewModel, state: UiState) {
    val c = LocalApkLabColors.current
    var showPicker by remember { mutableStateOf(false) }

    val safLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        if (uri != null) {
            showPicker = false
            vm.importSafApk(uri)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(c.paper)
            .padding(horizontal = 20.dp)
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.height(8.dp))
        // Brand header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(46.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(c.primary),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Shield, null, tint = androidx.compose.ui.graphics.Color.White, modifier = Modifier.size(24.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text("ApkLab", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = c.ink)
                Text("APK Dialog Stripper", fontSize = 12.sp, color = c.muted)
            }
            Box(
                modifier = Modifier
                    .size(38.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(c.card)
                    .clickable(onClick = vm::toggleDark),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    if (state.darkMode) Icons.Filled.LightMode
                    else Icons.Filled.DarkMode,
                    "Toggle theme", tint = c.inkSoft, modifier = Modifier.size(18.dp),
                )
            }
        }

        // Hero card
        AppCard {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(c.primarySoft),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Shield, null, tint = c.primary, modifier = Modifier.size(28.dp))
            }
            Spacer(Modifier.height(14.dp))
            Text("Remove Injected Dialogs", fontSize = 19.sp, fontWeight = FontWeight.Bold, color = c.ink)
            Spacer(Modifier.height(6.dp))
            Text(
                "Select APK → auto scan → patch → sign.\nEverything on-device, no root needed.",
                fontSize = 13.sp, color = c.muted, lineHeight = 20.sp,
            )
        }

        PrimaryButton(
            text = "Select APK",
            icon = Icons.Filled.Description,
            onClick = { showPicker = true },
            modifier = Modifier.padding(bottom = 16.dp),
        )

        // How it works
        AppCard {
            Text("How it works", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = c.ink, modifier = Modifier.padding(bottom = 12.dp))
            StepNumber("1", "Read APK & load dex")
            StepNumber("2", "Find dialog classes")
            StepNumber("3", "Patch methods")
            // last row without bottom padding handled inside StepNumber; fine
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(30.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(c.primarySoft),
                    contentAlignment = Alignment.Center,
                ) {
                    Text("4", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = c.primary)
                }
                Spacer(Modifier.width(12.dp))
                Text("Repack + sign", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = c.inkSoft)
            }
        }

        // Recent
        if (state.recent.isNotEmpty()) {
            SectionTitle("Recent")
            AppCard {
                state.recent.reversed().forEachIndexed { i, r ->
                    if (i > 0) Spacer(Modifier.height(12.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(c.purpleSoft),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.Description, null, tint = c.purple, modifier = Modifier.size(22.dp))
                        }
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(r.name, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = c.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            Text(
                                "${r.methods + r.hooks} items removed • ${formatTime(r.ts)}",
                                fontSize = 12.sp, color = c.muted,
                            )
                        }
                        StatusPill("Success", c.successSoft, c.success)
                    }
                }
            }
        }
        Spacer(Modifier.height(24.dp))
    }

    if (showPicker) {
        ModalBottomSheet(
            onDismissRequest = { showPicker = false },
            sheetState = rememberModalBottomSheetState(),
            containerColor = c.card,
        ) {
            Column(Modifier.padding(horizontal = 20.dp).padding(bottom = 28.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Choose APK", fontSize = 17.sp, fontWeight = FontWeight.Bold, color = c.ink, modifier = Modifier.weight(1f))
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(RoundedCornerShape(999.dp))
                            .background(c.paper)
                            .clickable { vm.refreshApkChoices() },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Refresh, "Refresh", tint = c.inkSoft, modifier = Modifier.size(18.dp))
                    }
                }
                // Browse files row
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(c.primarySoft)
                        .clickable { safLauncher.launch(arrayOf("application/vnd.android.package-archive")) }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.FolderOpen, null, tint = c.primary, modifier = Modifier.size(22.dp))
                    Spacer(Modifier.width(12.dp))
                    Text("Browse files…", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = c.primary)
                }
                Spacer(Modifier.height(10.dp))
                Text("From Downloads", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = c.muted, modifier = Modifier.padding(vertical = 6.dp))
                LazyColumn(
                    modifier = Modifier.height(320.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    items(state.apkChoices, key = { it.absolutePath }) { f ->
                        ApkRow(f) {
                            showPicker = false
                            vm.pickLocalApk(f)
                        }
                    }
                    if (state.apkChoices.isEmpty()) {
                        item {
                            Text(
                                "No APK files found in Downloads.",
                                fontSize = 13.sp, color = c.muted,
                                modifier = Modifier.padding(vertical = 16.dp),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ApkRow(f: File, onClick: () -> Unit) {
    val c = LocalApkLabColors.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(c.paper)
            .clickable(onClick = onClick)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(42.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(c.purpleSoft),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Description, null, tint = c.purple, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(f.name, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = c.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(formatBytes(f.length()), fontSize = 12.sp, color = c.muted)
        }
    }
}
