package io.github.stephane849.arabic_lexicons_kompakt.data

import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow

/**
 * What a tapped word resolved to: the form that actually matched (which
 * is often not the form that was tapped), the lexicon that answered, and
 * the entries found there.
 */
data class LookupResult(val word: String, val dict: Dict, val entries: List<DbRow>)

/**
 * Looks up a word taken from running text — the reader's pasted passage,
 * or the body of an entry in one of the Arabic lexicons, which define
 * Arabic with Arabic.
 *
 * [preferred] is the reader's chosen lexicon for taps, or null to follow
 * whichever lexicon is open ([selected]). Answering out of the lexicon
 * being read is rarely what a tap wants: Lisan al-Arab explains an Arabic
 * word with more classical Arabic, when the question behind the tap is
 * usually just "what does this mean" — hence the setting, and hence Hans
 * Wehr as its default and as the fallback when the chosen lexicon has
 * nothing.
 *
 * Returns null when the tap wasn't on Arabic at all, which is how a tap
 * on an English word in Hans Wehr quietly does nothing.
 *
 * Order is about precision, not just hit rate: the word as written wins
 * if a lexicon holds it; then simple affix trimming, which lands on the
 * headword itself (الرسالة -> رسالة); and only then Aramorph, which
 * resolves further to the root (-> رسل) and so answers a broader question
 * than was asked. Aramorph is what reaches the inflections nothing else
 * can — يكتبون -> كتب, ربهم -> رب.
 */
suspend fun lookUpWord(selected: Dict, preferred: Dict?, rawWord: String): LookupResult? {
    val word = ArabicText.keepOnlyAr(rawWord)
    if (word.isEmpty()) return null

    val target = preferred ?: selected
    val dicts = if (target == Dict.HANSWEHR) listOf(target) else listOf(target, Dict.HANSWEHR)

    suspend fun firstHit(candidates: List<String>): LookupResult? {
        for (candidate in candidates) {
            for (dict in dicts) {
                val res = LexiconRepository.search(dict, candidate)
                if (res.isNotEmpty()) return LookupResult(candidate, dict, res)
            }
        }
        return null
    }

    firstHit(listOf(word))?.let { return it }
    firstHit(ArabicText.lookupCandidates(word).drop(1))?.let { return it }
    firstHit(LexiconRepository.morphologicalForms(word))?.let { return it }

    return LookupResult(word, target, emptyList())
}
