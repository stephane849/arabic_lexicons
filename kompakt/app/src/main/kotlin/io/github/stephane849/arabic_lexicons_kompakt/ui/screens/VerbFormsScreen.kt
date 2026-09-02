package io.github.stephane849.arabic_lexicons_kompakt.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.latinBody

/**
 * The ten verb forms — the table Hans Wehr assumes you already have. It
 * lists a root's derived forms by Roman numeral alone, so II or VII is
 * only meaningful if you know what the pattern does to the root.
 *
 * Every form is collapsed to its numeral and pattern, which puts the whole
 * table on one screen: the numeral is what the dictionary hands you, and
 * the pattern is what you need back from it. Tapping a row opens the rest
 * in place — no sheet, and no expand animation, since on E Ink a growing
 * container repaints every frame of its growth.
 *
 * Each part is a separate list item, which is also what lets MMD's
 * index-based scrolling step through the page.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VerbFormsScreen(viewModel: AppViewModel, onBack: () -> Unit) {
    val listState = rememberLazyListState()
    val arabicStyle = arabicBody(viewModel.arabicFontSize)
    val latinStyle = latinBody(viewModel.latinFontSize)

    // Collapsed by default, so the ten numerals and their patterns sit on
    // one screen and the page works as a lookup table.
    val expanded = remember { mutableStateMapOf<String, Boolean>() }
    var glossaryOpen by remember { mutableStateOf(false) }

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
                val isOpen = expanded[form.form] == true

                item(key = "h-${form.form}") {
                    FormHeader(
                        form = form,
                        arabicStyle = arabicStyle,
                        expanded = isOpen,
                        onToggle = { expanded[form.form] = !isOpen },
                    )
                }

                if (isOpen) {
                    item(key = "m-${form.form}") { FormMeta(form, arabicStyle, latinStyle) }
                    item(key = "x-${form.form}") {
                        Labelled("Explanation", form.explanation, latinStyle)
                    }
                    form.examples.forEachIndexed { i, example ->
                        item(key = "e-${form.form}-$i") {
                            ExampleRow(example, arabicStyle, latinStyle)
                        }
                    }
                }

                item(key = "d-${form.form}") { HorizontalDividerMMD() }
            }

            item(key = "glossary") {
                SectionHeader(
                    title = "Grammar glossary",
                    expanded = glossaryOpen,
                    onToggle = { glossaryOpen = !glossaryOpen },
                )
            }

            if (glossaryOpen) {
                GRAMMAR_TERMS.forEachIndexed { i, term ->
                    item(key = "g-$i") { Labelled(term.term, term.definition, latinStyle) }
                }
            }
        }
    }
}

/**
 * A form's row: the numeral and its pattern, and nothing else until it is
 * opened. Collapsed, the ten rows are the reference — the numeral is what
 * Hans Wehr gives you and the pattern is what you need back from it.
 *
 * No expand animation: on E Ink a growing container repaints every frame
 * of the growth, so the detail simply appears.
 */
@Composable
private fun FormHeader(
    form: VerbForm,
    arabicStyle: TextStyle,
    expanded: Boolean,
    onToggle: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle)
            .heightIn(min = 52.dp)
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
            contentDescription = if (expanded) "Collapse" else "Expand",
            modifier = Modifier.padding(end = 8.dp),
        )
        TextMMD(
            text = "Form ${form.form}",
            fontWeight = FontWeight.Bold,
            modifier = Modifier.weight(1f),
        )
        // The pattern is the point of the row, so it gets the reader's
        // chosen Arabic size rather than the chrome size.
        TextMMD(
            text = form.pattern,
            style = arabicStyle,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Right,
        )
    }
}

/** The same affordance for a whole section, such as the glossary. */
@Composable
private fun SectionHeader(title: String, expanded: Boolean, onToggle: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle)
            .heightIn(min = 52.dp)
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
            contentDescription = if (expanded) "Collapse" else "Expand",
            modifier = Modifier.padding(end = 8.dp),
        )
        TextMMD(text = title, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun FormMeta(form: VerbForm, arabicStyle: TextStyle, latinStyle: TextStyle) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Labelled("Common meaning", form.commonMeaning, latinStyle)
        Labelled("Transitivity", form.transitivity, latinStyle)
        Labelled("Morphology", form.morphologyNote, latinStyle)
        Labelled("Example root", form.rootExample, arabicStyle, valueIsArabic = true)
    }
}

@Composable
private fun ExampleRow(example: VerbExample, arabicStyle: TextStyle, latinStyle: TextStyle) {
    Column(modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
        TextMMD(
            text = example.arabic,
            style = arabicStyle,
            textAlign = TextAlign.Right,
            modifier = Modifier.fillMaxWidth(),
        )
        TextMMD(
            text = example.literal,
            style = latinStyle,
            textAlign = TextAlign.Left,
            modifier = Modifier.fillMaxWidth().padding(top = 2.dp),
        )
    }
}

/** A bold label with its value beneath — the original's section shape. */
@Composable
private fun Labelled(
    label: String,
    value: String,
    valueStyle: TextStyle,
    valueIsArabic: Boolean = false,
) {
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        TextMMD(
            text = label,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Left,
            modifier = Modifier.fillMaxWidth(),
        )
        TextMMD(
            text = value,
            style = valueStyle,
            textAlign = if (valueIsArabic) TextAlign.Right else TextAlign.Left,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
