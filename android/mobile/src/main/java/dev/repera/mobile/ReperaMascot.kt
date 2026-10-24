package dev.repera.mobile

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.heightIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Poses de la mascota Repera (assets copiados 1:1 del catálogo iOS en main). */
enum class ReperaMascotPose(val assetPath: String) {
    WELCOME("mascot/mascot-welcome.png"),
    PERMISSIONS("mascot/mascot-permissions.png"),
    HERO("mascot/mascot-hero.png"),
    WATCH("mascot/mascot-watch.png")
}

/** Mascota Repera para onboarding y pantallas de producto. Port de ReperaMascot.swift. */
@Composable
fun ReperaMascot(pose: ReperaMascotPose, maxHeight: Dp = 220.dp, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val bitmap = remember(pose) {
        runCatching {
            context.assets.open(pose.assetPath).use { BitmapFactory.decodeStream(it) }
        }.getOrNull()?.asImageBitmap()
    }
    bitmap?.let {
        Image(
            bitmap = it,
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = modifier.heightIn(max = maxHeight)
        )
    }
}
