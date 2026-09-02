package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.ClickableText
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mudita.mmd.components.buttons.ButtonMMD
import com.mudita.mmd.components.buttons.OutlinedButtonMMD
import com.mudita.mmd.components.divider.HorizontalDividerMMD
import com.mudita.mmd.components.lazy.LazyColumnMMD
import com.mudita.mmd.components.progress_indicator.CircularProgressIndicatorMMD
import com.mudita.mmd.components.text.TextMMD
import com.mudita.mmd.components.text_field.TextFieldMMD
import com.mudita.mmd.components.top_app_bar.TopAppBarMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.data.LexiconRepository
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.RichMeaning
import io.github.stephane849.arabic_lexicons_kompakt.ui.nav.AppViewModel
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicBody
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.latinBody
import kotlinx.coroutines.launch

/** A word char for tap-boundary purposes: a Unicode letter, or a combining mark (Arabic harakat). */
private fun isWordChar(c: Char): Boolean =
    c.isLetter() || Character.getType(c) == Character.NON_SPACING_MARK.toInt()

private fun wordBoundsAt(text: String, offset: Int): IntRange {
    if (text.isEmpty()) return 0..0
    val idx = offset.coerceIn(0, text.length - 1)
    if (!isWordChar(text[idx])) return idx..idx
    var start = idx
    while (start > 0 && isWordChar(text[start - 1])) start--
    var end = idx
    while (end < text.length - 1 && isWordChar(text[end + 1])) end++
    return start..end
}

/**
 * Reader Mode's core interaction, ported per PORTING.md: paste text, tap
 * any word, see its meaning. Unlike the original (which persists a library
 * of named "books" on disk with per-book settings), this keeps a single
 * in-memory working buffer — paste, read, done, no saved library.
 */
// TopAppBarMMD wraps material3's TopAppBar, still an experimental API.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReaderScreen(
    viewModel: AppViewModel,
    text: String,
    onTextChange: (String) -> Unit,
    onBack: () -> Unit,
) {
    var lookup by remember { mutableStateOf<Pair<String, List<DbRow>>?>(null) }
    var loading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    // The pasted text is Arabic; the Hans Wehr lookup beneath it is English.
    val bodyStyle = arabicBody(viewModel.arabicFontSize)
    val lookupStyle = latinBody(viewModel.latinFontSize)
    val listState = rememberLazyListState()

    // Volume keys page the reader too — this is where paging matters most.
    LaunchedEffect(listState) {
        viewModel.pageScrolls.collect { direction ->
            val info = listState.layoutInfo
            val viewport = (info.viewportEndOffset - info.viewportStartOffset).toFloat()
            if (viewport > 0f) listState.scrollBy(direction * viewport * 0.9f)
        }
    }

    Column(modifier = Modifier.fillMaxSize().imePadding()) {
        TopAppBarMMD(
            title = { TextMMD("Reader Mode") },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                }
            },
        )

        if (text.isBlank()) {
            var draft by remember { mutableStateOf("") }
            Column(modifier = Modifier.fillMaxSize().padding(20.dp)) {
                TextMMD("Paste Arabic text below, then tap any word to look it up.")
                TextFieldMMD(
                    value = draft,
                    onValueChange = { draft = it },
                    modifier = Modifier.fillMaxWidth().weight(1f).padding(vertical = 12.dp),
                    textStyle = bodyStyle,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Default),
                )
                ButtonMMD(
                    onClick = { onTextChange(draft) },
                    enabled = draft.isNotBlank(),
                    modifier = Modifier.navigationBarsPadding(),
                ) {
                    TextMMD("Start reading")
                }
            }
            return@Column
        }

        val annotated = remember(text) { AnnotatedString(text) }

        Box(modifier = Modifier.weight(1f)) {
            LazyColumnMMD(
                modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp),
                state = listState,
            ) {
                item {
                    ClickableText(
                        text = annotated,
                        // Right, not End: Arabic is flush right regardless
                        // of the surrounding layout direction.
                        style = bodyStyle.copy(textAlign = TextAlign.Right),
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                        onClick = { offset ->
                            val range = wordBoundsAt(text, offset)
                            val word = text.substring(range.first, range.last + 1)
                                .trim { !it.isLetter() }
                            if (word.isNotEmpty()) {
                                loading = true
                                lookup = null
                                scope.launch {
                                    val res = LexiconRepository.search(Dict.HANSWEHR, word)
                                    lookup = word to res
                                    loading = false
                                }
                            }
                        },
                    )
                }
                item {
                    OutlinedButtonMMD(
                        onClick = { onTextChange("") },
                        modifier = Modifier.padding(vertical = 16.dp),
                    ) {
                        TextMMD("Clear & paste new text")
                    }
                }
            }
        }

        if (loading || lookup != null) {
            HorizontalDividerMMD()
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .padding(16.dp),
            ) {
                if (loading) {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicatorMMD()
                    }
                } else {
                    val (word, entries) = lookup!!
                    Row(
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        TextMMD(text = word, style = bodyStyle, fontWeight = FontWeight.Bold)
                        IconButton(onClick = { lookup = null }) {
                            Icon(Icons.Default.Close, contentDescription = "Close")
                        }
                    }
                    if (entries.isEmpty()) {
                        TextMMD("No entry found in Hans Wehr.")
                    } else {
                        for (e in entries.take(3)) {
                            RichMeaning(
                                html = e.meanings,
                                style = lookupStyle,
                                isLtr = true,
                                modifier = Modifier.padding(top = 6.dp),
                            )
                        }
                    }
                }
            }
        }
    }
}
