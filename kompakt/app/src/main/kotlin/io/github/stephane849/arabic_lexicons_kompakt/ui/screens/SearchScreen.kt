package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow
import io.github.stephane849.arabic_lexicons_kompakt.data.store.WordStore
import io.github.stephane849.arabic_lexicons_kompakt.data.suggest.SuggestionEntry
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.RichMeaning
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.EInk

@Composable
fun SearchScreen(
    selectedDict: Dict,
    query: String,
    results: List<DbRow>,
    suggestions: Map<Dict, Set<SuggestionEntry>>,
    bookmarksVersion: Int,
    onDictChange: (Dict) -> Unit,
    onQueryChange: (String) -> Unit,
    onSearch: (Dict, String) -> Unit,
    onToggleBookmark: (String) -> Unit,
    onBack: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
            modifier = Modifier.padding(start = 4.dp, end = 20.dp, top = 8.dp, bottom = 4.dp),
        ) {
            IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, contentDescription = "Back") }
            Text(selectedDict.ar, style = MaterialTheme.typography.titleLarge)
        }

        DictSelectorRow(selectedDict, onDictChange)

        OutlinedTextField(
            value = query,
            onValueChange = onQueryChange,
            placeholder = { Text("Search…") },
            singleLine = true,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 8.dp),
        )

        val currentSuggestions = suggestions[selectedDict].orEmpty().toList()
        if (query.isNotBlank() && currentSuggestions.isNotEmpty() && results.isEmpty()) {
            LazyColumn(modifier = Modifier.fillMaxWidth()) {
                items(currentSuggestions) { s: SuggestionEntry ->
                    Text(
                        s.word,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSearch(selectedDict, s.word) }
                            .padding(horizontal = 20.dp, vertical = 10.dp),
                        style = MaterialTheme.typography.bodyLarge,
                    )
                    Divider()
                }
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(results) { row: DbRow ->
                    ResultCard(row, WordStore.isBm(row.word), onToggleBookmark)
                    Divider()
                }
            }
        }
    }
}

@Composable
private fun DictSelectorRow(selected: Dict, onDictChange: (Dict) -> Unit) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp),
    ) {
        items(Dict.ALL) { dict ->
            val interactionSource = remember { MutableInteractionSource() }
            val isSelected = dict == selected
            Text(
                dict.ar,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                color = if (isSelected) EInk.black else EInk.ink40,
                modifier = Modifier
                    .clickable(interactionSource = interactionSource, indication = null) { onDictChange(dict) }
                    .background(if (isSelected) EInk.ink10 else EInk.paper)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
            )
        }
    }
}

@Composable
private fun ResultCard(row: DbRow, isBookmarked: Boolean, onToggleBookmark: (String) -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp)) {
        Row(
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(
                row.word,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = if (row.isRoot) FontWeight.Bold else FontWeight.Normal,
            )
            IconButton(onClick = { onToggleBookmark(row.word) }) {
                Icon(
                    if (isBookmarked) Icons.Default.Star else Icons.Default.StarBorder,
                    contentDescription = "Bookmark",
                )
            }
        }
        RichMeaning(row.meanings, modifier = Modifier.padding(top = 4.dp))
    }
}
