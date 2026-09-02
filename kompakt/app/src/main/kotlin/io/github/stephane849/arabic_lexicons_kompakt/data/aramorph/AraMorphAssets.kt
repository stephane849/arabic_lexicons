package io.github.stephane849.arabic_lexicons_kompakt.data.aramorph

import android.content.Context
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Reads Aramorph's six tables out of the APK's assets.
 *
 * Kept apart from [DictEngine] so the engine itself carries no Android
 * dependency and can be run against the real tables off-device.
 *
 * The files are Buckwalter transliteration in Latin-1; reading them as
 * UTF-8 would mangle the bytes above 0x7F that carry the transliteration's
 * punctuation.
 */
object AraMorphAssets {
    fun load(context: Context, engine: DictEngine) {
        val assets = context.assets
        engine.init(
            prefixes = assets.readLatin1("ar_en/dictprefixes"),
            stems = assets.readLatin1("ar_en/dictstems"),
            suffixes = assets.readLatin1("ar_en/dictsuffixes"),
            tableAb = assets.readLatin1("ar_en/tableab"),
            tableAc = assets.readLatin1("ar_en/tableac"),
            tableBc = assets.readLatin1("ar_en/tablebc"),
        )
    }

    private fun android.content.res.AssetManager.readLatin1(path: String): String =
        open(path).use { input ->
            BufferedReader(InputStreamReader(input, Charsets.ISO_8859_1)).use { it.readText() }
        }
}
