package io.github.stephane849.arabic_lexicons_kompakt.data.suggest

import android.content.Context
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbService
import org.json.JSONArray
import java.io.File

const val SEARCH_SUGGESTIONS_LIMIT = 10
private const val SUGG_DATA_SEP = "#"
private const val PREFIX_MAX_LEN = 3
private const val SUGG_CACHE_FILE = "sugg_data.txt"
private const val SUGG_PREFIX_CACHE_FILE = "sugg_prefix.txt"

data class SuggestionMeta(val isRoot: Boolean, val dicts: MutableSet<Dict>)

data class SuggestionEntry(val isRoot: Boolean, val word: String)

private data class SuggDatas(
    val suggMap: MutableMap<String, SuggestionMeta> = mutableMapOf(),
    val allRootKeys: MutableList<String> = mutableListOf(),
    val allWordKeys: MutableList<String> = mutableListOf(),
    val prefixIndex: MutableMap<String, List<String>> = mutableMapOf(),
) {
    val isEmpty: Boolean get() = suggMap.isEmpty() || prefixIndex.isEmpty()
}

/**
 * Port of `lib/lex/sugg/sugg.dart` + `lib/lex/sugg/data.dart`: builds a
 * prefix index across every dictionary's word/root list (once, from the
 * DB) and ranks suggestions exact -> doubled-root guess -> prefix match ->
 * contains match, capped per dictionary. Cached to disk after first build,
 * same as the original (Dart isolate -> plain background work here).
 */
class SuggestionEngine {
    private var data = SuggDatas()
    private var initialized = false

    fun init(context: Context) {
        if (initialized) return

        if (loadCache(context)) {
            initialized = true
            return
        }

        val built = buildFromDb()
        if (built.isEmpty) return

        data = built
        initialized = true
        saveCache(context, built)
    }

    fun getSuggestions(query: String, limit: Int = SEARCH_SUGGESTIONS_LIMIT): Map<Dict, Set<SuggestionEntry>> {
        if (query.isEmpty()) return emptyMap()

        val res: MutableMap<Dict, MutableSet<SuggestionEntry>> =
            Dict.ALL.associateWith { mutableSetOf<SuggestionEntry>() }.toMutableMap()

        var filledDict = 0
        val filledDictLen = Dict.ALL.size - 1

        fun add(mq: String): Boolean {
            val found = data.suggMap[mq] ?: return false
            for (d in found.dicts) {
                val bucket = res.getValue(d)
                if (bucket.size > limit) {
                    filledDict++
                    if (filledDict == filledDictLen) return true
                    continue
                }
                bucket.add(SuggestionEntry(found.isRoot, mq))
            }
            return false
        }

        if (add(query)) return res

        // when two chars it might be like حب where the root is حبب
        if (query.length == 2) {
            val q = query + query.substring(1)
            if (add(q)) return res
        }

        data.prefixIndex[query]?.let { prefixList ->
            for (w in prefixList) {
                if (add(w)) return res
            }
        }

        for (word in data.allRootKeys) {
            if (word.contains(query)) {
                if (add(word)) return res
            }
        }

        for (word in data.allWordKeys) {
            if (word.contains(query)) {
                if (add(word)) return res
            }
        }

        return res
    }

    private fun buildFromDb(): SuggDatas {
        val currData = SuggDatas()
        val prefixIndexRootGen = mutableMapOf<String, MutableSet<String>>()
        val prefixIndexWordGen = mutableMapOf<String, MutableSet<String>>()

        for (d in Dict.ALL) {
            if (d == Dict.AR_EN) continue

            val list = DbService.getSearchSuggestionList(d)
            for ((key, isRoot) in list) {
                val existing = currData.suggMap[key]

                if (existing != null && !existing.isRoot && isRoot) {
                    currData.suggMap[key] = SuggestionMeta(true, existing.dicts)
                    currData.allRootKeys.add(key)
                    currData.allWordKeys.remove(key)

                    for (i in 1..minOf(PREFIX_MAX_LEN, key.length)) {
                        val prefix = key.substring(0, i)
                        prefixIndexWordGen[prefix]?.remove(key)
                        prefixIndexRootGen.getOrPut(prefix) { mutableSetOf() }.add(key)
                    }
                } else if (existing == null) {
                    currData.suggMap[key] = SuggestionMeta(isRoot, mutableSetOf(d))

                    if (isRoot) currData.allRootKeys.add(key) else currData.allWordKeys.add(key)

                    for (i in 1..minOf(PREFIX_MAX_LEN, key.length)) {
                        val prefix = key.substring(0, i)
                        if (isRoot) {
                            prefixIndexRootGen.getOrPut(prefix) { mutableSetOf() }.add(key)
                        } else {
                            prefixIndexWordGen.getOrPut(prefix) { mutableSetOf() }.add(key)
                        }
                    }
                } else {
                    existing.dicts.add(d)
                }
            }
        }

        for ((prefix, keys) in prefixIndexRootGen) {
            currData.prefixIndex[prefix] = keys.take(SEARCH_SUGGESTIONS_LIMIT)
        }

        for ((prefix, keys) in prefixIndexWordGen) {
            val willTake = SEARCH_SUGGESTIONS_LIMIT - (currData.prefixIndex[prefix]?.size ?: 0)
            if (willTake <= 0) continue
            currData.prefixIndex[prefix] = (currData.prefixIndex[prefix].orEmpty()) + keys.take(willTake)
        }

        return currData
    }

    private fun saveCache(context: Context, currData: SuggDatas) {
        val suggText = currData.suggMap.entries.joinToString("\n") { (key, meta) ->
            "${if (meta.isRoot) "1" else "0"}$SUGG_DATA_SEP${Dict.encode(meta.dicts)}$SUGG_DATA_SEP$key"
        }
        File(context.filesDir, SUGG_CACHE_FILE).writeText(suggText)

        val prefixText = currData.prefixIndex.entries.joinToString("\n") { (prefix, words) ->
            "$prefix$SUGG_DATA_SEP${JSONArray(words)}"
        }
        File(context.filesDir, SUGG_PREFIX_CACHE_FILE).writeText(prefixText)
    }

    private fun loadCache(context: Context): Boolean {
        return try {
            val suggFile = File(context.filesDir, SUGG_CACHE_FILE)
            val prefixFile = File(context.filesDir, SUGG_PREFIX_CACHE_FILE)
            if (!suggFile.exists() || !prefixFile.exists()) return false

            val parsed = SuggDatas()

            for (line in suggFile.readLines()) {
                if (line.isEmpty()) continue
                val parts = line.split(SUGG_DATA_SEP, limit = 3)
                if (parts.size != 3) continue

                val isRoot = parts[0] == "1"
                val dictMask = parts[1].toIntOrNull() ?: continue
                val key = parts[2]

                parsed.suggMap[key] = SuggestionMeta(isRoot, Dict.decode(dictMask).toMutableSet())
                if (isRoot) parsed.allRootKeys.add(key) else parsed.allWordKeys.add(key)
            }

            for (line in prefixFile.readLines()) {
                if (line.isEmpty()) continue
                val idx = line.indexOf(SUGG_DATA_SEP)
                if (idx < 0) continue
                val prefix = line.substring(0, idx)
                val jsonArr = JSONArray(line.substring(idx + 1))
                parsed.prefixIndex[prefix] = List(jsonArr.length()) { jsonArr.getString(it) }
            }

            if (parsed.isEmpty) return false

            data = parsed
            true
        } catch (e: Exception) {
            false
        }
    }
}
