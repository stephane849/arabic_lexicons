package io.github.stephane849.arabic_lexicons_kompakt.data.db

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import java.io.File
import java.util.zip.ZipInputStream

data class DbRow(
    val word: String,
    val meanings: String,
    val isRoot: Boolean = false,
    val isHi: Boolean = false,
)

/** Simple LRU cache, mirroring `lib/lex/utils.dart`'s `LruCache`. */
private class LruCache<K, V>(private val capacity: Int) {
    private val map = object : LinkedHashMap<K, V>(capacity, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<K, V>?): Boolean =
            size > capacity
    }

    @Synchronized
    fun get(key: K): V? = map[key]

    @Synchronized
    fun put(key: K, value: V) {
        map[key] = value
    }
}

/**
 * Port of `lib/lex/dicts/db.dart`'s `DbService` — same four query shapes
 * (exact-word, root-chain for Hans Wehr/Lane, root-or-no-harakat for Ghani,
 * plus Hans Wehr's meanings-substring fallback with highlighting), the LRU
 * result cache, and the `[[...]]` footnote/reference processor with
 * Arabic-Indic numerals.
 *
 * The bundled `db.sqlite.zip` asset is copied + unzipped into internal
 * storage on first run (same asset-copy-once strategy as the Flutter app's
 * DbService, since a raw SQLite file can't be queried straight out of an
 * APK's compressed assets).
 */
object DbService {
    private const val DB_FILE_NAME = "db_v1.sqlite"
    private const val ASSET_ZIP_PATH = "db/db.sqlite.zip"

    private var db: SQLiteDatabase? = null
    private val cache = LruCache<String, List<DbRow>>(150)

    fun init(context: Context) {
        if (db != null) return
        val dbFile = File(context.filesDir, DB_FILE_NAME)
        if (!dbFile.exists()) {
            dbFile.parentFile?.mkdirs()
            context.assets.open(ASSET_ZIP_PATH).use { assetStream ->
                ZipInputStream(assetStream).use { zip ->
                    val entry = zip.nextEntry ?: throw IllegalStateException("db.sqlite.zip is empty")
                    dbFile.outputStream().use { out -> zip.copyTo(out) }
                }
            }
        }
        db = SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READONLY)
    }

    private fun database(): SQLiteDatabase =
        db ?: throw IllegalStateException("DbService.init() was not called")

    private fun getByWordWith3Rows(d: Dict, word: String?): List<DbRow> {
        if (word.isNullOrEmpty()) return emptyList()
        val database = database()
        val cursor = database.query(d.table, null, "word = ?", arrayOf(word), null, null, null)
        val entries = mutableListOf<DbRow>()
        cursor.use {
            val wordIdx = it.getColumnIndex("word")
            val meaningsIdx = it.getColumnIndex("meanings")
            while (it.moveToNext()) {
                val meaningsRaw = if (meaningsIdx >= 0) it.getString(meaningsIdx) ?: "" else ""
                var m = meaningsRaw.replace("|", "\n").replace("<br>", "\n")
                if (d.hasRefs) m = ReferenceProcessor.process(m)
                entries.add(DbRow(word = if (wordIdx >= 0) it.getString(wordIdx) ?: "" else "", meanings = m))
            }
        }
        return entries
    }

    private fun getByWordGhani(word: String?): List<DbRow> {
        if (word.isNullOrEmpty()) return emptyList()
        val database = database()
        val q = "SELECT word, root, meanings FROM mujamul_ghoni WHERE root = ? OR no_harakat = ?"
        val entries = mutableListOf<DbRow>()
        database.rawQuery(q, arrayOf(word, word)).use { c ->
            while (c.moveToNext()) {
                val meaningsRaw = c.getString(c.getColumnIndexOrThrow("meanings")) ?: ""
                val root = c.getString(c.getColumnIndexOrThrow("root"))
                entries.add(
                    DbRow(
                        word = c.getString(c.getColumnIndexOrThrow("word")) ?: "",
                        meanings = meaningsRaw.replace("|", "\n").replace("<br>", "\n"),
                        isRoot = !root.isNullOrEmpty(),
                    ),
                )
            }
        }
        return entries
    }

    private fun getByWordHans(word: String?): List<DbRow> {
        if (word.isNullOrBlank()) return emptyList()
        val database = database()
        val query = word.trim()
        val results = mutableListOf<DbRow>()

        fun runRootChain(sql: String): List<DbRow> {
            val rows = mutableListOf<DbRow>()
            database.rawQuery(sql, arrayOf(query)).use { c ->
                while (c.moveToNext()) {
                    val w = c.getString(c.getColumnIndexOrThrow("word")) ?: ""
                    rows.add(
                        DbRow(
                            word = w,
                            meanings = c.getString(c.getColumnIndexOrThrow("meanings")) ?: "",
                            isRoot = c.getInt(c.getColumnIndexOrThrow("is_root")) == 1,
                            isHi = word == w,
                        ),
                    )
                }
            }
            return rows
        }

        val byExactRoot = runRootChain(
            """
            SELECT word, meanings, is_root
            FROM hanswehr
            WHERE parent_id IN (
              SELECT parent_id FROM hanswehr WHERE is_root AND word = ?
            )
            ORDER BY id
            """.trimIndent(),
        )
        if (byExactRoot.isNotEmpty()) return byExactRoot

        val byAnyMatch = runRootChain(
            """
            SELECT word, meanings, is_root
            FROM hanswehr
            WHERE parent_id IN (
              SELECT parent_id FROM hanswehr WHERE word = ?
            )
            ORDER BY id
            """.trimIndent(),
        )
        if (byAnyMatch.isNotEmpty()) return byAnyMatch

        if (query.length >= 3) {
            val likeQuery = query.replace("_", " ")
            database.rawQuery(
                "SELECT word, meanings, is_root FROM hanswehr WHERE meanings LIKE ? LIMIT 40",
                arrayOf("%$likeQuery%"),
            ).use { c ->
                while (c.moveToNext()) {
                    val w = c.getString(c.getColumnIndexOrThrow("word")) ?: ""
                    val m = c.getString(c.getColumnIndexOrThrow("meanings")) ?: ""
                    val highlighted = m.replace(likeQuery, "<span class=\"high\">$likeQuery</span>")
                    results.add(
                        DbRow(
                            word = w,
                            meanings = highlighted,
                            isRoot = c.getInt(c.getColumnIndexOrThrow("is_root")) == 1,
                        ),
                    )
                }
            }
            return results
        }

        return results
    }

    private fun getByWordLane(word: String?): List<DbRow> {
        if (word.isNullOrEmpty()) return emptyList()
        val database = database()
        val results = mutableListOf<DbRow>()

        fun run(sql: String): List<DbRow> {
            val rows = mutableListOf<DbRow>()
            database.rawQuery(sql, arrayOf(word)).use { c ->
                while (c.moveToNext()) {
                    val w = c.getString(c.getColumnIndexOrThrow("word")) ?: ""
                    rows.add(
                        DbRow(
                            word = w,
                            meanings = c.getString(c.getColumnIndexOrThrow("meanings")) ?: "",
                            isRoot = c.getInt(c.getColumnIndexOrThrow("is_root")) == 1,
                            isHi = word == w,
                        ),
                    )
                }
            }
            return rows
        }

        val byExactRoot = run(
            """SELECT word, meanings, is_root FROM lanelexcon
               WHERE parent_id IN (SELECT parent_id FROM lanelexcon WHERE is_root AND WORD = ?)
               ORDER BY id""",
        )
        if (byExactRoot.isNotEmpty()) return byExactRoot

        val byAnyMatch = run(
            """SELECT word, meanings, is_root FROM lanelexcon
               WHERE parent_id IN (SELECT parent_id FROM lanelexcon WHERE WORD = ?)
               ORDER BY id""",
        )
        if (byAnyMatch.isNotEmpty()) return byAnyMatch

        return results
    }

    fun getSearchSuggestionList(selectedDict: Dict): List<Pair<String, Boolean>> {
        val res = mutableListOf<Pair<String, Boolean>>()
        val database = database()

        when (selectedDict) {
            Dict.AR_EN -> return res

            Dict.MUJAMUL_GHONI -> {
                database.rawQuery("SELECT root, no_harakat FROM ${selectedDict.table}", null).use { c ->
                    while (c.moveToNext()) {
                        val root = c.getString(c.getColumnIndexOrThrow("root")) ?: ""
                        if (root.isNotEmpty()) res.add(root to (root.length < 5))
                        val nh = c.getString(c.getColumnIndexOrThrow("no_harakat")) ?: ""
                        if (nh.isNotEmpty() && nh != root) res.add(nh to false)
                    }
                }
            }

            Dict.HANSWEHR, Dict.LANE_LEXICON -> {
                database.rawQuery("SELECT word, is_root FROM ${selectedDict.table}", null).use { c ->
                    while (c.moveToNext()) {
                        val word = c.getString(c.getColumnIndexOrThrow("word")) ?: ""
                        val isRoot = c.getInt(c.getColumnIndexOrThrow("is_root")) == 1
                        if (word.isNotEmpty()) res.add(word to (isRoot && word.length < 5))
                    }
                }
            }

            else -> {
                database.rawQuery("SELECT word FROM ${selectedDict.table}", null).use { c ->
                    while (c.moveToNext()) {
                        val word = c.getString(c.getColumnIndexOrThrow("word")) ?: ""
                        if (word.isNotEmpty()) res.add(word to false)
                    }
                }
            }
        }
        return res
    }

    fun search(d: Dict, word: String): List<DbRow> {
        val key = "${d.table}_$word"
        cache.get(key)?.let { return it }

        val dbRes: List<DbRow> = when (d) {
            Dict.HANSWEHR -> getByWordHans(word)
            Dict.LANE_LEXICON -> getByWordLane(word)
            Dict.MUJAMUL_GHONI -> getByWordGhani(word)
            Dict.MUJAMUL_SHIHAH,
            Dict.LISAN_AL_ARAB,
            Dict.MUJAMUL_MUASHIROH,
            Dict.MUJAMUL_WASITH,
            Dict.MUJAMUL_MUHITH,
            Dict.MUFRADAT_ALFAJUL_QURAN,
            Dict.MAQAYEESUL_LUGA,
            -> getByWordWith3Rows(d, word)
            Dict.AR_EN -> throw IllegalStateException("AR_EN is handled by DictEngine, not DbService")
        }

        cache.put(key, dbRes)
        return dbRes
    }
}

object ReferenceProcessor {
    private val refExp = Regex("\\[\\[(.*?)]]", RegexOption.DOT_MATCHES_ALL)

    fun process(text: String): String {
        if (text.isEmpty()) return text

        val mainBuffer = StringBuilder()
        val refs = mutableListOf<String>()

        var lastIndex = 0
        var counter = 1

        for (match in refExp.findAll(text)) {
            mainBuffer.append(text, lastIndex, match.range.first)

            val refContent = match.groupValues.getOrNull(1)
            if (refContent != null) {
                refs.add(refContent.trim())
                mainBuffer.append("(${enToArNum(counter)})")
                counter++
            }

            lastIndex = match.range.last + 1
        }

        mainBuffer.append(text, lastIndex, text.length)

        if (refs.isEmpty()) return mainBuffer.toString()

        mainBuffer.append("\n\n")

        for (i in refs.indices) {
            val arabicNumber = enToArNum(i + 1)
            val r = refs[i].trim().replaceFirst(". ", "")
            mainBuffer.append("($arabicNumber) ").append(r).append('\n')
        }

        return mainBuffer.toString().trimEnd()
    }
}

/** Port of `lib/utils.dart`'s `enToArNum` — Western digits to Arabic-Indic digits. */
fun enToArNum(n: Any): String =
    n.toString().map { c -> if (c.isDigit()) (0x0660 + (c - '0')).toChar() else c }.joinToString("")
