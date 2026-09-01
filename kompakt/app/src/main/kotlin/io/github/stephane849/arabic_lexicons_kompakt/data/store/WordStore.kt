package io.github.stephane849.arabic_lexicons_kompakt.data.store

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict

data class SearchHistItem(val word: String, val dict: Dict) {
    override fun equals(other: Any?): Boolean = other is SearchHistItem && other.word == word
    override fun hashCode(): Int = word.hashCode()
}

private class WordStoreDbHelper(context: Context) :
    SQLiteOpenHelper(context, "words.db", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE bookmarked_words (word TEXT PRIMARY KEY)")
        db.execSQL(
            "CREATE TABLE search_history (" +
                "word TEXT PRIMARY KEY, dict INTEGER NOT NULL, created_at INTEGER NOT NULL)",
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {}
}

/**
 * Port of `lib/datas/word_store.dart`'s `WordStore` — same SQLite schema
 * shape and behavior: a 10-char bookmark word-length cap, and a 200-entry
 * search-history cap with the same trim-back-to-200 batching. The original
 * app's "foreign words" (reading-progress-tracking) table isn't ported
 * here — see PORTING.md, it depends on the multi-book Reader Mode library
 * this port deliberately doesn't have.
 */
object WordStore {
    private const val HIST_MAX_SIZE = 200
    private const val MAX_BOOKMARK_WORD_SIZE = 10

    private var helper: WordStoreDbHelper? = null
    private var db: SQLiteDatabase? = null
    private var inited = false

    private val bookmarkedWordsSet = mutableSetOf<String>()
    val bookmarkedWords = mutableListOf<String>()

    val searchHist = mutableListOf<SearchHistItem>()

    private fun wordNotOk(s: String): Boolean = s.isEmpty() || s.length > MAX_BOOKMARK_WORD_SIZE

    fun init(context: Context) {
        if (inited) return
        try {
            helper = WordStoreDbHelper(context.applicationContext)
            db = helper!!.writableDatabase
            loadCache()
            inited = true
        } catch (e: Exception) {
            inited = false
        }
    }

    private fun loadCache() {
        val database = db ?: return

        database.query("bookmarked_words", null, null, null, null, null, null).use { c ->
            val idx = c.getColumnIndexOrThrow("word")
            while (c.moveToNext()) {
                val w = c.getString(idx)
                bookmarkedWords.add(w)
                bookmarkedWordsSet.add(w)
            }
        }

        database.query("search_history", null, null, null, null, null, "created_at ASC").use { c ->
            val wordIdx = c.getColumnIndexOrThrow("word")
            val dictIdx = c.getColumnIndexOrThrow("dict")
            val dicts = Dict.entries
            while (c.moveToNext()) {
                val word = c.getString(wordIdx)
                var dictIndex = c.getInt(dictIdx)
                if (dictIndex < 0 || dictIndex >= dicts.size) dictIndex = 0
                searchHist.add(SearchHistItem(word = word, dict = dicts[dictIndex]))
            }
        }
    }

    // -- Bookmarks -----------------------------------------------------

    fun isBm(word: String): Boolean = bookmarkedWordsSet.contains(word)

    fun addBm(word: String) {
        if (wordNotOk(word)) return
        if (!bookmarkedWordsSet.add(word)) return
        bookmarkedWords.add(word)
        db?.insertWithOnConflict(
            "bookmarked_words",
            null,
            ContentValues().apply { put("word", word) },
            SQLiteDatabase.CONFLICT_IGNORE,
        )
    }

    fun rmBm(word: String) {
        if (word.isEmpty()) return
        bookmarkedWordsSet.remove(word)
        bookmarkedWords.remove(word)
        db?.delete("bookmarked_words", "word = ?", arrayOf(word))
    }

    fun clearBookmarks() {
        bookmarkedWords.clear()
        bookmarkedWordsSet.clear()
        db?.delete("bookmarked_words", null, null)
    }

    // -- Search history --------------------------------------------------

    fun histAdd(d: Dict, word: String) {
        if (wordNotOk(word)) return

        val item = SearchHistItem(word = word, dict = d)
        val removedExisting = searchHist.remove(item)
        searchHist.add(item)

        db?.insertWithOnConflict(
            "search_history",
            null,
            ContentValues().apply {
                put("word", word)
                put("dict", d.ordinal)
                put("created_at", System.currentTimeMillis())
            },
            SQLiteDatabase.CONFLICT_REPLACE,
        )

        if (removedExisting) return

        if (searchHist.size > HIST_MAX_SIZE + 20) {
            val removeCount = searchHist.size - HIST_MAX_SIZE
            val toRemove = searchHist.take(removeCount)
            repeat(removeCount) { searchHist.removeAt(0) }
            rmHistItems(toRemove.map { it.word })
        }
    }

    fun rmHistItem(item: SearchHistItem) {
        searchHist.remove(item)
        db?.delete("search_history", "word = ?", arrayOf(item.word))
    }

    private fun rmHistItems(words: List<String>) {
        if (words.isEmpty()) return
        val placeholders = words.joinToString(",") { "?" }
        db?.delete("search_history", "word IN ($placeholders)", words.toTypedArray())
    }

    fun clearHist() {
        searchHist.clear()
        db?.delete("search_history", null, null)
    }
}
