package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.ClickableText
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mudita.mmd.components.buttons.ButtonMMD
import com.mudita.mmd.components.buttons.OutlinedButtonMMD
import com.mudita.mmd.components.lazy.LazyColumnMMD
import com.mudita.mmd.components.text.TextMMD
import com.mudita.mmd.components.text_field.TextFieldMMD
import com.mudita.mmd.components.top_app_bar.TopAppBarMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.ArabicText
import io.github.stephane849.arabic_lexicons_kompakt.data.LookupResult
import io.github.stephane849.arabic_lexicons_kompakt.data.lookUpWord
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.DefinitionPanel
import io.github.stephane849.arabic_lexicons_kompakt.ui.nav.AppViewModel
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicBody
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.latinBody
import kotlinx.coroutines.launch

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
    onOpenInSearch: (String) -> Unit,
    onBack: () -> Unit,
) {
    var lookup by remember { mutableStateOf<LookupResult?>(null) }
    var loading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    // The pasted text is Arabic; a lookup beneath it may come back in
    // either script, depending on which lexicon answers taps.
    val bodyStyle = arabicBody(viewModel.arabicFontSize)
    val lookupStyle = latinBody(viewModel.latinFontSize)
    val listState = rememberLazyListState()

    // The definition panel scrolls on its own, and is measured so the
    // volume keys can page it by roughly its own height.
    val panelScroll = rememberScrollState()
    var panelHeightPx by remember { mutableIntStateOf(0) }

    // Volume keys page the reader too — this is where paging matters most.
    // While a definition is open they page that instead, since it is what
    // you are reading and reaching past it to the text would be wrong.
    LaunchedEffect(listState, panelScroll) {
        viewModel.pageScrolls.collect { direction ->
            if (lookup != null || loading) {
                val page = panelHeightPx * 0.8f
                if (page > 0f) panelScroll.scrollBy(direction * page)
            } else {
                val info = listState.layoutInfo
                val viewport = (info.viewportEndOffset - info.viewportStartOffset).toFloat()
                if (viewport > 0f) listState.scrollBy(direction * viewport * 0.9f)
            }
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
                            val word = ArabicText.wordAt(text, offset)
                            if (word.isNotEmpty()) {
                                loading = true
                                lookup = null
                                scope.launch {
                                    lookup = lookUpWord(
                                        viewModel.selectedDict,
                                        viewModel.tapLookupDict,
                                        word,
                                    )
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

        DefinitionPanel(
            result = lookup,
            loading = loading,
            headingStyle = bodyStyle,
            arabicStyle = bodyStyle,
            latinStyle = lookupStyle,
            scrollState = panelScroll,
            onHeightChanged = { panelHeightPx = it },
            onDismiss = { lookup = null },
            onSearchWord = onOpenInSearch,
        )
    }
}
