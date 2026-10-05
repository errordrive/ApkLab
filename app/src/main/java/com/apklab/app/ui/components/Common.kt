package com.apklab.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apklab.app.ui.theme.LocalApkLabColors

@Composable
fun ApkLabTopBar(
    title: String,
    onBack: (() -> Unit)?,
    darkMode: Boolean,
    onToggleDark: () -> Unit,
) {
    val c = LocalApkLabColors.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 18.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (onBack != null) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(c.card)
                    .border(1.dp, c.line, RoundedCornerShape(999.dp))
                    .clickable(onClick = onBack),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack, "Back",
                    tint = c.ink, modifier = Modifier.size(18.dp),
                )
            }
            Spacer(Modifier.width(12.dp))
        }
        Text(
            title, fontSize = 18.sp, fontWeight = FontWeight.Bold, color = c.ink,
            modifier = Modifier.weight(1f),
        )
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(999.dp))
                .background(c.card)
                .border(1.dp, c.line, RoundedCornerShape(999.dp))
                .clickable(onClick = onToggleDark),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                if (darkMode) Icons.Filled.LightMode else Icons.Filled.DarkMode,
                "Toggle theme", tint = c.inkSoft, modifier = Modifier.size(18.dp),
            )
        }
    }
}

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    icon: ImageVector? = null,
) {
    val c = LocalApkLabColors.current
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(58.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(if (enabled) c.primary else c.faint)
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (icon != null) {
                Icon(icon, null, tint = Color.White, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(10.dp))
            }
            Text(text, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun OutlineButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
) {
    val c = LocalApkLabColors.current
    Box(
        modifier = modifier
            .height(50.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(c.card)
            .border(1.5.dp, c.line, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (icon != null) {
                Icon(icon, null, tint = c.inkSoft, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(8.dp))
            }
            Text(text, color = c.inkSoft, fontSize = 14.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun SectionTitle(text: String) {
    val c = LocalApkLabColors.current
    Text(
        text, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = c.inkSoft,
        modifier = Modifier.padding(start = 4.dp, bottom = 10.dp, top = 4.dp),
    )
}

@Composable
fun StatusPill(text: String, bg: Color, fg: Color) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(bg)
            .padding(horizontal = 11.dp, vertical = 4.dp),
    ) {
        Text(text, fontSize = 10.sp, fontWeight = FontWeight.Bold, color = fg)
    }
}

@Composable
fun AppCard(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val c = LocalApkLabColors.current
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(c.card)
            .padding(18.dp),
    ) {
        Column { content() }
    }
}

@Composable
fun AmberNote(text: String) {
    val c = LocalApkLabColors.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(c.amberSoft)
            .padding(14.dp, 16.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Text(
            text, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
            color = c.amber, lineHeight = 20.sp,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
fun StepNumber(num: String, text: String) {
    val c = LocalApkLabColors.current
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(bottom = 12.dp),
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .clip(RoundedCornerShape(999.dp))
                .background(c.primarySoft),
            contentAlignment = Alignment.Center,
        ) {
            Text(num, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = c.primary)
        }
        Spacer(Modifier.width(12.dp))
        Text(text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = c.inkSoft)
    }
}
