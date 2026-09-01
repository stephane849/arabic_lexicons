package io.github.stephane849.arabic_lexicons_kompakt.ui.nav

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.data.LexiconRepository
import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow
import io.github.stephane849.arabic_lexicons_kompakt.data.store.WordStore
import io.github.stephane849.arabic_lexicons_kompakt.data.suggest.SuggestionEntry
import kotlinx.coroutines.launch

/**
 * Holds the app's working state: which dictionary is selected, the current
 * search query/results, search suggestions, the Reader Mode text buffer
 * (see PORTING.md — this port keeps one in-memory buffer instead of the
 * original's on-disk multi-book library), and bookmark refresh signaling.
 */
class AppViewModel(application: Application) : AndroidViewModel(application) {
    var isReady by mutableStateOf(false)
        private set

    var selectedDict by mutableStateOf(Dict.HANSWEHR)
    var query by mutableStateOf("")
    var results by mutableStateOf<List<DbRow>>(emptyList())
        private set
    var suggestions by mutableStateOf<Map<Dict, Set<SuggestionEntry>>>(emptyMap())
        private set
    var isSearching by mutableStateOf(false)
        private set

    /** Reader Mode's single working buffer — paste text, read it, done. */
    var readerText by mutableStateOf("")

    var bookmarksVersion by mutableStateOf(0)
        private set

    init {
        viewModelScope.launch {
            LexiconRepository.init(application)
            isReady = true
        }
    }

    fun onQueryChange(newQuery: String) {
        query = newQuery
        if (newQuery.isBlank()) {
            suggestions = emptyMap()
            return
        }
        viewModelScope.launch {
            suggestions = LexiconRepository.suggestions(newQuery)
        }
    }

    fun search(dict: Dict = selectedDict, word: String = query) {
        if (word.isBlank()) return
        selectedDict = dict
        query = word
        isSearching = true
        viewModelScope.launch {
            results = LexiconRepository.search(dict, word)
            isSearching = false
            WordStore.histAdd(dict, word)
        }
    }

    fun toggleBookmark(word: String) {
        if (WordStore.isBm(word)) WordStore.rmBm(word) else WordStore.addBm(word)
        bookmarksVersion++
    }
}
