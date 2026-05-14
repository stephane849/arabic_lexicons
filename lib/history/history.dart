import 'dart:io';

import 'package:ara_dict/data.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pp;
import 'package:path_provider/path_provider.dart';

class SearchHistItem {
  final String word;
  final Dict dict;

  const SearchHistItem({required this.word, required this.dict});

  @override
  String toString() {
    return '${dict.index}:$word';
  }

  static SearchHistItem? fromString(String str, List<Dict> dicts) {
    final parts = str.split(":");
    if (parts.length != 2) return null;

    if (parts[1].isEmpty) return null;

    final dictIdx = int.tryParse(parts[0]);
    if (dictIdx == null || dictIdx < 0 || dictIdx >= dicts.length) return null;

    return SearchHistItem(word: parts[1], dict: dicts[dictIdx]);
  }
}

class SearchHist {
  static const int _maxSize = 500;

  static late final List<SearchHistItem> _items;

  static bool get isEmpty => _items.isEmpty;
  static bool get isNotEmpty => _items.isNotEmpty;
  static int get length => _items.length;
  static List<SearchHistItem> get items => _items;

  static late final File _file;
  static late final File _tmpFile;

  static bool _inited = false;
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;

    try {
      await _setFiles();
      _items = await _parse();
    } catch (_) {
      _inited = false;
    }
  }

  static Future<void> _setFiles() async {
    final dataDir = await getApplicationDocumentsDirectory();
    _file = File(pp.join(dataDir.path, 'dict_search_hist.txt'));
    _tmpFile = File(pp.join(dataDir.path, 'dict_search_hist_tmp.txt'));
  }

  static Future<bool> _save() async {
    if (!_inited) return false;

    final data = _items.join("\n");
    try {
      await _tmpFile.writeAsString(data);
      await _tmpFile.rename(_file.path);

      if (kDebugMode) debugPrint("searchHist saved: ${_file.path}");

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("while saving searchHist: $e");
      }
      return false;
    }
  }

  static Future<List<SearchHistItem>> _parse() async {
    if (!await _file.exists()) return [];

    final data = await _file.readAsLines();

    final List<SearchHistItem> res = [];
    final dicts = Dict.values;
    for (final l in data) {
      final lc = l.trim();
      if (lc.isEmpty) continue;

      final itm = SearchHistItem.fromString(lc, dicts);
      if (itm == null) continue;
      res.add(itm);
    }

    return res;
  }

  static Future<bool> add(Dict d, String w) async {
    if (w.isEmpty) return false;

    _items.removeWhere((itm) => w == itm.word);
    _items.add(SearchHistItem(dict: d, word: w));

    if (_items.length >= _maxSize) {
      _items.removeRange(0, length - _maxSize); // max 500
    }

    return _save();
  }

  static Future<bool> rmAll() async {
    items.clear();
    try {
      if (await _file.exists()) await _file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> rm(String w) async {
    final preLen = _items.length;
    _items.removeWhere((itm) => w == itm.word);
    if (_items.length != preLen) {
      return _save();
    }
    return false;
  }
}
