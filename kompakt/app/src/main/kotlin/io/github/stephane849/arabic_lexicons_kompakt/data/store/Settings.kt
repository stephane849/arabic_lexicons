package io.github.stephane849.arabic_lexicons_kompakt.data.store

import android.content.Context
import android.content.SharedPreferences
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict

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

    /**
     * Which lexicon answers a tapped word out of the box. Hans Wehr is the
     * app's own default dictionary and the broadest single answer to
     * "what does this word mean", which is what a tap is asking.
     */
    val DEFAULT_TAP_LOOKUP_DICT: Dict? = Dict.HANSWEHR

    private const val PREFS_NAME = "kompakt_settings"
    private const val KEY_ARABIC_FONT_SIZE = "ar_font_size"
    private const val KEY_LATIN_FONT_SIZE = "en_font_size"
    private const val KEY_TAP_LOOKUP_DICT = "tap_lookup_dict"

    /** Stored in place of a name for "whichever lexicon is open". */
    private const val TAP_LOOKUP_FOLLOW_CURRENT = "current"

    private var prefs: SharedPreferences? = null

    fun init(context: Context) {
        if (prefs != null) return
        prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun arabicFontSize(): Int = read(KEY_ARABIC_FONT_SIZE, DEFAULT_ARABIC_FONT_SIZE)

    fun latinFontSize(): Int = read(KEY_LATIN_FONT_SIZE, DEFAULT_LATIN_FONT_SIZE)

    fun setArabicFontSize(size: Int) = write(KEY_ARABIC_FONT_SIZE, size)

    fun setLatinFontSize(size: Int) = write(KEY_LATIN_FONT_SIZE, size)

    /**
     * The lexicon a tapped word is looked up in, or null to follow the one
     * being read. Stored by name rather than ordinal: [Dict]'s order is a
     * bit position elsewhere, and this must survive the enum growing.
     */
    fun tapLookupDict(): Dict? {
        val stored = prefs?.getString(KEY_TAP_LOOKUP_DICT, null) ?: return DEFAULT_TAP_LOOKUP_DICT
        if (stored == TAP_LOOKUP_FOLLOW_CURRENT) return null
        return Dict.ALL.firstOrNull { it.name == stored } ?: DEFAULT_TAP_LOOKUP_DICT
    }

    fun setTapLookupDict(dict: Dict?) {
        prefs?.edit()
            ?.putString(KEY_TAP_LOOKUP_DICT, dict?.name ?: TAP_LOOKUP_FOLLOW_CURRENT)
            ?.apply()
    }

    private fun read(key: String, default: Int): Int =
        (prefs?.getInt(key, default) ?: default).coerceIn(MIN_FONT_SIZE, MAX_FONT_SIZE)

    private fun write(key: String, size: Int) {
        prefs?.edit()?.putInt(key, size.coerceIn(MIN_FONT_SIZE, MAX_FONT_SIZE))?.apply()
    }
}
