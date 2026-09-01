package io.github.stephane849.arabic_lexicons_kompakt

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import io.github.stephane849.arabic_lexicons_kompakt.data.Dict
import io.github.stephane849.arabic_lexicons_kompakt.ui.nav.AppViewModel
import io.github.stephane849.arabic_lexicons_kompakt.ui.screens.BookmarksScreen
import io.github.stephane849.arabic_lexicons_kompakt.ui.screens.HomeScreen
import io.github.stephane849.arabic_lexicons_kompakt.ui.screens.ReaderScreen
import io.github.stephane849.arabic_lexicons_kompakt.ui.screens.SearchScreen
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.KompaktTheme

private object Routes {
    const val HOME = "home"
    const val SEARCH = "search"
    const val READER = "reader"
    const val BOOKMARKS = "bookmarks"
}

class MainActivity : ComponentActivity() {
    private val viewModel: AppViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            KompaktTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    if (viewModel.isReady) {
                        AppNavHost(viewModel)
                    } else {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AppNavHost(viewModel: AppViewModel) {
    val navController: NavHostController = rememberNavController()

    NavHost(navController = navController, startDestination = Routes.HOME) {
        composable(Routes.HOME) {
            HomeScreen(
                onOpenSearch = { dict ->
                    viewModel.selectedDict = dict
                    navController.navigate(Routes.SEARCH)
                },
                onOpenReader = { navController.navigate(Routes.READER) },
                onOpenBookmarks = { navController.navigate(Routes.BOOKMARKS) },
            )
        }

        composable(Routes.SEARCH) {
            SearchScreen(
                selectedDict = viewModel.selectedDict,
                query = viewModel.query,
                results = viewModel.results,
                suggestions = viewModel.suggestions,
                bookmarksVersion = viewModel.bookmarksVersion,
                onDictChange = { viewModel.selectedDict = it },
                onQueryChange = { viewModel.onQueryChange(it) },
                onSearch = { dict, word -> viewModel.search(dict, word) },
                onToggleBookmark = { viewModel.toggleBookmark(it) },
                onBack = { navController.popBackStack() },
            )
        }

        composable(Routes.READER) {
            ReaderScreen(
                text = viewModel.readerText,
                onTextChange = { viewModel.readerText = it },
                onBack = { navController.popBackStack() },
            )
        }

        composable(Routes.BOOKMARKS) {
            BookmarksScreen(
                bookmarksVersion = viewModel.bookmarksVersion,
                onOpenWord = { word ->
                    viewModel.selectedDict = Dict.HANSWEHR
                    viewModel.search(Dict.HANSWEHR, word)
                    navController.navigate(Routes.SEARCH)
                },
                onBack = { navController.popBackStack() },
            )
        }
    }
}
