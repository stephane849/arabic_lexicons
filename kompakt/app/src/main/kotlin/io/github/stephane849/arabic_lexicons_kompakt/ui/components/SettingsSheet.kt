package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mudita.mmd.components.bottom_sheet.ModalBottomSheetMMD
import com.mudita.mmd.components.buttons.OutlinedButtonMMD
import com.mudita.mmd.components.chips.FilterChipMMD
import com.mudita.mmd.components.divider.HorizontalDividerMMD
import com.mudita.mmd.components.text.TextMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.data.store.Settings
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicBody
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicLabel
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.latinBody

/** The original's preview line, from `lib/font_size.dart`. */
private const val ARABIC_PREVIEW = "هذا مثال لتجربة حجم الخط\nهذا هو السطر التالي"
private const val LATIN_PREVIEW = "This is a sample of the text size\nand this is the next line"

/**
 * The app's settings: which lexicon answers a tapped word, and the two
 * text sizes.
 *
 * The two scripts are sized independently, since a lexicon page is
 * usually both at once and they do not read as the same size at the same
 * point value. Stepped buttons rather than a slider: a slider on E Ink
 * repaints the whole track on every pixel of drag, where two buttons
 * repaint once per tap.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsSheet(
    arabicSize: Int,
    latinSize: Int,
    tapLookupDict: Dict?,
    onArabicChange: (Int) -> Unit,
    onLatinChange: (Int) -> Unit,
    onTapLookupDictChange: (Dict?) -> Unit,
    onDismiss: () -> Unit,
) {
    ModalBottomSheetMMD(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .padding(bottom = 24.dp),
        ) {
            TapLookupControl(selected = tapLookupDict, onChange = onTapLookupDictChange)

            HorizontalDividerMMD(modifier = Modifier.padding(vertical = 16.dp))

            SizeControl(
                label = "Arabic",
                current = arabicSize,
                preview = ARABIC_PREVIEW,
                previewStyle = arabicBody(arabicSize),
                previewAlign = TextAlign.Right,
                onChange = onArabicChange,
            )

            HorizontalDividerMMD(modifier = Modifier.padding(vertical = 16.dp))

            SizeControl(
                label = "English",
                current = latinSize,
                preview = LATIN_PREVIEW,
                previewStyle = latinBody(latinSize),
                previewAlign = TextAlign.Left,
                onChange = onLatinChange,
            )
        }
    }
}

/**
 * Which lexicon a tapped word is looked up in.
 *
 * "The current lexicon" is the old fixed behaviour, kept because it is
 * what you want when reading one lexicon closely; the default is Hans
 * Wehr, because a tap inside Lisan al-Arab is usually asking what a word
 * means, not for more classical Arabic about it.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TapLookupControl(selected: Dict?, onChange: (Dict?) -> Unit) {
    Column(modifier = Modifier.fillMaxWidth()) {
        TextMMD(
            text = "Tap a word to define it in",
            style = arabicLabel,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )

        FlowRow(
            modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            FilterChipMMD(
                selected = selected == null,
                onClick = { onChange(null) },
                label = { TextMMD(text = "المعجم الحالي", style = arabicLabel) },
            )
            for (dict in Dict.ALL) {
                FilterChipMMD(
                    selected = dict == selected,
                    onClick = { onChange(dict) },
                    label = { TextMMD(text = dict.ar, style = arabicLabel) },
                )
            }
        }
    }
}

@Composable
private fun SizeControl(
    label: String,
    current: Int,
    preview: String,
    previewStyle: TextStyle,
    previewAlign: TextAlign,
    onChange: (Int) -> Unit,
) {
    // Mirrors the value the caller holds, so the preview tracks each tap.
    var size by remember(current) { mutableIntStateOf(current) }

    fun apply(next: Int) {
        val clamped = next.coerceIn(Settings.MIN_FONT_SIZE, Settings.MAX_FONT_SIZE)
        if (clamped == size) return
        size = clamped
        onChange(clamped)
    }

    Column(modifier = Modifier.fillMaxWidth()) {
        TextMMD(
            text = "$label: $size",
            style = arabicLabel,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )

        // Live preview, so the choice is made against real text rather
        // than against a number.
        Box(
            modifier = Modifier.fillMaxWidth().heightIn(min = 110.dp).padding(vertical = 8.dp),
            contentAlignment = Alignment.Center,
        ) {
            TextMMD(
                text = preview,
                style = previewStyle,
                textAlign = previewAlign,
                modifier = Modifier.fillMaxWidth(),
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedButtonMMD(
                onClick = { apply(size - Settings.FONT_SIZE_STEP) },
                enabled = size > Settings.MIN_FONT_SIZE,
                modifier = Modifier.weight(1f),
            ) {
                TextMMD("A −")
            }
            OutlinedButtonMMD(
                onClick = { apply(size + Settings.FONT_SIZE_STEP) },
                enabled = size < Settings.MAX_FONT_SIZE,
                modifier = Modifier.weight(1f),
            ) {
                TextMMD("A +")
            }
        }
    }
}
