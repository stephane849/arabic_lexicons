package io.github.stephane849.arabic_lexicons_kompakt.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * Placeholder E Ink theme, standing in for the real `com.mudita:mmd`
 * component library (not publicly available — see PORTING.md). Grayscale
 * only, flat pressed-state fill instead of ripple, no motion. Swap this
 * file (and the `LocalIndication.current` override below) for the real MMD
 * theme/components once `useMuditaMmd` wiring is available.
 */
object EInk {
    val black = Color(0xFF000000)
    val ink90 = Color(0xFF1A1A1A)
    val ink70 = Color(0xFF474747)
    val ink40 = Color(0xFF8C8C8C)
    val ink20 = Color(0xFFC6C6C6)
    val ink10 = Color(0xFFE3E3E3)
    val paper = Color(0xFFFFFFFF)
    val highlight = Color(0xFFD8D8D8)
}

private val einkColorScheme = lightColorScheme(
    primary = EInk.black,
    onPrimary = EInk.paper,
    secondary = EInk.ink70,
    onSecondary = EInk.paper,
    background = EInk.paper,
    onBackground = EInk.black,
    surface = EInk.paper,
    onSurface = EInk.black,
    surfaceVariant = EInk.ink10,
    onSurfaceVariant = EInk.ink90,
    outline = EInk.ink40,
    error = EInk.black,
    onError = EInk.paper,
)

private val einkTypography = Typography(
    bodyLarge = TextStyle(fontSize = 17.sp, fontWeight = FontWeight.Normal, color = EInk.black),
    titleLarge = TextStyle(fontSize = 22.sp, fontWeight = FontWeight.Bold, color = EInk.black),
    titleMedium = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.SemiBold, color = EInk.black),
    labelLarge = TextStyle(fontSize = 15.sp, fontWeight = FontWeight.Medium, color = EInk.black),
)

@Composable
fun KompaktTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = einkColorScheme,
        typography = einkTypography,
        content = content,
    )
}
