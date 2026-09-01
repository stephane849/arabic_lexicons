package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import com.mudita.mmd.components.text.TextMMD
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.EInk

/**
 * Hand-written parser for the `meanings` HTML fragments DbService returns,
 * covering what's actually in the bundled data: `<b>`, `<i>`/`<em>`,
 * `<br>`, and the `<span class="high">` highlight DbService wraps around
 * substring matches. Doesn't handle tables, images, or links — the
 * original Flutter app used `flutter_html` for this; see PORTING.md for
 * why this port doesn't pull in a full HTML renderer.
 */
private sealed class Tok {
    data class Text(val text: String) : Tok()
    object Break : Tok()
    data class Open(val tag: String) : Tok()
    data class Close(val tag: String) : Tok()
}

private val TAG_RE = Regex("<(/?)(b|i|em|br|span(?:\\s+class=\"high\")?)\\s*/?>", RegexOption.IGNORE_CASE)

private fun tokenize(html: String): List<Tok> {
    val tokens = mutableListOf<Tok>()
    var last = 0
    for (m in TAG_RE.findAll(html)) {
        if (m.range.first > last) tokens.add(Tok.Text(html.substring(last, m.range.first)))
        val closing = m.groupValues[1] == "/"
        val rawTag = m.groupValues[2].lowercase()
        val tag = if (rawTag.startsWith("span")) "span" else rawTag
        when (tag) {
            "br" -> tokens.add(Tok.Break)
            else -> tokens.add(if (closing) Tok.Close(tag) else Tok.Open(tag))
        }
        last = m.range.last + 1
    }
    if (last < html.length) tokens.add(Tok.Text(html.substring(last)))
    return tokens
}

/**
 * @param style the reader's chosen content text style.
 * @param isLtr whether this lexicon's entries read left-to-right (the
 *   English ones). Arabic is flush right.
 * @param emphasized the row the query matched exactly. The original tints
 *   it; on E Ink that becomes weight, since a tint would only dither.
 */
@Composable
fun RichMeaning(
    html: String,
    style: TextStyle,
    modifier: Modifier = Modifier,
    isLtr: Boolean = false,
    emphasized: Boolean = false,
) {
    val annotated = buildAnnotatedString {
        val openStack = ArrayDeque<String>()
        for (tok in tokenize(html)) {
            when (tok) {
                is Tok.Text -> append(tok.text)
                is Tok.Break -> append('\n')
                is Tok.Open -> {
                    openStack.addLast(tok.tag)
                    val style = when (tok.tag) {
                        "b" -> SpanStyle(fontWeight = FontWeight.Bold)
                        "i", "em" -> SpanStyle(fontStyle = FontStyle.Italic)
                        // A search hit inverts to white-on-black. MMD has no
                        // grays to highlight with, and inversion is the one
                        // emphasis E Ink renders perfectly crisply.
                        "span" -> SpanStyle(background = EInk.ink, color = EInk.paper)
                        else -> SpanStyle()
                    }
                    pushStyle(style)
                }
                is Tok.Close -> {
                    if (openStack.isNotEmpty() && openStack.last() == tok.tag) {
                        openStack.removeLast()
                        pop()
                    }
                }
            }
        }
    }

    TextMMD(
        text = annotated,
        modifier = modifier,
        style = style,
        fontWeight = if (emphasized) FontWeight.Bold else null,
        // Explicitly Left/Right, never Start/End: Arabic renders inside an
        // RTL layout, where End would resolve to the *left* margin and
        // leave the text ragged down the wrong edge.
        textAlign = if (isLtr) TextAlign.Left else TextAlign.Right,
    )
}
