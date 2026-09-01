package io.github.stephane849.arabic_lexicons_kompakt.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.sp
import com.mudita.mmd.ThemeMMD
import com.mudita.mmd.black
import com.mudita.mmd.white

/**
 * The app runs on Mudita Mindful Design's own E Ink theme. `ThemeMMD`
 * carries MMD's black-on-white color scheme (no grays, no gradients — a
 * gray fill on E Ink dithers into noise rather than reading as a tint) and
 * disables Compose's ripple globally, since an animated ripple ghosts.
 *
 * Emphasis therefore comes from weight, borders and inversion, never from
 * color; that constraint runs through every screen in this app.
 */
@Composable
fun KompaktTheme(content: @Composable () -> Unit) = ThemeMMD(content = content)

/** The only two values on an E Ink panel. */
object EInk {
    val ink = black
    val paper = white
}

/**
 * MMD's typography is Lato, which carries no Arabic glyphs. Lexicon
 * content is overwhelmingly Arabic, so it renders in the platform's own
 * Arabic face instead of leaning on per-glyph fallback.
 *
 * The size is the reader's own choice (see Settings); line height tracks
 * it, because vocalized Arabic needs the leading to stay proportional or
 * the harakat collide on a low-DPI E Ink panel.
 */
fun arabicBody(fontSize: Int) = TextStyle(
    fontFamily = FontFamily.Default,
    fontSize = fontSize.sp,
    lineHeight = (fontSize * 1.75f).sp,
)

/** The same face at a fixed size, for chrome: chips, titles, labels. */
val arabicLabel = TextStyle(
    fontFamily = FontFamily.Default,
    fontSize = 17.sp,
    lineHeight = 24.sp,
)
