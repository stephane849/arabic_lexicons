import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const bookMarkFileName = 'arabic_lexicons_bookMarks.txt';

class BookMarks {
  static const int _maxBookMarkWrodSize = 10;
  static late final File _bookMarkFile;
  static late final File _bookMarkFileTmp;
  static Set<String> _bookMarkedWords = {};

  static Set<String> get words => _bookMarkedWords;

  static bool _loaded = false;

  static Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _bookMarkFile = File(join(dir.path, bookMarkFileName));
      _bookMarkFileTmp = File(
        join(dir.path, 'arabic_lexicons_bookMarks_tmp.txt'),
      );

      if (!await _bookMarkFile.exists()) {
        _loaded = true;
        return;
      }
      final lines = await _bookMarkFile.readAsLines();

      final res = await Isolate.run(() {
        final Set<String> res = {};
        for (var w in lines) {
          w = w.trim();
          if (w.isNotEmpty) res.add(w);
        }
        return res;
      });
      _bookMarkedWords = res;
      _loaded = true;
    } catch (e) {
      debugPrint('Bookmark load failed: $e');
      _loaded = true;
    }
  }

  static bool isSet(String? w) {
    if (!_loaded) return false;
    return _bookMarkedWords.contains(w);
  }

  static bool get isEmpty {
    if (!_loaded) return true;
    return _bookMarkedWords.isEmpty;
  }

  static bool get isNotEmpty {
    if (!_loaded) return false;
    return _bookMarkedWords.isNotEmpty;
  }

  static int get length {
    if (!_loaded) return 0;
    return _bookMarkedWords.length;
  }

  static Set<String> get list {
    if (!_loaded) return {};
    return _bookMarkedWords;
  }

  static Future<bool> tougge(String w) async {
    if (isSet(w)) return rm(w);

    return add(w);
  }

  /// word must be cleaned
  static Future<bool> add(String w) async {
    if (!_loaded) return false;
    if (w.isEmpty || w.length > _maxBookMarkWrodSize) return false;
    if (!_bookMarkedWords.add(w)) return true;

    if (!await _saveToFile()) {
      _bookMarkedWords.remove(w);
      return false;
    }
    return true;
  }

  /// word list must be cleaned
  static Future<int> addAll(List<String> wl) async {
    if (!_loaded) return 0;
    List<String> addedWords = [];
    for (final w in wl) {
      if (w.isEmpty || w.length > _maxBookMarkWrodSize) continue;
      if (_bookMarkedWords.add(w)) {
        addedWords.add(w);
      }
    }

    if (addedWords.isEmpty) return 0;

    if (!await _saveToFile()) {
      for (final w in addedWords) {
        _bookMarkedWords.remove(w);
      }
      return 0;
    }

    return addedWords.length;
  }

  static Future<bool> rm(String w) async {
    if (!_loaded) return false;
    if (w.isEmpty) return false;
    if (!_bookMarkedWords.remove(w)) return true;
    if (!await _saveToFile()) {
      _bookMarkedWords.add(w);
      return false;
    }

    return true;
  }

  static Future<int> rmList(Iterable<String> wordsToDel) async {
    if (!_loaded) return 0;
    if (_bookMarkedWords.isEmpty) return 0;

    final removedWords = _bookMarkedWords.toList();

    int rmCount = 0;
    for (final w in wordsToDel) {
      if (_bookMarkedWords.remove(w)) rmCount++;
    }

    if (!await _saveToFile()) {
      _bookMarkedWords.addAll(removedWords);
      return 0;
    }

    return rmCount;
  }

  static Future<int> rmAll() async {
    if (!_loaded) return 0;
    if (_bookMarkedWords.isEmpty) return 0;

    final removedWords = _bookMarkedWords.toList();
    _bookMarkedWords.clear();

    if (!await _saveToFile()) {
      for (final w in removedWords) {
        _bookMarkedWords.add(w);
      }
      return 0;
    }

    return removedWords.length;
  }

  /// if could not save then remove form memory also
  static Future<bool> _saveToFile() async {
    if (!_loaded) return false;
    if (_bookMarkedWords.isEmpty) {
      try {
        if (await _bookMarkFile.exists()) await _bookMarkFile.delete();
      } catch (_) {
        return false;
      }
      return true;
    }

    final txt = _bookMarkedWords.join("\n");

    try {
      await _bookMarkFileTmp.writeAsString(txt);
    } catch (e) {
      return false;
    }

    try {
      await _bookMarkFileTmp.rename(_bookMarkFile.path);
    } catch (e) {
      return false;
    }
    return true;
  }
}
