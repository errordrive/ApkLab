package com.apklab.app.ui

/** Manual navigation — the ViewModel owns the current screen. */
sealed interface Screen {
    data object PermissionGate : Screen
    data object Home : Screen
    data object Analyze : Screen
    data object Report : Screen
    data object Patch : Screen
    data object Result : Screen
}
