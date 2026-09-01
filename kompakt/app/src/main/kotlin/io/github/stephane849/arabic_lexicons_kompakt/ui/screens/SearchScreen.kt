package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Bookmarks
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Directions
import androidx.compose.material.icons.filled.FormatSize
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.CompositionLocalProvider
import com.mudita.mmd.components.divider.HorizontalDividerMMD
import com.mudita.mmd.components.lazy.LazyColumnMMD
import com.mudita.mmd.components.menus.DropdownMenuItemMMD
import com.mudita.mmd.components.menus.DropdownMenuMMD
import com.mudita.mmd.components.progress_indicator.CircularProgressIndicatorMMD
import com.mudita.mmd.components.text.TextMMD
import com.mudita.mmd.components.text_field.TextFieldMMD
import com.mudita.mmd.components.top_app_bar.TopAppBarMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.FontSizeSheet
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.ResultBlock
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.RichMeaning
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.WordDictPickerSheet
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.buildResultBlocks
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.suggestionCards
import io.github.stephane849.arabic_lexicons_kompakt.ui.nav.AppViewModel
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicBody
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicLabel

/** The three lexicons whose entries are written in English. */
private fun Dict.isLtr(): Boolean =
    this == Dict.AR_EN || this == Dict.HANSWEHR || this == Dict.LANE_LEXICON

/**
 * The app's home, mirroring the original Flutter app: it opens straight
 * into search rather than a dictionary menu, the input sits at the bottom
 * within thumb reach, and everything above it is the answer.
 *
 * The dictionary is chosen *after* the word — from the suggestions when
 * the current lexicon has nothing, or from the picker sheet at any time.
 */
// TopAppBarMMD wraps material3's TopAppBar, still an experimental API.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    viewModel: AppViewModel,
    onOpenReader: () -> Unit,
    onOpenBookmarks: () -> Unit,
) {
    var pickerOpen by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }
    var fontSheetOpen by remember { mutableStateOf(false) }

    val word = viewModel.selectedWord
    val showingSugg = viewModel.isShowingSugg
    val bookmarked = remember(word, viewModel.bookmarksVersion) { viewModel.isBookmarked(word) }

    Column(modifier = Modifier.fillMaxSize().imePadding()) {
        TopAppBarMMD(
            title = {
                TextMMD(
                    text = if (word.isEmpty()) viewModel.selectedDict.ar
                    else "${viewModel.selectedDict.ar}: ${word.replace('_', ' ')}",
                    style = arabicLabel,
                    fontWeight = FontWeight.Bold,
                )
            },
            actions = {
                IconButton(
                    onClick = { viewModel.toggleSuggestions() },
                    enabled = word.isNotEmpty(),
                ) {
                    Icon(
                        if (showingSugg) Icons.Default.Directions else Icons.Default.AutoAwesome,
                        contentDescription = "Toggle suggestions",
                    )
                }

                IconButton(
                    onClick = { viewModel.toggleBookmark(word) },
                    enabled = word.isNotEmpty() && !showingSugg,
                ) {
                    Icon(
                        if (bookmarked) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                        contentDescription = if (bookmarked) "Remove bookmark" else "Bookmark",
                    )
                }

                Box {
                    IconButton(onClick = { menuOpen = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "More")
                    }
                    DropdownMenuMMD(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                        DropdownMenuItemMMD(
                            text = { TextMMD("Reader Mode") },
                            leadingIcon = {
                                Icon(Icons.AutoMirrored.Filled.MenuBook, contentDescription = null)
                            },
                            onClick = {
                                menuOpen = false
                                onOpenReader()
                            },
                        )
                        DropdownMenuItemMMD(
                            text = { TextMMD("Bookmarks") },
                            leadingIcon = {
                                Icon(Icons.Default.Bookmarks, contentDescription = null)
                            },
                            onClick = {
                                menuOpen = false
                                onOpenBookmarks()
                            },
                        )
                        DropdownMenuItemMMD(
                            text = { TextMMD("Text size") },
                            leadingIcon = {
                                Icon(Icons.Default.FormatSize, contentDescription = null)
                            },
                            onClick = {
                                menuOpen = false
                                fontSheetOpen = true
                            },
                        )
                    }
                }
            },
        )

        Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
            SearchBody(viewModel)
        }

        HorizontalDividerMMD()

        SearchInputBar(
            viewModel = viewModel,
            onOpenPicker = { pickerOpen = true },
        )
    }

    if (pickerOpen) {
        WordDictPickerSheet(
            words = viewModel.words,
            selectedWord = word,
            selectedDict = viewModel.selectedDict,
            onPickWord = {
                pickerOpen = false
                viewModel.selectWord(it)
            },
            onPickDict = {
                pickerOpen = false
                viewModel.selectDict(it)
            },
            onDismiss = { pickerOpen = false },
        )
    }

    if (fontSheetOpen) {
        FontSizeSheet(
            current = viewModel.contentFontSize,
            onSizeChange = { viewModel.setContentFontSize(it) },
            onDismiss = { fontSheetOpen = false },
        )
    }
}

@Composable
private fun SearchBody(viewModel: AppViewModel) {
    val word = viewModel.selectedWord

    val emptyStyle = arabicBody(viewModel.contentFontSize)

    // Nothing typed yet.
    if (word.isEmpty()) {
        EmptyState(text = "ابحث عن كلمة", style = emptyStyle)
        return
    }

    // Suggestions: pick a word and its lexicon together.
    if (viewModel.isShowingSugg) {
        if (viewModel.suggestions.values.all { it.isEmpty() }) {
            EmptyState(text = "لا توجد اقتراحات لـ\n$word", style = emptyStyle)
            return
        }
        val suggState = rememberLazyListState()
        PageScrollHandler(viewModel, suggState)
        LazyColumnMMD(
            modifier = Modifier.fillMaxSize(),
            state = suggState,
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        ) {
            suggestionCards(
                query = word,
                dictOrder = viewModel.suggDictSorted,
                suggestions = viewModel.suggestions,
                selectedDict = viewModel.selectedDict,
                onPick = { w, d -> viewModel.onSuggestionPicked(w, d) },
            )
        }
        return
    }

    if (!viewModel.resLoaded) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicatorMMD()
        }
        return
    }

    if (viewModel.results.isEmpty()) {
        EmptyState(text = "لا توجد نتائج لـ\n$word", style = emptyStyle)
        return
    }

    val ltr = viewModel.selectedDict.isLtr()
    val listState = rememberLazyListState()
    val bodyStyle = arabicBody(viewModel.contentFontSize)

    // Long entries are broken into many small blocks, because
    // LazyColumnMMD scrolls by item index — see ResultBlocks.
    val (blocks, matchIndex) = remember(viewModel.results, ltr) {
        buildResultBlocks(viewModel.results, showTitles = !ltr)
    }

    // Hans Wehr and Lane answer with a root's whole entry chain, so the
    // word actually asked for can sit well down the list. The original
    // scrolls to it; jump straight there, with no animation to ghost.
    LaunchedEffect(blocks) {
        if (matchIndex > 0) listState.scrollToItem(matchIndex)
    }

    PageScrollHandler(viewModel, listState)

    CompositionLocalProvider(
        LocalLayoutDirection provides if (ltr) LayoutDirection.Ltr else LayoutDirection.Rtl,
    ) {
        LazyColumnMMD(
            modifier = Modifier.fillMaxSize(),
            state = listState,
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        ) {
            items(blocks.size) { i ->
                when (val block = blocks[i]) {
                    is ResultBlock.Title -> TextMMD(
                        text = block.word,
                        style = arabicLabel,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Right,
                        modifier = Modifier.fillMaxWidth().padding(top = 10.dp, bottom = 2.dp),
                    )

                    is ResultBlock.Body -> RichMeaning(
                        html = block.html,
                        style = bodyStyle,
                        isLtr = ltr,
                        emphasized = block.emphasized,
                        modifier = Modifier.fillMaxWidth().padding(vertical = 3.dp),
                    )

                    ResultBlock.Separator -> HorizontalDividerMMD(
                        modifier = Modifier.padding(vertical = 8.dp),
                    )
                }
            }
        }
    }
}

/** Pages the given list whenever a volume key is pressed. */
@Composable
private fun PageScrollHandler(viewModel: AppViewModel, listState: LazyListState) {
    LaunchedEffect(listState) {
        viewModel.pageScrolls.collect { direction ->
            val info = listState.layoutInfo
            val viewport = (info.viewportEndOffset - info.viewportStartOffset).toFloat()
            if (viewport <= 0f) return@collect
            // Just under a full screen, so a line of context carries over.
            listState.scrollBy(direction * viewport * 0.9f)
        }
    }
}

@Composable
private fun EmptyState(text: String, style: TextStyle) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        TextMMD(text = text, style = style, textAlign = TextAlign.Center)
    }
}

@Composable
private fun SearchInputBar(viewModel: AppViewModel, onOpenPicker: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        // Opens the word/lexicon picker — the deliberate way to change
        // dictionary once you have a word.
        IconButton(onClick = onOpenPicker, modifier = Modifier.size(48.dp)) {
            Icon(Icons.Default.Tune, contentDescription = "Switch lexicon or word")
        }

        TextFieldMMD(
            value = viewModel.query,
            onValueChange = { viewModel.onQueryChange(it) },
            modifier = Modifier.weight(1f),
            singleLine = true,
            textStyle = arabicBody(viewModel.contentFontSize),
            placeholder = { TextMMD(text = "ابحث", style = arabicLabel) },
            trailingIcon = {
                if (viewModel.query.text.isNotEmpty()) {
                    IconButton(onClick = { viewModel.clearQuery() }) {
                        Icon(Icons.Default.Clear, contentDescription = "Clear")
                    }
                }
            },
        )
    }
}
