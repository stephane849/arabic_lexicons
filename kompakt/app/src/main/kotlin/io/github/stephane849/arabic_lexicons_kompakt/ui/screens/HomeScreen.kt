package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Divider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict

/**
 * Launcher screen: lexicon list + navigation rows to Search/Reader/Bookmarks.
 * The original Flutter app opens straight into a search-with-drawer screen;
 * this port adds a Home screen instead (see PORTING.md — better fit for a
 * single-screen-per-purpose norm than a dense always-on chip row on first
 * launch). Feature-equivalent, different navigation shape.
 */
@Composable
fun HomeScreen(
    onOpenSearch: (Dict) -> Unit,
    onOpenReader: () -> Unit,
    onOpenBookmarks: () -> Unit,
) {
    LazyColumn(modifier = Modifier.fillMaxSize()) {
        item {
            Text(
                "Arabic Lexicons",
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(20.dp),
            )
        }

        item { NavRow("Reader Mode", "Paste text, tap a word for its meaning", onOpenReader) }
        item { NavRow("Bookmarks", "Words you've saved", onOpenBookmarks) }
        item { Divider() }

        items(Dict.ALL) { dict ->
            NavRow(dict.ar, dict.enLong) { onOpenSearch(dict) }
        }
    }
}

@Composable
private fun NavRow(title: String, subtitle: String, onClick: () -> Unit) {
    val interactionSource = remember { MutableInteractionSource() }
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(interactionSource = interactionSource, indication = null, onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 16.dp),
    ) {
        Text(title, style = MaterialTheme.typography.titleMedium)
        Text(subtitle, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
    Divider()
}
