package io.github.stephane849.arabic_lexicons_kompakt.data

import android.content.Context
import io.github.stephane849.arabic_lexicons_kompakt.data.aramorph.AraMorphAssets
import io.github.stephane849.arabic_lexicons_kompakt.data.aramorph.DictEngine
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbService
import io.github.stephane849.arabic_lexicons_kompakt.data.store.Settings
import io.github.stephane849.arabic_lexicons_kompakt.data.store.WordStore
import io.github.stephane849.arabic_lexicons_kompakt.data.suggest.SuggestionEngine
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Glues DbService (11 SQL-backed lexicons), DictEngine (the "Direct"/arEn
 * morphological engine, which isn't SQL-backed — see db.dart's own
 * special-casing of Dict.arEn) and SuggestionEngine behind one facade the
 * UI talks to, and owns startup initialization order.
 */
object LexiconRepository {
    private val arEnEngine = DictEngine()
    private val suggestionEngine = SuggestionEngine()

    @Volatile
    var ready = false
        private set

    suspend fun init(context: Context) = withContext(Dispatchers.IO) {
        Settings.init(context)
        DbService.init(context)
        AraMorphAssets.load(context, arEnEngine)
        WordStore.init(context)
        suggestionEngine.init(context)
        ready = true
    }

    suspend fun search(dict: Dict, word: String): List<DbRow> = withContext(Dispatchers.IO) {
        if (word.isBlank()) return@withContext emptyList()
        if (dict == Dict.AR_EN) {
            arEnEngine.findWords(word).map { DbRow(word = it.word, meanings = it.def) }
        } else {
            DbService.search(dict, word)
        }
    }

    suspend fun suggestions(query: String) = withContext(Dispatchers.IO) {
        suggestionEngine.getSuggestions(query)
    }

    /**
     * The dictionary forms Aramorph can segment [word] into, best first.
     *
     * Running text gives you inflected, prefixed words; the lexicons hold
     * headwords. The morphological engine already bundled for the arEn
     * dictionary knows that يكتبون is a form of كتب, so it is what turns a
     * word tapped mid-sentence into something lookup-able.
     */
    suspend fun morphologicalForms(word: String): List<String> = withContext(Dispatchers.IO) {
        if (!ready || word.isBlank()) emptyList() else arEnEngine.analyze(word)
    }
}
