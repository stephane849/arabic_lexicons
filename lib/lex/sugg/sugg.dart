import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/sugg/sugg_isolate.dart';
import 'package:ara_dict/lex/sugg_cache.dart';
import 'package:ara_dict/utils.dart';
import 'package:path_provider/path_provider.dart';

const int searchSuggestionsLimit = 10;
const String suggDataSep = '#';

class SearchSuggestions {
  static bool _initialized = false;
  static late final SuggIsolate _eng;

  static bool get isInitalized {
    return _initialized;
  }

  static bool get shouldShow {
    return _initialized && appSettingsNotifier.showSearchSugg;
  }

  static Future<void> init() async {
    if (_initialized || !appSettingsNotifier.showSearchSugg) return;
    _eng = SuggIsolate();
    await _eng.spwan();
    await _eng.init((await getApplicationCacheDirectory()).path);
    _initialized = true;
  }

  static final _cache = LruCache<String, SuggestionEntries>(100);

  static Future<SuggestionEntries> getSuggestions(String query) async {
    final c = _cache.get(query);
    if (c != null) return c;

    if (!_initialized) return {};
    final res = await _eng.search(query);

    _cache.put(query, res.results);
    return res.results;
  }
}
