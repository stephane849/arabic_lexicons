package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mudita.mmd.components.divider.HorizontalDividerMMD
import com.mudita.mmd.components.lazy.LazyColumnMMD
import com.mudita.mmd.components.text.TextMMD
import com.mudita.mmd.components.top_app_bar.TopAppBarMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.store.WordStore
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicBody

// TopAppBarMMD wraps material3's TopAppBar, still an experimental API.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookmarksScreen(
    bookmarksVersion: Int,
    onOpenWord: (String) -> Unit,
    onRemove: (String) -> Unit,
    onBack: () -> Unit,
) {
    // `bookmarksVersion` forces recomposition whenever WordStore's bookmark
    // set changes (it isn't itself Compose-observable state).
    val words = remember(bookmarksVersion) { WordStore.bookmarkedWords.toList() }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBarMMD(
            title = { TextMMD("Bookmarks") },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                }
            },
        )

        if (words.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                TextMMD("No bookmarks yet.")
            }
            return@Column
        }

        LazyColumnMMD(modifier = Modifier.fillMaxSize()) {
            items(words) { word ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpenWord(word) }
                        .padding(start = 20.dp, top = 4.dp, bottom = 4.dp),
                ) {
                    TextMMD(
                        text = word,
                        style = arabicBody,
                        textAlign = TextAlign.End,
                        modifier = Modifier.weight(1f),
                    )
                    IconButton(onClick = { onRemove(word) }) {
                        Icon(Icons.Default.Close, contentDescription = "Remove")
                    }
                }
                HorizontalDividerMMD()
            }
        }
    }
}
