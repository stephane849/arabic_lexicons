package io.github.stephane849.arabic_lexicons_kompakt

import android.os.Bundle
import android.view.KeyEvent
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.mudita.mmd.components.progress_indicator.CircularProgressIndicatorMMD
import io.github.stephane849.arabic_lexicons_kompakt.ui.nav.AppViewModel
import io.github.stephane849.arabic_lexicons_kompakt.ui.screens.BookmarksScreen
import io.github.stephane849.arabic_lexicons_kompakt.ui.screens.ReaderScreen
import io.github.stephane849.arabic_lexicons_kompakt.ui.screens.SearchScreen
import io.github.stephane849.arabic_lexicons_kompakt.ui.screens.VerbFormsScreen
import io.github.stephane849.arabic_lexicons_kompakt.ui.theme.KompaktTheme

private object Routes {
    const val SEARCH = "search"
    const val READER = "reader"
    const val BOOKMARKS = "bookmarks"
    const val VERB_FORMS = "verb_forms"
}

class MainActivity : ComponentActivity() {
    private val viewModel: AppViewModel by viewModels()

    /**
     * The volume keys page the text, the way they do on a dedicated
     * reader — reaching for the screen to scroll is what you want to avoid
     * on E Ink, where every touch-drag repaints.
     *
     * Both down and up are consumed: handling only the down event still
     * lets the framework act on the up event and flash the volume panel.
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean = when (keyCode) {
        KeyEvent.KEYCODE_VOLUME_DOWN -> {
            viewModel.pageScroll(1)
            true
        }

        KeyEvent.KEYCODE_VOLUME_UP -> {
            viewModel.pageScroll(-1)
            true
        }

        else -> super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean = when (keyCode) {
        KeyEvent.KEYCODE_VOLUME_DOWN, KeyEvent.KEYCODE_VOLUME_UP -> true
        else -> super.onKeyUp(keyCode, event)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            KompaktTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    if (viewModel.isReady) {
                        AppNavHost(viewModel)
                    } else {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicatorMMD()
                        }
                    }
                }
            }
        }
    }
}

/**
 * Search is the app itself, not a destination inside it — the same shape
 * as the original Flutter app, which opens on the search screen and keeps
 * Reader and Bookmarks one tap away rather than in front of it.
 */
@Composable
private fun AppNavHost(viewModel: AppViewModel) {
    val navController: NavHostController = rememberNavController()

    NavHost(navController = navController, startDestination = Routes.SEARCH) {
        composable(Routes.SEARCH) {
            SearchScreen(
                viewModel = viewModel,
                onOpenReader = { navController.navigate(Routes.READER) },
                onOpenBookmarks = { navController.navigate(Routes.BOOKMARKS) },
                onOpenVerbForms = { navController.navigate(Routes.VERB_FORMS) },
            )
        }

        composable(Routes.VERB_FORMS) {
            VerbFormsScreen(
                viewModel = viewModel,
                onBack = { navController.popBackStack() },
            )
        }

        composable(Routes.READER) {
            ReaderScreen(
                viewModel = viewModel,
                text = viewModel.readerText,
                onTextChange = { viewModel.readerText = it },
                onBack = { navController.popBackStack() },
            )
        }

        composable(Routes.BOOKMARKS) {
            BookmarksScreen(
                viewModel = viewModel,
                bookmarksVersion = viewModel.bookmarksVersion,
                onOpenWord = { word ->
                    viewModel.openWord(word)
                    navController.popBackStack()
                },
                onRemove = { viewModel.removeBookmark(it) },
                onBack = { navController.popBackStack() },
            )
        }
    }
}
