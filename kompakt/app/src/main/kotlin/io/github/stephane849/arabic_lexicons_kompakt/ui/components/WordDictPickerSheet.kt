package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mudita.mmd.components.bottom_sheet.ModalBottomSheetMMD
import com.mudita.mmd.components.chips.FilterChipMMD
import com.mudita.mmd.components.divider.HorizontalDividerMMD
import com.mudita.mmd.components.text.TextMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicLabel

/**
 * Port of `_WordDictPickerSheet` from `lib/lex/widgets.dart`: the sheet
 * behind the button beside the search field, holding the words parsed out
 * of the current query and every lexicon.
 *
 * It is the deliberate, always-available half of "search then choose the
 * dictionary" — suggestions offer a dictionary when the current one comes
 * up empty, this lets you switch on demand without retyping.
 */
@Composable
fun WordDictPickerSheet(
    words: List<String>,
    selectedWord: String,
    selectedDict: Dict,
    onPickWord: (String) -> Unit,
    onPickDict: (Dict) -> Unit,
    onDismiss: () -> Unit,
) {
    ModalBottomSheetMMD(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 24.dp),
        ) {
            TextMMD(
                text = "تغيير المعجم أو الكلمة",
                style = arabicLabel,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth(),
            )

            if (words.size > 1) {
                SheetSection(title = "الكلمات") {
                    for (word in words) {
                        FilterChipMMD(
                            selected = word == selectedWord,
                            onClick = { onPickWord(word) },
                            label = {
                                TextMMD(
                                    text = word.replace('_', ' ').trim().take(30),
                                    style = arabicLabel,
                                )
                            },
                        )
                    }
                }
            }

            SheetSection(title = "المعاجم") {
                for (dict in Dict.ALL) {
                    FilterChipMMD(
                        selected = dict == selectedDict,
                        onClick = { onPickDict(dict) },
                        label = { TextMMD(text = dict.ar, style = arabicLabel) },
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SheetSection(title: String, content: @Composable () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().padding(top = 20.dp)) {
        TextMMD(
            text = title,
            style = arabicLabel,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.End,
            modifier = Modifier.fillMaxWidth(),
        )
        HorizontalDividerMMD(modifier = Modifier.padding(top = 6.dp, bottom = 12.dp))
        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            content()
        }
    }
}
