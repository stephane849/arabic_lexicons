package io.github.stephane849.arabic_lexicons_kompakt.data

import android.content.Context
import io.github.stephane849.arabic_lexicons_kompakt.data.aramorph.DictEngine
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbService
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
        DbService.init(context)
        arEnEngine.init(context)
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
}
