import 'dart:io';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbService {
  static const _assetDbPath = 'assets/data/db.sqlite';
  static const _oldDbFileNames = ['db.sqlite', 'db_v2.sqlite'];
  static const _dbFileName = 'db_v5.sqlite';

  static Database? _db;

  static Future<Database> _openDb() async {
    final dbPath = await _copyDbFromAssetsIfNeeded();
    return openDatabase(dbPath, readOnly: true);
  }

  static Future<String> _copyDbFromAssetsIfNeeded() async {
    final dbDir = await getDatabasesPath();
    final dbPath = join(dbDir, _dbFileName);

    if (kDebugMode) {
      debugPrint('Copying db $_assetDbPath -> ${dbPath.toString()}');
    }

    // delete old files
    for (final n in _oldDbFileNames) {
      final f = File(join(dbDir, n));
      f.exists().then((ok) {
        if (ok) f.delete();
      });
    }

    if (await File(dbPath).exists()) {
      return dbPath;
    }

    final data = await rootBundle.load(_assetDbPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    await File(dbPath).create(recursive: true);
    await File(dbPath).writeAsBytes(bytes, flush: true);

    return dbPath;
  }

  /// Must be called once (Linux requirement)
  static Future<void> init() async {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _db = await _openDb();
  }

  static Database get database {
    if (_db == null) {
      throw "no db open";
    }
    return _db!;
  }

  /// Fetch by exact word
  static Future<List<Map<String, dynamic>>> getByWordWith3Rows(
    Dict d,
    String? word,
  ) async {
    if (word == null || word.isEmpty) {
      return const [];
    }

    final db = database;
    var res = await db.query(d.table, where: 'word = ?', whereArgs: [word]);

    if (res.isEmpty && word.length > 2) {
      res = await db.query(d.table, where: 'word = ?', whereArgs: ['ال$word']);
    }

    if (res.isEmpty) return [];

    final entries = <Map<String, dynamic>>[];

    for (final row in res) {
      final meaningsRaw = row['meanings'] as String? ?? '';

      String m = meaningsRaw.replaceAll('|', '\n').replaceAll('<br>', '\n');
      if (d.hasRefs) m = ReferenceProcessor.process(m);
      entries.add({'word': row['word'], 'meanings': m});
    }

    return entries;
  }

  static Future<List<Map<String, dynamic>>> getByWordGoni(String? word) async {
    if (word == null || word.isEmpty) {
      return const [];
    }
    final db = database;
    const q =
        'SELECT word, root, meanings FROM mujamul_ghoni WHERE root = ? OR no_harakat = ?';
    final res = await db.rawQuery(q, [word, word]);

    final entries = <Map<String, dynamic>>[];

    for (final row in res) {
      final meaningsRaw = row['meanings'] as String? ?? '';

      entries.add({
        'word': row['word'],
        'root': row['root'],
        'meanings': meaningsRaw.replaceAll('|', '\n').replaceAll('<br>', '\n'),
      });
    }

    return entries;
  }

  static Future<List<Map<String, dynamic>>> getByWordHans(String? word) async {
    if (word == null || word.trim().isEmpty) {
      return const [];
    }

    final db = database;
    final query = word.trim();

    var res = await db.rawQuery(
      '''
      SELECT word, meanings, is_root
      FROM hanswehr
      WHERE parent_id IN (
        SELECT parent_id FROM hanswehr WHERE is_root AND word = ?
      )
      ORDER BY id
    ''',
      [query],
    );

    if (res.isNotEmpty) {
      return res;
    }

    res = await db.rawQuery(
      '''
      SELECT word, meanings, is_root
      FROM hanswehr
      WHERE parent_id IN (
        SELECT parent_id FROM hanswehr WHERE word = ?
      )
      ORDER BY id
    ''',
      [query],
    );

    final results = <Map<String, dynamic>>[];
    if (res.isNotEmpty) {
      results.addAll(
        res.map((row) {
          final w = row['word'] as String? ?? '';
          return {
            'word': w,
            'meanings': row['meanings'],
            // 'isRoot': row['is_root'],
            'isHi': w == query, // match highlighted word result
          };
        }),
      );
      return results;
    }

    if (query.length >= 3) {
      res = await db.rawQuery(
        '''
        SELECT word, meanings, is_root
        FROM hanswehr
        WHERE meanings LIKE ?
        LIMIT 40
      ''',
        ['%$query%'],
      );

      results.addAll(
        res.map((row) {
          final w = row['word'] as String? ?? '';
          var m = row['meanings'] as String? ?? '';

          // Highlight query inside meanings
          final highlighted = m.replaceAll(
            query,
            '<span class="high">$query</span>',
          );

          return {'word': w, 'meanings': highlighted, 'isRoot': row['is_root']};
        }),
      );
    }

    return results;
  }

  static Future<List<Map<String, dynamic>>> getByWordLane(String? word) async {
    if (word == null || word.isEmpty) {
      return const [];
    }
    var q = '''SELECT word, meanings, is_root FROM lanelexcon
	WHERE parent_id IN (SELECT parent_id FROM lanelexcon WHERE is_root AND WORD = ?)
	ORDER BY id''';

    final db = database;
    var res = await db.rawQuery(q, [word]);

    if (res.isNotEmpty) {
      return res;
    }
    q = '''SELECT word, meanings, is_root FROM lanelexcon
       WHERE parent_id IN (SELECT parent_id FROM lanelexcon WHERE WORD = ?)
       ORDER BY id''';
    res = await db.rawQuery(q, [word]);

    final results = <Map<String, dynamic>>[];
    if (res.isNotEmpty) {
      results.addAll(
        res.map((row) {
          final w = row['word'] as String? ?? '';
          return {
            'word': w,
            'meanings': row['meanings'],
            'isRoot': row['is_root'],
            'isHi': w == word,
          };
        }),
      );
    }
    return results;
  }

  static Future<void> close() async {
    await _db?.close();
  }

  static Future<List<String>> getSearchSuggestionList(Dict selectedDict) async {
    switch (selectedDict) {
      case Dict.arEn:
        return [];

      case Dict.mujamulGhoni:
        final db = database;

        var dbRes = await db.rawQuery('SELECT root FROM ${selectedDict.table}');
        final res = dbRes.map((r) => r['root'] as String).toList();

        dbRes = await db.rawQuery('SELECT no_harakat FROM ${selectedDict.table}');
        res.addAll(dbRes.map((r) => r['no_harakat'] as String));

        return res;

      case Dict.mujamulShihah:
      case Dict.lisanAlArab:
      case Dict.mujamulMuashiroh:
      case Dict.mujamulWasith:
      case Dict.mujamulMuhith:
      case Dict.mufradatAlfajulQuran:
      case Dict.maqayeesulLuga:
      case Dict.hanswehr:
      case Dict.laneLexicon:
        final db = database;
        final dbRes = await db.rawQuery(
          'SELECT word FROM ${selectedDict.table}',
        );

        return dbRes.map((r) => r['word'] as String).toList();
    }
  }
}

class ReferenceProcessor {
  // Compiled once. Never recreated.
  static final RegExp _refExp = RegExp(r'\[\[(.*?)\]\]', dotAll: true);

  static String process(String text) {
    if (text.isEmpty) return text;

    final StringBuffer mainBuffer = StringBuffer();
    final List<String> refs = [];

    int lastIndex = 0;
    int counter = 1;

    for (final match in _refExp.allMatches(text)) {
      // Write text before match
      mainBuffer.write(text.substring(lastIndex, match.start));

      final refContent = match.group(1);
      if (refContent != null) {
        refs.add(refContent.trim());

        final arabicNumber = enToArNum(counter.toString());
        mainBuffer.write('($arabicNumber)');
        counter++;
      }

      lastIndex = match.end;
    }

    // Write remaining text
    mainBuffer.write(text.substring(lastIndex));

    if (refs.isEmpty) {
      return mainBuffer.toString();
    }

    mainBuffer.write('\n\n');
    // Append references section

    for (int i = 0; i < refs.length; i++) {
      final arabicNumber = enToArNum((i + 1).toString());
      final r = refs[i].trim().replaceFirst('. ', '');
      mainBuffer
        ..write('($arabicNumber) ')
        ..writeln(r);
    }

    return mainBuffer.toString().trimRight();
  }
}
