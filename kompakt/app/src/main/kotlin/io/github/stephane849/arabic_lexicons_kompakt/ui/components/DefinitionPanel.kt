package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.mudita.mmd.components.buttons.OutlinedButtonMMD
import com.mudita.mmd.components.divider.HorizontalDividerMMD
import com.mudita.mmd.components.progress_indicator.CircularProgressIndicatorMMD
import com.mudita.mmd.components.text.TextMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.LookupResult

/** Entries shown before the reader is expected to open a full search. */
private const val MAX_ENTRIES = 8

/**
 * The panel that answers a tapped word, in the reader and over search
 * results alike.
 *
 * Bounded to under half the screen so it cannot swallow what is being
 * read, and scrollable within that, because entries routinely run longer
 * than any bound worth setting. The heading stays put while they scroll,
 * since it names the form that actually resolved — often not the form
 * that was tapped.
 */
@Composable
fun DefinitionPanel(
    result: LookupResult?,
    loading: Boolean,
    headingStyle: TextStyle,
    bodyStyle: TextStyle,
    isLtr: Boolean,
    scrollState: ScrollState,
    onHeightChanged: (Int) -> Unit,
    onDismiss: () -> Unit,
    onSearchWord: (String) -> Unit,
    onWordTap: ((String) -> Unit)? = null,
) {
    if (!loading && result == null) return

    HorizontalDividerMMD()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(max = (LocalConfiguration.current.screenHeightDp * 0.45f).dp)
            .navigationBarsPadding()
            .onSizeChanged { onHeightChanged(it.height) }
            .padding(horizontal = 16.dp)
            .padding(bottom = 12.dp),
    ) {
        if (loading) {
            Box(
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                contentAlignment = Alignment.Center,
            ) {
                CircularProgressIndicatorMMD()
            }
            return@Column
        }

        val found = result ?: return@Column

        Row(
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth(),
        ) {
            TextMMD(text = found.word, style = headingStyle, fontWeight = FontWeight.Bold)
            IconButton(onClick = onDismiss) {
                Icon(Icons.Default.Close, contentDescription = "Close")
            }
        }

        Column(modifier = Modifier.fillMaxWidth().verticalScroll(scrollState)) {
            if (found.entries.isEmpty()) {
                TextMMD("No entry for this word.")
                // A full search has the suggestion fallback, which reaches
                // forms no amount of stripping or segmenting will.
                OutlinedButtonMMD(
                    onClick = { onSearchWord(found.word) },
                    modifier = Modifier.padding(top = 8.dp),
                ) {
                    TextMMD("Search for this word")
                }
            } else {
                for (entry in found.entries.take(MAX_ENTRIES)) {
                    RichMeaning(
                        html = entry.meanings,
                        style = bodyStyle,
                        isLtr = isLtr,
                        onWordTap = onWordTap,
                        modifier = Modifier.fillMaxWidth().padding(top = 6.dp),
                    )
                }
            }
        }
    }
}
