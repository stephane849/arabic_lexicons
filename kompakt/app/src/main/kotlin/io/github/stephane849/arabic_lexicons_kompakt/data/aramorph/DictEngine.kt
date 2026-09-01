package io.github.stephane849.arabic_lexicons_kompakt.data.aramorph

import android.content.Context
import java.io.BufferedReader
import java.io.InputStreamReader

data class ArEnEntry(val root: String, val word: String, val def: String)

private data class Entry(
    val root: String,
    val word: String,
    val morph: String,
    val def: String,
    val isVerb: Boolean,
)

private enum class DictPos { PRE, DEF, SUFF }

/**
 * Port of `lib/lex/dicts/ar_en/ar_en.dart`'s `DictEngine`: the
 * prefix/stem/suffix segmentation + AB/AC/BC grammar-table algorithm,
 * running on Tim Buckwalter's Aramorph tables. The original runs this in a
 * Dart isolate; here it's just plain Kotlin invoked from a background
 * coroutine (see AraMorphEngine.init).
 */
class DictEngine {
    private lateinit var dictPref: Map<String, List<Entry>>
    private lateinit var dictStems: Map<String, List<Entry>>
    private lateinit var dictSuff: Map<String, List<Entry>>
    private lateinit var tableAB: Map<String, List<String>>
    private lateinit var tableAC: Map<String, List<String>>
    private lateinit var tableBC: Map<String, List<String>>

    fun init(context: Context) {
        val assets = context.assets
        dictPref = loadDict(readLatin1(assets, "ar_en/dictprefixes"), DictPos.PRE)
        dictStems = loadDict(readLatin1(assets, "ar_en/dictstems"), DictPos.DEF)
        dictSuff = loadDict(readLatin1(assets, "ar_en/dictsuffixes"), DictPos.SUFF)
        tableAB = loadTable(readLatin1(assets, "ar_en/tableab"))
        tableAC = loadTable(readLatin1(assets, "ar_en/tableac"))
        tableBC = loadTable(readLatin1(assets, "ar_en/tablebc"))
    }

    fun findWords(words: String): List<ArEnEntry> {
        val res = mutableListOf<ArEnEntry>()
        for (w in words.split("_")) {
            if (w.isEmpty()) continue
            res.addAll(findWord(w))
        }
        return res
    }

    fun findWord(w: String, check: Boolean = false): List<ArEnEntry> {
        val res = mutableListOf<ArEnEntry>()

        for (i in w.indices) {
            for (j in (i + 1)..w.length) {
                val pref = w.substring(0, i)
                val prf = dictPref[pref] ?: continue
                if (prf.isEmpty()) continue

                val stem = w.substring(i, j)
                val stm = dictStems[stem] ?: continue
                if (stm.isEmpty()) continue

                val suff = w.substring(j, w.length)
                val suf = dictSuff[suff] ?: continue
                if (suf.isEmpty()) continue

                for (p in prf) {
                    for (s in stm) {
                        for (su in suf) {
                            if (!obeysGrammar(p.morph, s.morph, su.morph)) continue

                            val r = ArEnEntry(
                                root = s.root,
                                word = p.word + s.word + su.word,
                                def = formatDef(p.def, s.def, su.def, su.isVerb),
                            )

                            if (check) return listOf(r)
                            res.add(r)
                        }
                    }
                }
            }
        }

        return res
    }

    private fun obeysGrammar(pref: String, stem: String, suff: String): Boolean {
        if (!(tableAB[pref]?.contains(stem) ?: false)) return false
        if (!(tableBC[stem]?.contains(suff) ?: true)) return false
        if (!(tableAC[pref]?.contains(suff) ?: true)) return false
        return true
    }
}

private fun readLatin1(assets: android.content.res.AssetManager, path: String): String {
    assets.open(path).use { input ->
        BufferedReader(InputStreamReader(input, Charsets.ISO_8859_1)).use { reader ->
            return reader.readText()
        }
    }
}

private fun loadDict(fileContent: String, dp: DictPos): Map<String, List<Entry>> {
    val dict = mutableMapOf<String, MutableList<Entry>>()

    var root = ""
    var rootTransliterated = false

    for (rawLine in fileContent.lineSequence()) {
        val line = rawLine
        when {
            line.trim() == ";" -> {
                root = ""
                rootTransliterated = false
            }
            line.startsWith(";--- ") -> {
                root = line.split(" ")[1]
                rootTransliterated = false
            }
            line.startsWith("; form") -> {
                // family label — not used further down the line, matching original
            }
            !line.startsWith(";") && line.isNotEmpty() -> {
                val parts = line.split("\t")
                if (parts.size < 4) continue
                val key = bukToArabic(parts[0])

                if (root.isNotEmpty() && !rootTransliterated) {
                    root = bukToArabic(root)
                    rootTransliterated = true
                }
                val word = bukToArabic(parts[1])
                val (def, isVerb) = formatDictDef(dp, parts[3])

                val e = Entry(root = root, word = word, morph = parts[2], def = def, isVerb = isVerb)
                dict.getOrPut(key) { mutableListOf() }.add(e)
            }
        }
    }
    return dict
}

private fun loadTable(fileContent: String): Map<String, List<String>> {
    val table = mutableMapOf<String, MutableList<String>>()
    for (line in fileContent.lineSequence()) {
        if (line.isEmpty() || line.startsWith(";")) continue
        val parts = line.split(" ")
        if (parts.size == 2) {
            table.getOrPut(parts[0]) { mutableListOf() }.add(parts[1])
        }
    }
    return table
}

private fun formatDef(pre: String, stem: String, suf: String, isVerb: Boolean): String {
    val res = StringBuilder(pre)
    if (isVerb) {
        res.append(suf.replaceFirst("<verb>", stem))
    } else {
        res.append(stem)
        res.append(suf)
    }
    return res.toString()
}

private fun formatDictDef(dp: DictPos, rawDef: String): Pair<String, Boolean> {
    val def = rawDef.trim()
    if (def.isEmpty()) return "" to false

    return when (dp) {
        DictPos.PRE -> {
            val res = "[${def.split("<pos>")[0].trim()}] "
            res to false
        }

        DictPos.DEF -> {
            val res = def.split("<pos>")[0].trim().replace(";", ", ")
            res to false
        }

        DictPos.SUFF -> {
            val res = StringBuilder()
            val subDef = def.split("<pos>")[0].trim()
            if (subDef.contains("<verb>")) {
                val parts = subDef.split("<verb>")
                res.append("[${parts[0].trim()}] <verb>")
                if (parts.size > 1 && parts[1].trim().isNotEmpty()) {
                    res.append(" [${parts[1].trim()}]")
                }
                return res.toString() to true
            }
            res.append(" [$subDef]")
            res.toString() to false
        }
    }
}
