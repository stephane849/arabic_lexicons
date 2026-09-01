package io.github.stephane849.arabic_lexicons_kompakt.data.store

import android.content.Context
import android.content.SharedPreferences

/**
 * Persisted user preferences. Mirrors the range the Flutter app's font
 * size sheet offers (`lib/font_size.dart`: 14–30, defaulting to 18), so a
 * reader moving between the two apps lands on the same text.
 */
object Settings {
    const val MIN_FONT_SIZE = 14
    const val MAX_FONT_SIZE = 30
    const val DEFAULT_FONT_SIZE = 18
    const val FONT_SIZE_STEP = 1

    private const val PREFS_NAME = "kompakt_settings"
    private const val KEY_FONT_SIZE = "ar_font_size"

    private var prefs: SharedPreferences? = null

    fun init(context: Context) {
        if (prefs != null) return
        prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun fontSize(): Int =
        (prefs?.getInt(KEY_FONT_SIZE, DEFAULT_FONT_SIZE) ?: DEFAULT_FONT_SIZE)
            .coerceIn(MIN_FONT_SIZE, MAX_FONT_SIZE)

    fun setFontSize(size: Int) {
        prefs?.edit()?.putInt(KEY_FONT_SIZE, size.coerceIn(MIN_FONT_SIZE, MAX_FONT_SIZE))?.apply()
    }
}
