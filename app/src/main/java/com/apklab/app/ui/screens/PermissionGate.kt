package com.apklab.app.ui.screens

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apklab.app.AppViewModel
import com.apklab.app.ui.components.PrimaryButton
import com.apklab.app.ui.theme.LocalApkLabColors

@Composable
fun PermissionGateScreen(vm: AppViewModel, permissionDenied: Boolean) {
    val c = LocalApkLabColors.current
    val context = LocalContext.current

    val legacyLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { grants ->
        vm.onPermissionResult(grants.values.all { it })
    }
    val settingsLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        vm.onPermissionResult(vm.hasStoragePermission())
    }

    fun request() {
        if (Build.VERSION.SDK_INT >= 30) {
            val intent = Intent(
                Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:${context.packageName}"),
            )
            settingsLauncher.launch(intent)
        } else {
            legacyLauncher.launch(
                arrayOf(
                    android.Manifest.permission.READ_EXTERNAL_STORAGE,
                    android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
                )
            )
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(c.paper)
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .size(88.dp)
                .clip(RoundedCornerShape(24.dp))
                .background(c.primarySoft),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Shield, null, tint = c.primary, modifier = Modifier.size(44.dp))
        }
        Spacer(Modifier.height(24.dp))
        Text(
            "Storage access required",
            fontSize = 22.sp, fontWeight = FontWeight.Bold, color = c.ink,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(12.dp))
        Text(
            "ApkLab reads APK files and saves patched output to the " +
                "ApkLab folder on your storage. This permission is required to continue.",
            fontSize = 14.sp, color = c.muted, textAlign = TextAlign.Center,
            lineHeight = 21.sp,
        )
        Spacer(Modifier.height(28.dp))
        PrimaryButton(text = "Grant Access", onClick = ::request)
        if (permissionDenied) {
            Spacer(Modifier.height(16.dp))
            Text(
                "Permission was denied. ApkLab cannot work without it. " +
                    "Please open Settings, find ApkLab, and enable " +
                    if (Build.VERSION.SDK_INT >= 30) "'Allow all files access'."
                    else "'Storage' permission.",
                fontSize = 13.sp, color = c.amber, textAlign = TextAlign.Center,
                lineHeight = 19.sp,
            )
        }
    }
}
