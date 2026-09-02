package io.github.stephane849.arabic_lexicons_kompakt.data.store

import android.content.Context
import android.content.SharedPreferences

/**
 * Persisted user preferences.
 *
 * Arabic and Latin text are sized separately, because a page is usually
 * both at once — Hans Wehr's headwords are Arabic while its definitions
 * are English — and the two scripts do not read as the same size at the
 * same point value. The range matches the Flutter app's font size sheet
 * (`lib/font_size.dart`: 14–30), and the Arabic key is the one that app
 * already uses, so an existing setting carries over.
 */
object Settings {
    const val MIN_FONT_SIZE = 14
    const val MAX_FONT_SIZE = 30
    const val DEFAULT_ARABIC_FONT_SIZE = 18
    const val DEFAULT_LATIN_FONT_SIZE = 16
    const val FONT_SIZE_STEP = 1

    private const val PREFS_NAME = "kompakt_settings"
    private const val KEY_ARABIC_FONT_SIZE = "ar_font_size"
    private const val KEY_LATIN_FONT_SIZE = "en_font_size"

    private var prefs: SharedPreferences? = null

    fun init(context: Context) {
        if (prefs != null) return
        prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun arabicFontSize(): Int = read(KEY_ARABIC_FONT_SIZE, DEFAULT_ARABIC_FONT_SIZE)

    fun latinFontSize(): Int = read(KEY_LATIN_FONT_SIZE, DEFAULT_LATIN_FONT_SIZE)

    fun setArabicFontSize(size: Int) = write(KEY_ARABIC_FONT_SIZE, size)

    fun setLatinFontSize(size: Int) = write(KEY_LATIN_FONT_SIZE, size)

    private fun read(key: String, default: Int): Int =
        (prefs?.getInt(key, default) ?: default).coerceIn(MIN_FONT_SIZE, MAX_FONT_SIZE)

    private fun write(key: String, size: Int) {
        prefs?.edit()?.putInt(key, size.coerceIn(MIN_FONT_SIZE, MAX_FONT_SIZE))?.apply()
    }
}
