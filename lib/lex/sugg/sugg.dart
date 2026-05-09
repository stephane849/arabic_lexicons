import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/sugg/isolate.dart';
import 'package:ara_dict/lex/sugg/data.dart';
import 'package:ara_dict/utils.dart';
import 'package:path_provider/path_provider.dart';

const int searchSuggestionsLimit = 10;
const String suggDataSep = '#';

class _SearchSuggestions {
  static bool _initialized = false;
  static late final SuggIsolate _eng;

  static bool get isInitalized {
    return _initialized;
  }

  static bool get shouldShow {
    return _initialized && appConf.showSearchSugg;
  }

  static Future<void> init() async {
    if (_initialized || !appConf.showSearchSugg) return;
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
