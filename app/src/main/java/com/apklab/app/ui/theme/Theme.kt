package com.apklab.app.ui.theme

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.graphics.Color

@Immutable
data class ApkLabColors(
    val paper: Color,
    val card: Color,
    val ink: Color,
    val inkSoft: Color,
    val muted: Color,
    val faint: Color,
    val line: Color,
    val primary: Color,
    val primarySoft: Color,
    val success: Color,
    val successSoft: Color,
    val danger: Color,
    val dangerSoft: Color,
    val amber: Color,
    val amberSoft: Color,
    val purple: Color,
    val purpleSoft: Color,
    val dark: Boolean,
)

fun lightApkLabColors() = ApkLabColors(
    paper = PaperLight, card = CardLight, ink = InkLight, inkSoft = InkSoftLight,
    muted = MutedLight, faint = FaintLight, line = LineLight,
    primary = PrimaryLight, primarySoft = PrimarySoftLight,
    success = SuccessLight, successSoft = SuccessSoftLight,
    danger = DangerLight, dangerSoft = DangerSoftLight,
    amber = AmberLight, amberSoft = AmberSoftLight,
    purple = PurpleLight, purpleSoft = PurpleSoftLight,
    dark = false,
)

fun darkApkLabColors() = ApkLabColors(
    paper = PaperDark, card = CardDark, ink = InkDark, inkSoft = InkSoftDark,
    muted = MutedDark, faint = FaintDark, line = LineDark,
    primary = PrimaryDark, primarySoft = PrimarySoftDark,
    success = SuccessDark, successSoft = SuccessSoftDark,
    danger = DangerDark, dangerSoft = DangerSoftDark,
    amber = AmberDark, amberSoft = AmberSoftDark,
    purple = PurpleDark, purpleSoft = PurpleSoftDark,
    dark = true,
)

val LocalApkLabColors = staticCompositionLocalOf { lightApkLabColors() }

private val LightScheme = lightColorScheme(
    primary = PrimaryLight,
    onPrimary = Color.White,
    primaryContainer = PrimarySoftLight,
    onPrimaryContainer = PrimaryLight,
    background = PaperLight,
    onBackground = InkLight,
    surface = CardLight,
    onSurface = InkLight,
    surfaceVariant = LineLight,
    onSurfaceVariant = InkSoftLight,
    error = DangerLight,
    onError = Color.White,
)

private val DarkScheme = darkColorScheme(
    primary = PrimaryDark,
    onPrimary = Color.White,
    primaryContainer = PrimarySoftDark,
    onPrimaryContainer = PrimaryDark,
    background = PaperDark,
    onBackground = InkDark,
    surface = CardDark,
    onSurface = InkDark,
    surfaceVariant = LineDark,
    onSurfaceVariant = InkSoftDark,
    error = DangerDark,
    onError = Color.White,
)

@Composable
fun ApkLabTheme(
    darkTheme: Boolean,
    content: @Composable () -> Unit,
) {
    val colors = if (darkTheme) darkApkLabColors() else lightApkLabColors()
    CompositionLocalProvider(LocalApkLabColors provides colors) {
        MaterialTheme(
            colorScheme = if (darkTheme) DarkScheme else LightScheme,
            content = content,
        )
    }
}
