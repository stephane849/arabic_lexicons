package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import io.github.stephane849.arabic_lexicons_kompakt.data.store.WordStore

@Composable
fun BookmarksScreen(bookmarksVersion: Int, onOpenWord: (String) -> Unit, onBack: () -> Unit) {
    // `bookmarksVersion` forces recomposition whenever WordStore's bookmark
    // set changes (it isn't itself Compose-observable state).
    val words = remember(bookmarksVersion) { WordStore.bookmarkedWords.toList() }

    androidx.compose.foundation.layout.Column(modifier = Modifier.fillMaxSize()) {
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically, modifier = Modifier.padding(4.dp)) {
            IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, contentDescription = "Back") }
            Text("Bookmarks", style = MaterialTheme.typography.titleLarge)
        }

        if (words.isEmpty()) {
            Text("No bookmarks yet.", modifier = Modifier.padding(20.dp))
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(words) { word ->
                    Row(
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onOpenWord(word) }
                            .padding(horizontal = 20.dp, vertical = 12.dp),
                    ) {
                        Text(word, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                        IconButton(onClick = { WordStore.rmBm(word) }) {
                            Icon(Icons.Default.Close, contentDescription = "Remove")
                        }
                    }
                    Divider()
                }
            }
        }
    }
}
