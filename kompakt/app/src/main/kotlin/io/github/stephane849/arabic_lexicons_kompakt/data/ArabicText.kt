package io.github.stephane849.arabic_lexicons_kompakt.data

/**
 * Port of the search path's text handling from the Flutter app:
 * `lib/alphabets.dart`'s `ArabicNormalizer.keepOnlyAr`/`keepOnlyArList`
 * and `lib/lex/utils.dart`'s `getNextWord`.
 *
 * The query is a free-text field, but a lookup is always per-word, so the
 * query gets normalized to bare Arabic letters and split into words; the
 * word under the caret is the one that gets looked up.
 */
object ArabicText {
    /** Everything that isn't an Arabic letter or the app's `_` intra-word separator. */
    private val nonArabicLetters = Regex("[^ء-غف-يىةی_]")
    private val multiUnderscore = Regex("_{2,}")
    private val edgeUnderscore = Regex("^_+|_+$")

    /** Farsi ya (ی) normalizes to alef maksura at the end of a word, plain ya elsewhere. */
    private val farsiYaEnd = Regex("ی(?=\\s|$)")
    private const val FARSI_YA = "ی"
    private const val ALEF_MAKSURA = "ى"
    private const val ARABIC_YA = "ي"

    private val whitespace = Regex("\\s+")

    /**
     * Keep only Arabic letters: drops tashkil, symbols, digits and spaces
     * (but keeps `_`), and normalizes Farsi ya.
     */
    fun keepOnlyAr(word: String): String {
        if (word.isEmpty()) return word

        val cleaned = word
            .replace(nonArabicLetters, "")
            .replace(multiUnderscore, "_")
            .replace(edgeUnderscore, "")
            .replace(farsiYaEnd, ALEF_MAKSURA)
            .replace(FARSI_YA, ARABIC_YA)

        return if (cleaned == "_") "" else cleaned
    }

    fun keepOnlyArList(sentence: String): List<String> {
        val trimmed = sentence.trim()
        if (trimmed.isEmpty()) return emptyList()

        return trimmed.split(whitespace).mapNotNull { w ->
            keepOnlyAr(w).ifEmpty { null }
        }
    }

    /**
     * Splits [query] into normalized words and picks the one the caret sits
     * in — that's the word the lexicons get searched for. Returns the word
     * list plus the selected word (null when the query holds no Arabic).
     */
    fun getNextWord(query: String, caret: Int): Pair<List<String>, String?> {
        val q = query.trim()

        if (q.isEmpty()) return emptyList<String>() to null

        if (q.length == caret || !q.contains(" ")) {
            val parts = keepOnlyArList(q)
            return if (parts.isNotEmpty()) parts to parts.last() else parts to null
        }

        val res = mutableListOf<String>()
        var word: String? = null
        var i = 0

        while (i < q.length) {
            while (i < q.length && q[i] == ' ') i++
            if (i >= q.length) break

            val sub = q.substring(i)
            val spaceIdx = sub.indexOf(' ')
            val curWord = if (spaceIdx < 0) sub else sub.substring(0, spaceIdx)
            i += curWord.length
            while (i < q.length && q[i] == ' ') i++

            val cw = keepOnlyAr(curWord)
            if (cw.isNotEmpty()) {
                res.add(cw)
                if (word == null && caret < i) word = cw
            }
        }

        if (res.isNotEmpty() && word == null) word = res.last()

        return res to word
    }
}
