package io.github.stephane849.arabic_lexicons_kompakt.ui.nav

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.TextFieldValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import io.github.stephane849.arabic_lexicons_kompakt.data.ArabicText
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.data.LexiconRepository
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow
import io.github.stephane849.arabic_lexicons_kompakt.data.store.WordStore
import io.github.stephane849.arabic_lexicons_kompakt.data.suggest.SuggestionEntry
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private const val SEARCH_DEBOUNCE_MS = 200L

/**
 * Port of `SearchLexiconsDatas` + `onTextChanged` from the Flutter app.
 *
 * The search model is the original's, and the order matters: a lookup runs
 * against the *selected* dictionary first, and only when that comes back
 * empty does it fall back to suggestions — which are grouped per
 * dictionary, so picking one switches word and dictionary together. That
 * is the app's core flow: search a word, then choose the dictionary.
 */
class AppViewModel(application: Application) : AndroidViewModel(application) {
    var isReady by mutableStateOf(false)
        private set

    /** Held as a [TextFieldValue] because the caret picks the searched word. */
    var query by mutableStateOf(TextFieldValue(""))
        private set

    var words by mutableStateOf<List<String>>(emptyList())
        private set
    var selectedWord by mutableStateOf("")
        private set
    var selectedDict by mutableStateOf(Dict.HANSWEHR)
        private set

    var results by mutableStateOf<List<DbRow>>(emptyList())
        private set
    var resLoaded by mutableStateOf(false)
        private set

    var isShowingSugg by mutableStateOf(false)
        private set
    var suggestions by mutableStateOf<Map<Dict, Set<SuggestionEntry>>>(emptyMap())
        private set

    /** Dictionary order for the suggestion list — selected one first. */
    var suggDictSorted by mutableStateOf<List<Dict>>(emptyList())
        private set

    /** Reader Mode's single working buffer — paste text, read it, done. */
    var readerText by mutableStateOf("")

    var bookmarksVersion by mutableStateOf(0)
        private set

    private var searchJob: Job? = null
    private var debounceJob: Job? = null

    init {
        viewModelScope.launch {
            LexiconRepository.init(application)
            isReady = true
        }
    }

    // -- Query handling ----------------------------------------------------

    fun onQueryChange(newValue: TextFieldValue) {
        val textChanged = newValue.text != query.text
        query = newValue

        if (!textChanged) {
            // Caret moved without an edit: the word under it may have
            // changed, which is a new lookup (the original does this from
            // the field's onTap).
            applyQuery()
            return
        }

        debounceJob?.cancel()
        debounceJob = viewModelScope.launch {
            delay(SEARCH_DEBOUNCE_MS)
            applyQuery()
        }
    }

    fun clearQuery() {
        debounceJob?.cancel()
        searchJob?.cancel()
        query = TextFieldValue("")
        resetAll()
    }

    private fun applyQuery() {
        val (parts, currWord) = ArabicText.getNextWord(query.text.trim(), query.selection.start)

        if (currWord == selectedWord) {
            if (parts.size != words.size) words = parts
            return
        }

        if (currWord == null) {
            resetAll()
            return
        }

        words = parts
        selectedWord = currWord
        getAndShowResOrSugg()
    }

    // -- Lookup ------------------------------------------------------------

    /**
     * Port of `getAndShowResORSugg`: run the lookup, and when it comes back
     * empty fall through to suggestions instead of a dead end.
     */
    fun getAndShowResOrSugg(forceSugg: Boolean = false, forceRes: Boolean = false) {
        require(!(forceSugg && forceRes)) { "Can not have both forceSugg and forceRes == true" }

        searchJob?.cancel()
        resetLoadedValues()

        if (selectedWord.isEmpty()) {
            resLoaded = true
            return
        }

        searchJob = viewModelScope.launch {
            if (forceSugg) {
                loadSuggestions()
                return@launch
            }

            val res = LexiconRepository.search(selectedDict, selectedWord)
            results = res
            resLoaded = true

            if (res.isNotEmpty()) {
                WordStore.histAdd(selectedDict, selectedWord)
                return@launch
            }

            if (forceRes) return@launch

            loadSuggestions()
        }
    }

    private suspend fun loadSuggestions() {
        suggestions = LexiconRepository.suggestions(selectedWord)
        suggDictSorted = listOf(selectedDict) + Dict.ALL.filter { it != selectedDict }
        isShowingSugg = true
    }

    /** App-bar toggle between the result view and the suggestion view. */
    fun toggleSuggestions() {
        if (selectedWord.isEmpty()) return
        val showing = isShowingSugg
        getAndShowResOrSugg(forceSugg = !showing, forceRes = showing)
    }

    // -- Selection ---------------------------------------------------------

    /**
     * A suggestion carries both a word and the dictionary it was found in,
     * so accepting one switches to that dictionary and rewrites the query's
     * selected word in place, keeping any other words the user typed.
     */
    fun onSuggestionPicked(word: String, dict: Dict) {
        if (word != selectedWord) {
            val rewritten = LinkedHashSet(words.map { if (it == selectedWord) word else it })
            // Move the picked word last so the caret lands on it.
            rewritten.remove(word)
            rewritten.add(word)
            words = rewritten.toList()

            val text = rewritten.joinToString(" ")
            query = TextFieldValue(text, TextRange(text.length))
            selectedWord = word
        }

        if (selectedDict != dict) {
            selectedDict = dict
            suggDictSorted = emptyList()
        }

        isShowingSugg = false
        getAndShowResOrSugg(forceRes = true)
    }

    /** Picking a dictionary for the word already being looked up. */
    fun selectDict(dict: Dict) {
        if (dict == selectedDict) return
        selectedDict = dict
        suggDictSorted = emptyList()
        getAndShowResOrSugg(forceRes = true)
    }

    /** Picking a different word out of a multi-word query. */
    fun selectWord(word: String) {
        if (word == selectedWord) return
        selectedWord = word
        getAndShowResOrSugg(forceRes = true)
    }

    /** Opening a word from elsewhere in the app (bookmarks, reader). */
    fun openWord(word: String, dict: Dict = selectedDict) {
        selectedDict = dict
        selectedWord = word
        words = listOf(word)
        query = TextFieldValue(word, TextRange(word.length))
        suggDictSorted = emptyList()
        getAndShowResOrSugg(forceRes = true)
    }

    // -- Bookmarks ---------------------------------------------------------

    fun isBookmarked(word: String): Boolean = WordStore.isBm(word)

    fun toggleBookmark(word: String) {
        if (word.isEmpty()) return
        if (WordStore.isBm(word)) WordStore.rmBm(word) else WordStore.addBm(word)
        bookmarksVersion++
    }

    fun removeBookmark(word: String) {
        WordStore.rmBm(word)
        bookmarksVersion++
    }

    // -- Reset -------------------------------------------------------------

    private fun resetLoadedValues() {
        suggestions = emptyMap()
        isShowingSugg = false
        resLoaded = false
        results = emptyList()
    }

    private fun resetAll() {
        resetLoadedValues()
        words = emptyList()
        selectedWord = ""
    }
}
