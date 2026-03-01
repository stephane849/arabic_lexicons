import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/db.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const int searchSuggestionsLimit = 10;
const String suggDataSep = '#';

class SearchSuggestions {
  static final Map<String, SuggestionMeta> _suggMap = {};
  static final List<String> _allRootKeys = [];
  static final List<String> _allWordKeys = [];
  static final Map<String, List<String>> _prefixIndex = {};

  static bool _initialized = false;

  static bool get isInitalized {
    return _initialized;
  }

  static bool get shouldShow {
    return _initialized && appSettingsNotifier.showSearchSugg;
  }

  static final _prefixMaxLen = 3;

  static Future<void> init() async {
    if (_initialized || !appSettingsNotifier.showSearchSugg) return;
    if (await _loadCache()) {
      _initialized = true;
      return;
    }

    final Map<String, Set<String>> prefixIndexRootGen = {};
    final Map<String, Set<String>> prefixIndexWordGen = {};
    Stopwatch? sw;
    if (kDebugMode) sw = Stopwatch()..start();
    int totalPrefixses = 0;
    int totalPrefixsActual = 0;

    for (final d in allDictsExpeptArEn) {
      final list = await DbService.getSearchSuggestionList(d);

      for (final (key, isRoot) in list) {
        final existing = _suggMap[key];

        if (existing != null && !existing.isRoot && isRoot) {
          _suggMap[key] = SuggestionMeta(true, existing.dicts);
          _allRootKeys.add(key);
          _allWordKeys.remove(key);

          for (int i = 1; i <= _prefixMaxLen && i <= key.length; i++) {
            final prefix = key.substring(0, i);
            final wBucket = prefixIndexWordGen[prefix] ?? <String>{};
            if (wBucket.isNotEmpty) wBucket.remove(key);
            prefixIndexWordGen[prefix] = wBucket;

            final rBucket = prefixIndexRootGen[prefix] ?? <String>{};
            rBucket.add(key);
            prefixIndexRootGen[prefix] = rBucket;
          }
        } else if (existing == null) {
          _suggMap[key] = SuggestionMeta(isRoot, {d});

          if (isRoot) {
            _allRootKeys.add(key);
          } else {
            _allWordKeys.add(key);
          }

          // build prefix index
          for (int i = 1; i <= _prefixMaxLen && i <= key.length; i++) {
            final prefix = key.substring(0, i);
            bool added = false;
            if (isRoot) {
              final rBucket = prefixIndexRootGen[prefix] ?? <String>{};
              added = rBucket.add(key);
              prefixIndexRootGen[prefix] = rBucket;
            } else {
              final wBucket = prefixIndexWordGen[prefix] ?? <String>{};
              added = wBucket.add(key);
              prefixIndexWordGen[prefix] = wBucket;
            }
            if (added) totalPrefixses++;
          }
        } else {
          existing.dicts.add(d);
        }
      }
    }

    for (final e in prefixIndexRootGen.entries) {
      final add = e.value.take(searchSuggestionsLimit).toList();
      totalPrefixsActual += add.length;
      _prefixIndex[e.key] = add;
    }

    for (final e in prefixIndexWordGen.entries) {
      final willTake =
          searchSuggestionsLimit - (_prefixIndex[e.key]?.length ?? 0);

      if (willTake <= 0) continue;

      final add = e.value.take(willTake).toList();
      totalPrefixsActual += add.length;
      _prefixIndex[e.key] = add;
    }

    if (kDebugMode) {
      debugPrint('Total words indexed for searchSuggesstion');
      debugPrint('Total words indexed for _suggMap: ${_suggMap.length}');
      debugPrint(
        'Total words indexed for _allRootKeys: ${_allRootKeys.length}',
      );
      debugPrint(
        'Total words indexed for _allWordKeys: ${_allWordKeys.length}',
      );
      debugPrint(
        'Total words indexed for _all__Keys: ${_allWordKeys.length + _allRootKeys.length}',
      );
      debugPrint(
        'Total words indexed for prefixIndexGen: ${_prefixIndex.length} -> $totalPrefixses',
      );
      debugPrint(
        'Total words indexed for _prefixIndex: ${_prefixIndex.length} -> $totalPrefixsActual',
      );
      debugPrint(
        'Total words indexed for _prefixIndex diff: ${totalPrefixsActual - _prefixIndex.length}',
      );

      sw?.stop();
      debugPrint('Took: ${sw?.elapsedMilliseconds}ms');

      final sorted = List<String>.from(_allRootKeys)
        ..sort((a, b) => b.length.compareTo(a.length));

      // for (int i = 0; i < 50 && i < sorted.length; i++) {
      //   debugPrint('$i. ${sorted[i].length} --> ${sorted[i]}');
      // }

      File(
        '/tmp/soreted.txt',
      ).writeAsString(sorted.map((i) => '${i.length} --> $i').join("\n"));
      debugPrint('Biggest key -> ${sorted.first.length} --> ${sorted.first}');
    }
    _initialized = true;
    await saveToDb();
  }

  static bool directMatch(String query, Dict d) {
    return _suggMap[query]?.dicts.contains(d) ?? false;
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

      final sm = _suggMap[word];
      if (sm == null) return;

      for (final d in sm.dicts) {
        results.putIfAbsent(d, () => <String>{}).add(word);
      }

      count++;
    }

    // Exact match
    if (_suggMap.containsKey(query)) {
      tryAdd(query);
    }

    if (count >= limit) return results;

    // Prefix match
    final prefixList = _prefixIndex[query];
    if (prefixList != null) {
      for (final word in prefixList) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    if (count >= limit) return results;

    // Contains match
    for (final word in _allRootKeys) {
      if (word.contains(query)) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    if (count >= limit) return results;

    for (final word in _allWordKeys) {
      if (word.contains(query)) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    return results;
  }

  static void _clearAll() {
    _suggMap.clear();
    _prefixIndex.clear();
    _allRootKeys.clear();
    _allWordKeys.clear();
  }

  static const String _suggSaveFileName = 'sugg_data.txt';
  static const String _suggPrefixSaveFileName = 'sugg_prefix.txt';

  static Future<void> saveToDb() async {
    if (!_initialized) return;
    final cacheDir = await getApplicationCacheDirectory();

    Stopwatch? sw;
    if (kDebugMode) sw = Stopwatch()..start();

    final data = _suggMap.entries
        .map(
          (v) =>
              '${v.value.isRoot ? "1" : "0"}'
              '$suggDataSep${encode(v.value.dicts)}$suggDataSep${v.key}',
        )
        .join('\n');

    File(join(cacheDir.path, _suggSaveFileName)).writeAsString(data);

    final prefixData = _prefixIndex.entries
        .map((v) => '${v.key}$suggDataSep${jsonEncode(v.value)}')
        .join('\n');

    File(
      join(cacheDir.path, _suggPrefixSaveFileName),
    ).writeAsString(prefixData);

    if (kDebugMode) {
      debugPrint('sugg_db saved in ${sw?.elapsedMilliseconds}ms');
    }
  }

  static Future<bool> _loadCache() async {
    Stopwatch? sw;
    if (kDebugMode) sw = Stopwatch()..start();
    _clearAll();

    final cacheDir = await getApplicationCacheDirectory();
    try {
      var file = File(join(cacheDir.path, _suggSaveFileName));
      if (!await file.exists()) return false;
      var lines = await file.readAsLines();

      for (final l in lines) {
        final datas = l.split(suggDataSep);
        if (datas.length != 3) {
          if (kDebugMode) debugPrint('malformedline $l');
          continue;
        }

        final key = datas[2];
        final isRoot = datas[0] == '1';
        final dictTables = int.parse(datas[1]);

        _suggMap[key] = SuggestionMeta(isRoot, decode(dictTables));
        if (isRoot) {
          _allRootKeys.add(key);
        } else {
          _allWordKeys.add(key);
        }
      }

      file = File(join(cacheDir.path, _suggPrefixSaveFileName));

      lines = await file.readAsLines();

      for (final l in lines) {
        final datas = l.split(suggDataSep);
        if (datas.length != 2) {
          if (kDebugMode) debugPrint('malformedline $l');
          continue;
        }

        final prefix = datas[0];
        // fsw.start();
        final words = List<String>.from(jsonDecode(datas[1]));
        // fsw.stop();

        _prefixIndex[prefix] = words;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('err: $e');
      }
      _clearAll();
      return false;
    }
    if (_suggMap.isEmpty || _prefixIndex.isEmpty) {
      _clearAll();
      return false;
    }
    if (kDebugMode) {
      sw?.stop();
      debugPrint(
        'sugg_db loaded from chache in ${sw?.elapsedMilliseconds}ms or ${sw?.elapsed.inSeconds}s',
      );
    }
    return true;
  }
}

class SuggestionMeta {
  final bool isRoot;
  final Set<Dict> dicts;

  SuggestionMeta(this.isRoot, this.dicts);
}
