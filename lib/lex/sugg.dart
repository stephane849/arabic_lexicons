import 'package:ara_dict/data.dart';
import 'package:ara_dict/db.dart';
import 'package:flutter/foundation.dart';

class SearchSuggestions {
  static final Map<String, Set<Dict>> _suggMap = {};
  static final List<String> _allKeys = [];
  static final Map<String, List<String>> _prefixIndex = {};

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    int totalPrefixses = 0;
    for (final d in allDictsExpeptArEn) {
      final list = await DbService.getSearchSuggestionList(d);

      for (final key in list) {
        final existing = _suggMap[key];
        if (existing == null) {
          _suggMap[key] = {d};
          _allKeys.add(key);

          // build prefix index
          for (int i = 1; i < 4 && i <= key.length; i++) {
            final prefix = key.substring(0, i);
            final bucket = _prefixIndex[prefix];
            if (bucket == null) {
              totalPrefixses++;
              _prefixIndex[prefix] = [key];
            } else {
              totalPrefixses++;
              bucket.add(key);
            }
          }
        } else {
          existing.add(d);
        }
      }
    }

    if (kDebugMode) { debugPrint('Total words indexed for searchSuggesstion');
      debugPrint('Total words indexed for _suggMap: ${_suggMap.length}');
      debugPrint('Total words indexed for _allKeys: ${_allKeys.length}');
      debugPrint(
        'Total words indexed for _prefixIndex: ${_prefixIndex.length} -> $totalPrefixses',
      );

      // final sorted = List<String>.from(_allKeys)
      //   ..sort((a, b) => b.length.compareTo(a.length));

      // for (int i = 0; i < 50 && i < sorted.length; i++) {
      //   debugPrint('$i. ${sorted[i].length} --> ${sorted[i]}');
      // }

      // File(
      //   '/tmp/soreted.txt',
      // ).writeAsString(sorted.map((i) => '${i.length} --> $i').join("\n"));
      // debugPrint('Biggest key -> ${sorted.first.length} --> ${sorted.first}');
    }
    _initialized = true;
  }

  static bool directMatch(String query, Dict d) {
    return _suggMap[query]?.contains(d) ?? false;
  }

  static Map<Dict, Set<String>> getSuggestions(String query, {int limit = 10}) {
    if (query.isEmpty) return {};
    final Map<Dict, Set<String>> results = {};
    final Set<String> addedWords = {};
    int count = 0;

    void tryAdd(String word) {
      if (count >= limit) return;
      if (!addedWords.add(word)) return;

      final dicts = _suggMap[word];
      if (dicts == null) return;

      for (final d in dicts) {
        results.putIfAbsent(d, () => <String>{}).add(word);
      }

      count++;
    }

    // 1️⃣ Exact match
    if (_suggMap.containsKey(query)) {
      tryAdd(query);
    }

    if (count >= limit) return results;

    // 2️⃣ Prefix match
    final prefixList = _prefixIndex[query];
    if (prefixList != null) {
      for (final word in prefixList) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    if (count >= limit) return results;

    // 3️⃣ Contains match
    for (final word in _allKeys) {
      if (word.contains(query)) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    return results;
  }
}
