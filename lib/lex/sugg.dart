import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lex/sugg_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const int searchSuggestionsLimit = 10;
const String suggDataSep = '#';

class SearchSuggestions {
  // static final Map<String, SuggestionMeta> _suggMap = {};
  // static final List<String> _allRootKeys = [];
  // static final List<String> _allWordKeys = [];
  // static final Map<String, List<String>> _prefixIndex = {};
  static var _datas = SuggDatas.empty();

  static bool _initialized = false;

  static bool get isInitalized {
    return _initialized;
  }

  static bool get shouldShow {
    return _initialized && appSettingsNotifier.showSearchSugg;
  }

  static Future<void> init() async {
    if (_initialized || !appSettingsNotifier.showSearchSugg) return;

    // _initialized = await _loadCache();
    if (_initialized) return;

    final wordList = await Future.wait(
      allDictsExpeptArEn.map(
        (d) async => (d, await DbService.getSearchSuggestionList(d)),
      ),
    );

    // final list = await DbService.getSearchSuggestionList(d);
    final res = await Isolate.run(() async {
      return await initSuggetions(wordList);
    });
    if (res.isEmpty) return;
    _datas = res;
    _initialized = true;

    final cacheDir = await getApplicationCacheDirectory();
    await Isolate.run(() async {
      return await _saveCache(cacheDir.path, _datas);
    });
  }

  static bool directMatch(String query, Dict d) {
    return _datas.suggMap[query]?.dicts.contains(d) ?? false;
  }

  static Map<Dict, Set<String>> getSuggestions(String query) {
    if (query.isEmpty) return {};
    final Map<Dict, Set<String>> results = {};
    final Set<String> addedWords = {};
    int count = 0;

    const limit = searchSuggestionsLimit;
    void tryAdd(String word) {
      if (count >= limit) return;
      if (!addedWords.add(word)) return;

      final sm = _datas.suggMap[word];
      if (sm == null) return;

      for (final d in sm.dicts) {
        results.putIfAbsent(d, () => <String>{}).add(word);
      }

      count++;
    }

    // Exact match
    if (_datas.suggMap.containsKey(query)) {
      tryAdd(query);
    }

    if (count >= limit) return results;

    // Prefix match
    final prefixList = _datas.prefixIndex[query];
    if (prefixList != null) {
      for (final word in prefixList) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    if (count >= limit) return results;

    // Contains match
    for (final word in _datas.allRootKeys) {
      if (word.contains(query)) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    if (count >= limit) return results;

    for (final word in _datas.allWordKeys) {
      if (word.contains(query)) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    return results;
  }

  static const String _suggSaveFileName = 'sugg_data.txt';
  static const String _suggPrefixSaveFileName = 'sugg_prefix.txt';

  static Future<void> _saveCache(String cacheDir, SuggDatas currDatas) async {
    if (!_initialized) return;

    Stopwatch? sw;
    if (kDebugMode) sw = Stopwatch()..start();

    final data = currDatas.suggMap.entries
        .map(
          (v) =>
              '${v.value.isRoot ? "1" : "0"}'
              '$suggDataSep${encode(v.value.dicts)}$suggDataSep${v.key}',
        )
        .join('\n');

    File(join(cacheDir, _suggSaveFileName)).writeAsString(data);

    final prefixData = currDatas.prefixIndex.entries
        .map((v) => '${v.key}$suggDataSep${jsonEncode(v.value)}')
        .join('\n');

    File(join(cacheDir, _suggPrefixSaveFileName)).writeAsString(prefixData);

    if (kDebugMode) {
      debugPrint('sugg_db saved in ${sw?.elapsedMilliseconds}ms');
    }
  }

  static Future<bool> _loadCache() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final suggData = await File(
        join(cacheDir.path, _suggSaveFileName),
      ).readAsLines();
      final prefixData = await File(
        join(cacheDir.path, _suggPrefixSaveFileName),
      ).readAsLines();

      // Parse in background isolate
      final parsed = await Isolate.run(() {
        return parseCacheDatas(suggData, prefixData);
      });

      if (parsed.suggMap.isEmpty || parsed.prefixIndex.isEmpty) return false;

      _datas = parsed;
      return true;
    } catch (e) {
      return false;
    }

    // if (_suggMap.isEmpty || _prefixIndex.isEmpty) {
    //   _clearAll();
    //   return false;
    // }
    // if (kDebugMode) {
    //   sw?.stop();
    //   debugPrint(
    //     'sugg_db loaded from chache in ${sw?.elapsedMilliseconds}ms or ${sw?.elapsed.inSeconds}s',
    //   );
    // }
    // return true;
  }
}

class SuggestionMeta {
  final bool isRoot;
  final Set<Dict> dicts;

  SuggestionMeta(this.isRoot, this.dicts);
}
