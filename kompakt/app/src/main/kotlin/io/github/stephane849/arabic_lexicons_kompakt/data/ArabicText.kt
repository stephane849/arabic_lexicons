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
     * A word character for tap purposes: a letter, or a combining mark —
     * Arabic harakat are marks, not letters, and must stay attached or a
     * tap would cut a vocalized word in half.
     */
    private fun isWordChar(c: Char): Boolean =
        c.isLetter() || Character.getType(c) == Character.NON_SPACING_MARK.toInt()

    /**
     * The whole word containing [offset] in [text], as written. Returns it
     * un-normalized: the caller decides whether to normalize, and a caller
     * that gets back an empty string after normalizing knows the tap landed
     * on something that isn't Arabic.
     */
    fun wordAt(text: String, offset: Int): String {
        if (text.isEmpty()) return ""
        val idx = offset.coerceIn(0, text.length - 1)
        if (!isWordChar(text[idx])) return ""

        var start = idx
        while (start > 0 && isWordChar(text[start - 1])) start--
        var end = idx
        while (end < text.length - 1 && isWordChar(text[end + 1])) end++

        return text.substring(start, end + 1)
    }

    /**
     * Clitics that attach to a word in running text but are not part of the
     * headword the lexicons store: the article, the conjunctions and
     * prepositions that fuse to the front, and the attached pronouns.
     * Longest first, so وال is tried before و.
     */
    private val PREFIXES =
        listOf("وبال", "فبال", "وكال", "بال", "كال", "فال", "وال", "لل", "ال", "و", "ف", "ب", "ل", "ك", "س")
    private val SUFFIXES =
        listOf("كما", "هما", "ها", "هم", "هن", "كم", "كن", "نا", "ات", "ون", "ين", "ان", "ه", "ك", "ي")

    /** Arabic roots are three letters; never strip below that. */
    private const val MIN_STEM_LENGTH = 3

    /**
     * The forms to try for a word taken from running text, best first.
     *
     * A lexicon is keyed on headwords, but prose gives you الرجل and وذهب.
     * Stripping the attached article, conjunction or pronoun is what turns
     * a tapped word into something the dictionary actually holds — without
     * it, most taps in a real passage find nothing.
     *
     * This is deliberately shallow morphology: it will not resolve an
     * inflected stem back to its root, which is what the search screen's
     * suggestions are for.
     */
    fun lookupCandidates(word: String): List<String> {
        if (word.isEmpty()) return emptyList()

        val out = LinkedHashSet<String>()
        out.add(word)

        fun stripSuffixes(w: String) {
            for (s in SUFFIXES) {
                if (w.endsWith(s) && w.length - s.length >= MIN_STEM_LENGTH) {
                    out.add(w.dropLast(s.length))
                }
            }
        }

        stripSuffixes(word)

        for (p in PREFIXES) {
            if (!word.startsWith(p) || word.length - p.length < MIN_STEM_LENGTH) continue
            val stem = word.drop(p.length)
            out.add(stem)
            stripSuffixes(stem)
        }

        return out.toList()
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
