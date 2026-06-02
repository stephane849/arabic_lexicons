import 'dart:io';

import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/history/history.dart';
import 'package:ara_dict/reader/input.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract final class WordStore {
  static const int histMaxSize = 200;
  static const int _maxBookMarkWrodSize = 10;

  static bool _inited = false;
  static Database? _db;

  static final Set<String> bookmarkedWords = <String>{};
  static final Set<String> foreignWords = <String>{};
  static final List<SearchHistItem> searchHist = []; //<SearchHist>{};

  /// word not okay
  static bool _wnok(String s) => s.isEmpty || s.length > _maxBookMarkWrodSize;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  static Future<void> init() async {
    if (_inited) return;

    try {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dbPath = await getDatabasesPath();

      _db = await openDatabase(
        join(dbPath, 'words.db'),
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE bookmarked_words (
            word TEXT PRIMARY KEY
          )
        ''');

          await db.execute('''
          CREATE TABLE foreign_words (
            word TEXT PRIMARY KEY
          )
        ''');
          await db.execute('''
          CREATE TABLE search_history (
            word TEXT PRIMARY KEY,
            dict INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          );
          ''');
        },
      );

      await _loadCache();

      _inited = true;
    } catch (_) {
      _inited = false;
    }
    await BookMarks.migrateOld(_inited);
  }

  static Future<void> _loadCache() async {
    // bookmarkedWords.clear();
    // foreignWords.clear();
    // searchHist.clear();

    final bookmarks = await _db?.query('bookmarked_words');
    if (bookmarks != null) {
      bookmarkedWords.addAll(bookmarks.map((e) => e['word'] as String));
    }

    final foreigns = await _db?.query('foreign_words');
    if (foreigns != null) {
      foreignWords.addAll(foreigns.map((e) => e['word'] as String));
    }

    final rows = await _db?.query('search_history', orderBy: 'created_at ASC');

    if (rows != null) {
      final dicts = Dict.values;
      for (final r in rows) {
        final word = r['word'] as String;
        int dictIndex = r['dict'] as int;

        if (dictIndex < 0 || dictIndex >= dicts.length) dictIndex = 0;

        searchHist.add(SearchHistItem(word: word, dict: dicts[dictIndex]));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Bookmark words
  // ---------------------------------------------------------------------------

  /// bookmarked

  static bool isBm(String word) => bookmarkedWords.contains(word);
  static int get bmLen => bookmarkedWords.length;
  static String bmAt(int i) => bookmarkedWords.elementAt(i);
  static bool get bmEmpty => bookmarkedWords.isEmpty;
  static bool get bmNotEmpty => bookmarkedWords.isNotEmpty;

  static Future<void> addBM(String word) async {
    if (_wnok(word)) return;

    bookmarkedWords.add(word);
    await _db?.insert('bookmarked_words', {
      'word': word,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<int> addBMs(Iterable<String> words) async {
    if (words.isEmpty) return 0;

    final batch = _db?.batch();

    int added = 0;
    for (final word in words) {
      if (_wnok(word)) continue;

      added++;
      bookmarkedWords.add(word);

      if (batch == null) continue;
      batch.insert('bookmarked_words', {
        'word': word,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch?.commit(noResult: true);
    return added;
  }

  static Future<void> rmBM(String word) async {
    if (word.isEmpty) return;

    bookmarkedWords.remove(word);
    await _db?.delete('bookmarked_words', where: 'word = ?', whereArgs: [word]);
  }

  static Future<void> rmBMs(Iterable<String> words) async {
    if (words.isEmpty) return;

    bookmarkedWords.removeAll(words);

    if (_db == null) return;

    final list = words.toList();
    final placeholders = List.filled(list.length, '?').join(',');

    await _db?.delete(
      'bookmarked_words',
      where: 'word IN ($placeholders)',
      whereArgs: list,
    );
  }

  static Future<void> clearBookmarks() async {
    bookmarkedWords.clear();
    await _db?.delete('bookmarked_words');
  }

  // ---------------------------------------------------------------------------
  // Foreign words
  // ---------------------------------------------------------------------------

  static bool isForeign(String word) => foreignWords.contains(word);
  static int get foreignLen => foreignWords.length;
  static String foreignIdx(int i) => foreignWords.elementAt(i);
  static bool get foreignEmpty => foreignWords.isEmpty;
  static bool get foreignNotEmpty => foreignWords.isNotEmpty;

  static Future<void> addForeign(String word) async {
    if (_wnok(word)) return;

    foreignWords.add(word);

    await _db?.insert('foreign_words', {
      'word': word,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> addForeigns(Iterable<String> words) async {
    if (words.isEmpty) return;

    final batch = _db?.batch();

    for (final word in words) {
      if (_wnok(word)) continue;

      foreignWords.add(word);

      if (batch == null) continue;
      batch.insert('foreign_words', {
        'word': word,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch?.commit(noResult: true);
  }

  static Future<void> removeForeign(String word) async {
    if (word.isEmpty) return;
    foreignWords.remove(word);
    await _db?.delete('foreign_words', where: 'word = ?', whereArgs: [word]);
  }

  static Future<void> removeForeignMany(Iterable<String> words) async {
    if (words.isEmpty) return;

    final list = words.toList();
    foreignWords.removeAll(list);

    if (_db == null) return;

    final placeholders = List.filled(list.length, '?').join(',');

    await _db?.delete(
      'foreign_words',
      where: 'word IN ($placeholders)',
      whereArgs: list,
    );
  }

  static Future<void> clearForeign() async {
    foreignWords.clear();
    await _db?.delete('foreign_words');
  }

  // static List<String> getForeignWords() {
  //   return foreignWords.toList(growable: false);
  // }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  // static Future<void> reload() async {
  //   await _loadCache();
  // }

  static Future<void> close() async {
    await _db?.close();
    _db = null;

    bookmarkedWords.clear();
    foreignWords.clear();
  }

  // ---------------------------------------------------------------------------
  // Search History
  // ---------------------------------------------------------------------------
  static int get histLen => searchHist.length;
  static SearchHistItem histAt(int i) => searchHist[i];
  static bool get histEmpty => searchHist.isEmpty;
  static bool get histNotEmpty => searchHist.isNotEmpty;

  static Future<void> histAdd(Dict d, String word) async {
    if (_wnok(word)) return;

    final item = SearchHistItem(dict: d, word: word);

    // remove existing in memory (refresh order)
    final rmed = searchHist.remove(item);

    searchHist.add(item);

    await _db?.insert('search_history', {
      'word': word,
      'dict': d.index,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (rmed) return;

    if (searchHist.length > histMaxSize + 20) {
      final removeCount = searchHist.length - histMaxSize;

      // oldest items in memory
      final toRemove = searchHist.take(removeCount).toList();

      // remove from memory
      searchHist.removeRange(0, removeCount);

      // remove from DB using keys
      final words = toRemove.map((e) => e.word).toList();

      final placeholders = List.filled(words.length, '?').join(',');

      await _db?.delete(
        'search_history',
        where: 'word IN ($placeholders)',
        whereArgs: words,
      );
    }
  }

  static Future<void> rmHistItem(SearchHistItem item) async {
    // remove existing in memory (refresh order)
    searchHist.remove(item);
    await _db?.delete(
      'search_history',
      where: 'word = ?',
      whereArgs: [item.word],
    );
  }

  static Future<void> clearHist() async {
    searchHist.clear();
    await _db?.delete('search_history');
  }
}

bool _migratedForeigns = false;
Future<void> migrateForeigns() async {
  if (_migratedForeigns) return;
  if (!ReaderInputPageData.isInited) {
    await ReaderInputPageData.init();
    if (!ReaderInputPageData.isInited) return;
  }

  _migratedForeigns = true;

  for (final b in ReaderInputPageData.books) {
    final f = await ReaderPageSettings.lurFile(b.hash);
    try {
      WordStore.addForeigns(await f.readAsLines());
      if (WordStore._inited) await f.delete();
    } catch (_) {}
  }
}
