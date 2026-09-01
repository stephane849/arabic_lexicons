package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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

/** The original's preview line, from `lib/font_size.dart`. */
private const val PREVIEW = "هذا مثال لتجربة حجم الخط\nهذا هو السطر التالي"

/**
 * Text size picker, matching the Flutter app's range (14–30). Stepped
 * buttons rather than a slider: a slider on E Ink repaints the whole
 * track on every pixel of drag, where two buttons repaint once per tap.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FontSizeSheet(
    current: Int,
    onSizeChange: (Int) -> Unit,
    onDismiss: () -> Unit,
) {
    var size by remember { mutableIntStateOf(current) }

    fun apply(next: Int) {
        val clamped = next.coerceIn(Settings.MIN_FONT_SIZE, Settings.MAX_FONT_SIZE)
        if (clamped == size) return
        size = clamped
        onSizeChange(clamped)
    }

    ModalBottomSheetMMD(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 24.dp),
        ) {
            TextMMD(
                text = "Text size: $size",
                style = arabicLabel,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )

            HorizontalDividerMMD(modifier = Modifier.padding(vertical = 12.dp))

            // Live preview, so the choice is made against real Arabic
            // rather than against a number.
            Box(
                modifier = Modifier.fillMaxWidth().heightIn(min = 160.dp),
                contentAlignment = Alignment.Center,
            ) {
                TextMMD(
                    text = PREVIEW,
                    style = arabicBody(size),
                    textAlign = TextAlign.Right,
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            HorizontalDividerMMD(modifier = Modifier.padding(vertical = 12.dp))

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
}
