package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.widget.Toast

/**
 * Puts an entry on the clipboard as plain text, headword first when there
 * is one, so it can be pasted into notes or a flashcard app.
 */
fun copyEntry(context: Context, word: String, html: String) {
    val body = meaningPlainText(html)
    val text = if (word.isEmpty()) body else "$word\n$body"

    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    clipboard.setPrimaryClip(ClipData.newPlainText(word.ifEmpty { "entry" }, text))

    // Android 13 and later confirm a copy themselves; before that, nothing
    // would show that the long press did anything.
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
        Toast.makeText(context, "Entry copied", Toast.LENGTH_SHORT).show()
    }
}
