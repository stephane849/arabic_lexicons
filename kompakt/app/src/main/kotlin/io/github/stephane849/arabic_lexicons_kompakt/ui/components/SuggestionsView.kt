package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import com.mudita.mmd.components.cards.CardMMD
import com.mudita.mmd.components.chips.AssistChipMMD
import com.mudita.mmd.components.lazy.LazyRowMMD
import com.mudita.mmd.components.text.TextMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.data.suggest.SuggestionEntry
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicLabel

/**
 * Port of `showSearchSugg` from `lib/lex/sugg/widgets.dart` — one card per
 * dictionary, each holding the words that dictionary can actually answer
 * for. Accepting a chip therefore picks a word *and* a dictionary at once,
 * which is how the original lets you search first and choose the lexicon
 * second.
 *
 * The original tints the matched substring and the root marker; on E Ink
 * there is no tint to spend, so the match is carried by weight and the
 * selected dictionary by a check glyph.
 */
fun LazyListScope.suggestionCards(
    query: String,
    dictOrder: List<Dict>,
    suggestions: Map<Dict, Set<SuggestionEntry>>,
    selectedDict: Dict,
    onPick: (word: String, dict: Dict) -> Unit,
) {
    for (dict in dictOrder) {
        val entries = suggestions[dict].orEmpty()
        val isSelected = dict == selectedDict

        // The selected dictionary always shows, so "nothing here" is still
        // an answer; the rest only when they have something.
        if (!isSelected && entries.isEmpty()) continue

        // One card per item, so MMD's jump-scrolling advances by whole
        // dictionaries rather than dragging through one giant item.
        item(key = dict.name) {
            SuggestionCard(
                dict = dict,
                entries = entries,
                query = query,
                isSelected = isSelected,
                onPick = onPick,
            )
        }
    }
}

@Composable
private fun SuggestionCard(
    dict: Dict,
    entries: Set<SuggestionEntry>,
    query: String,
    isSelected: Boolean,
    onPick: (word: String, dict: Dict) -> Unit,
) {
    CardMMD(modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 12.dp, bottom = 10.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (isSelected) {
                Icon(
                    Icons.Default.Check,
                    contentDescription = "Current lexicon",
                    modifier = Modifier.size(16.dp).padding(end = 2.dp),
                )
            }
            TextMMD(
                text = dict.ar,
                style = arabicLabel,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                textAlign = TextAlign.Center,
            )
        }

        if (entries.isEmpty()) {
            TextMMD(
                text = "لا توجد نتائج لـ: $query",
                style = arabicLabel,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(bottom = 14.dp),
            )
        } else {
            LazyRowMMD(
                modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                reverseLayout = true,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                isScrollbarVisible = false,
            ) {
                items(entries.toList()) { entry ->
                    // A root is the entry worth spotting in a row of chips;
                    // the original stars it, and a glyph survives E Ink where
                    // its accent color would not.
                    val rootIcon: (@Composable () -> Unit)? = if (entry.isRoot) {
                        {
                            Icon(
                                Icons.Default.Star,
                                contentDescription = "Root",
                                modifier = Modifier.size(14.dp),
                            )
                        }
                    } else {
                        null
                    }

                    AssistChipMMD(
                        onClick = { onPick(entry.word, dict) },
                        leadingIcon = rootIcon,
                        label = {
                            TextMMD(
                                text = highlightMatch(entry.word.replace('_', ' '), query),
                                style = arabicLabel,
                            )
                        },
                    )
                }
            }
        }
    }
}

/** Bolds the part of [text] the user actually typed. */
private fun highlightMatch(text: String, query: String) = buildAnnotatedString {
    val at = if (query.isEmpty()) -1 else text.indexOf(query)
    if (at < 0) {
        append(text)
        return@buildAnnotatedString
    }
    append(text.substring(0, at))
    withStyle(SpanStyle(fontWeight = FontWeight.Bold)) {
        append(text.substring(at, at + query.length))
    }
    append(text.substring(at + query.length))
}
