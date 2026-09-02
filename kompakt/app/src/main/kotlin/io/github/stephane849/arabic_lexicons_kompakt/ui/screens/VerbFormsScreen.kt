package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mudita.mmd.components.divider.HorizontalDividerMMD
import com.mudita.mmd.components.lazy.LazyColumnMMD
import com.mudita.mmd.components.text.TextMMD
import com.mudita.mmd.components.top_app_bar.TopAppBarMMD
import io.github.stephane849.arabic_lexicons_kompakt.data.GRAMMAR_TERMS
import io.github.stephane849.arabic_lexicons_kompakt.data.VERB_FORMS
import io.github.stephane849.arabic_lexicons_kompakt.data.VerbExample
import io.github.stephane849.arabic_lexicons_kompakt.data.VerbForm
import io.github.stephane849.arabic_lexicons_kompakt.ui.nav.AppViewModel
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicBody
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.arabicLabel

/**
 * The ten verb forms — the table Hans Wehr assumes you already have. It
 * lists a root's derived forms by Roman numeral alone, so II or VII is
 * only meaningful if you know what the pattern does to the root.
 *
 * Laid out as one long reference to page through rather than a menu of
 * forms to tap into: on E Ink, opening and closing a sheet per form costs
 * a full repaint each way. Every part is its own list item, which is also
 * what lets MMD's index-based scrolling step through it.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VerbFormsScreen(viewModel: AppViewModel, onBack: () -> Unit) {
    val listState = rememberLazyListState()
    val bodyStyle = arabicBody(viewModel.contentFontSize)

    LaunchedEffect(listState) {
        viewModel.pageScrolls.collect { direction ->
            val info = listState.layoutInfo
            val viewport = (info.viewportEndOffset - info.viewportStartOffset).toFloat()
            if (viewport > 0f) listState.scrollBy(direction * viewport * 0.9f)
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBarMMD(
            title = { TextMMD("Verb forms") },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                }
            },
        )

        LazyColumnMMD(
            modifier = Modifier.fillMaxSize(),
            state = listState,
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        ) {
            item(key = "intro") {
                TextMMD(
                    text = "Patterns are shown on the root ف ع ل. Hans Wehr lists a " +
                        "root's derived forms by these numerals.",
                    textAlign = TextAlign.Left,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                )
            }

            for (form in VERB_FORMS) {
                item(key = "h-${form.form}") { FormHeader(form, bodyStyle) }
                item(key = "m-${form.form}") { FormMeta(form) }
                item(key = "x-${form.form}") { Labelled("Explanation", form.explanation) }

                form.examples.forEachIndexed { i, example ->
                    item(key = "e-${form.form}-$i") { ExampleRow(example, bodyStyle) }
                }

                item(key = "d-${form.form}") {
                    HorizontalDividerMMD(modifier = Modifier.padding(vertical = 14.dp))
                }
            }

            item(key = "glossary") {
                TextMMD(
                    text = "Grammar glossary",
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Left,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                )
            }

            GRAMMAR_TERMS.forEachIndexed { i, term ->
                item(key = "g-$i") { Labelled(term.term, term.definition) }
            }
        }
    }
}

@Composable
private fun FormHeader(form: VerbForm, bodyStyle: TextStyle) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        TextMMD(
            text = "Form ${form.form}",
            fontWeight = FontWeight.Bold,
            modifier = Modifier.weight(1f),
        )
        // The pattern itself is the point of the row, so it gets the
        // reader's chosen size rather than the chrome size.
        TextMMD(
            text = form.pattern,
            style = bodyStyle,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Right,
        )
    }
}

@Composable
private fun FormMeta(form: VerbForm) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Labelled("Common meaning", form.commonMeaning)
        Labelled("Transitivity", form.transitivity)
        Labelled("Morphology", form.morphologyNote)
        Labelled("Example root", form.rootExample, valueIsArabic = true)
    }
}

@Composable
private fun ExampleRow(example: VerbExample, bodyStyle: TextStyle) {
    Column(modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
        TextMMD(
            text = example.arabic,
            style = bodyStyle,
            textAlign = TextAlign.Right,
            modifier = Modifier.fillMaxWidth(),
        )
        TextMMD(
            text = example.literal,
            style = arabicLabel,
            textAlign = TextAlign.Left,
            modifier = Modifier.fillMaxWidth().padding(top = 2.dp),
        )
    }
}

/** A bold label with its value beneath — the original's section shape. */
@Composable
private fun Labelled(label: String, value: String, valueIsArabic: Boolean = false) {
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        TextMMD(
            text = label,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Left,
            modifier = Modifier.fillMaxWidth(),
        )
        if (valueIsArabic) {
            TextMMD(
                text = value,
                style = arabicLabel,
                textAlign = TextAlign.Right,
                modifier = Modifier.fillMaxWidth(),
            )
        } else {
            // No explicit style: English inherits MMD's own typography.
            TextMMD(
                text = value,
                textAlign = TextAlign.Left,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}
