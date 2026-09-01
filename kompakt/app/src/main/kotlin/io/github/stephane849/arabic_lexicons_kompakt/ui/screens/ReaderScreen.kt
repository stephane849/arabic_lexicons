package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.ClickableText
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.data.LexiconRepository
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow
import io.github.stephane849.arabic_lexicons_kompakt.ui.components.RichMeaning
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
 * Reader Mode's core interaction, ported faithfully per PORTING.md: paste
 * text, tap any word, see its meaning. Unlike the original (which persists
 * a library of named "books" on disk with per-book settings), this keeps a
 * single in-memory working buffer — paste, read, done, no saved library.
 */
@Composable
fun ReaderScreen(text: String, onTextChange: (String) -> Unit, onBack: () -> Unit) {
    var lookup by remember { mutableStateOf<Pair<String, List<DbRow>>?>(null) }
    var loading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Column(modifier = Modifier.fillMaxSize()) {
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically, modifier = Modifier.padding(4.dp)) {
            IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, contentDescription = "Back") }
            Text("Reader Mode", style = MaterialTheme.typography.titleLarge)
        }

        if (text.isBlank()) {
            var draft by remember { mutableStateOf("") }
            Column(modifier = Modifier.fillMaxSize().padding(20.dp)) {
                Text("Paste Arabic text below and tap any word to see its meaning.")
                OutlinedTextField(
                    value = draft,
                    onValueChange = { draft = it },
                    modifier = Modifier.fillMaxWidth().padding(vertical = 12.dp),
                    minLines = 8,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                )
                Button(onClick = { onTextChange(draft) }, enabled = draft.isNotBlank()) {
                    Text("Start reading")
                }
            }
        } else {
            val annotated = remember(text) { AnnotatedString(text) }

            LazyColumn(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp)) {
                item {
                    ClickableText(
                        text = annotated,
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.padding(top = 8.dp),
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
                    Button(
                        onClick = { onTextChange("") },
                        modifier = Modifier.padding(top = 16.dp),
                    ) { Text("Clear & paste new text") }
                }
            }
        }

        if (loading || lookup != null) {
            Surface(tonalElevation = 4.dp, modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    if (loading) {
                        CircularProgressIndicator()
                    } else {
                        val (word, entries) = lookup!!
                        Row(
                            horizontalArrangement = Arrangement.SpaceBetween,
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Text(word, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                            IconButton(onClick = { lookup = null }) {
                                Text("✕")
                            }
                        }
                        if (entries.isEmpty()) {
                            Text("No entry found in Hans Wehr.")
                        } else {
                            for (e in entries.take(3)) {
                                RichMeaning(e.meanings, modifier = Modifier.padding(top = 6.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}
