package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import com.mudita.mmd.components.divider.HorizontalDividerMMD
import com.mudita.mmd.components.text.TextMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.store.Settings
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicBody
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicLabel
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.latinBody

/** The original's preview line, from `lib/font_size.dart`. */
private const val ARABIC_PREVIEW = "هذا مثال لتجربة حجم الخط\nهذا هو السطر التالي"
private const val LATIN_PREVIEW = "This is a sample of the text size\nand this is the next line"

/**
 * Text size picker. The two scripts are set independently, since a
 * lexicon page is usually both at once and they do not read as the same
 * size at the same point value.
 *
 * Stepped buttons rather than a slider: a slider on E Ink repaints the
 * whole track on every pixel of drag, where two buttons repaint once per
 * tap.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FontSizeSheet(
    arabicSize: Int,
    latinSize: Int,
    onArabicChange: (Int) -> Unit,
    onLatinChange: (Int) -> Unit,
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
