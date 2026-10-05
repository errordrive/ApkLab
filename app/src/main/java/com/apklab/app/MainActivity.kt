package com.apklab.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toArgb
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.apklab.app.ui.Screen
import com.apklab.app.ui.screens.AnalyzeScreen
import com.apklab.app.ui.screens.HomeScreen
import com.apklab.app.ui.screens.PatchScreen
import com.apklab.app.ui.screens.PermissionGateScreen
import com.apklab.app.ui.screens.ReportScreen
import com.apklab.app.ui.screens.ResultScreen
import com.apklab.app.ui.theme.ApkLabTheme
import com.apklab.app.ui.theme.LocalApkLabColors

class MainActivity : ComponentActivity() {

    private val vm: AppViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Re-check permission when returning from Settings.
        lifecycle.addObserver(LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) vm.onResumeCheck()
        })

        setContent {
            val state by vm.state.collectAsState()
            val snackbar = remember { SnackbarHostState() }

            LaunchedEffect(state.infoMessage) {
                state.infoMessage?.let {
                    snackbar.showSnackbar(it)
                    vm.clearInfo()
                }
            }

            ApkLabTheme(darkTheme = state.darkMode) {
                val c = LocalApkLabColors.current
                // Status bar matches the paper background, like the mockups.
                val dark = state.darkMode
                LaunchedEffect(dark) {
                    window.statusBarColor = c.paper.toArgb()
                    WindowInsetsControllerCompat(window, window.decorView)
                        .isAppearanceLightStatusBars = !dark
                }

                Scaffold(
                    snackbarHost = { SnackbarHost(snackbar) },
                    containerColor = c.paper,
                ) { padding ->
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(padding),
                    ) {
                        when (state.screen) {
                            Screen.PermissionGate -> PermissionGateScreen(vm, state.permissionDenied)
                            Screen.Home -> HomeScreen(vm, state)
                            Screen.Analyze -> AnalyzeScreen(vm, state)
                            Screen.Report -> ReportScreen(vm, state)
                            Screen.Patch -> PatchScreen(vm, state)
                            Screen.Result -> ResultScreen(vm, state)
                        }
                    }
                }
            }
        }
    }
}
