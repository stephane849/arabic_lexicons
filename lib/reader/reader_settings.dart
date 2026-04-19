import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ReaderPageSettings {
  final String bookHash;
  bool isQasidah;
  bool isQasidahCentered;
  bool qasidahLineNum;
  bool isRmTashkil;
  bool isBmColored;
  TextAlign textAlign;
  String fontFam;

  ReaderPageSettings({
    required this.bookHash,
    required this.isQasidah,
    required this.isQasidahCentered,
    required this.qasidahLineNum,
    required this.isRmTashkil,
    required this.isBmColored,
    required this.fontFam,
    required this.textAlign,
  });

  static ReaderPageSettings def({String hash = "", bool? isQasidah}) =>
      ReaderPageSettings(
        bookHash: hash,
        isQasidah: isQasidah ?? false,
        isQasidahCentered: false,
        qasidahLineNum: true,
        isRmTashkil: false,
        isBmColored: true,
        fontFam: fontKitab,
        textAlign: TextAlign.justify,
      );

  bool isEqual(ReaderPageSettings rs) {
    return isQasidah == rs.isQasidah &&
        isQasidahCentered == rs.isQasidahCentered &&
        qasidahLineNum == rs.qasidahLineNum &&
        isRmTashkil == rs.isRmTashkil &&
        isBmColored == rs.isBmColored &&
        fontFam == rs.fontFam &&
        textAlign == rs.textAlign;
  }

  ReaderPageSettings copyWith({
    String? bookHash,
    bool? isQasidah,
    bool? isQasidahCentered,
    bool? qasidahLineNum,
    bool? isRmTashkil,
    bool? isBmColored,
    bool? isOpenLexiconDirecly,
    String? fontFam,
    TextAlign? textAlign,
  }) {
    return ReaderPageSettings(
      bookHash: bookHash ?? this.bookHash,
      isQasidah: isQasidah ?? this.isQasidah,
      isQasidahCentered: isQasidahCentered ?? this.isQasidahCentered,
      qasidahLineNum: qasidahLineNum ?? this.qasidahLineNum,
      isRmTashkil: isRmTashkil ?? this.isRmTashkil,
      isBmColored: isBmColored ?? this.isBmColored,
      fontFam: fontFam ?? this.fontFam,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  // @override
  // String toString() {
  //   return 'ReaderPageSettings(isQasidah: $isQasidah, '
  //       'qliasidahLineNum: $qasidahLineNum, '
  //       'isRmTashkil: $isRmTashkil, '
  //       // 'isOpenLexiconDirecly: $isOpenLexiconDirecly, '
  //       'textAlign: $textAlign)';
  // }

  Map<String, dynamic> toMap() {
    return {
      'isQasidah': isQasidah,
      'isQasidahCentered': isQasidahCentered,
      'qasidahLineNum': qasidahLineNum,
      'isRmTashkil': isRmTashkil,
      'isBmColored': isBmColored,
      'fontFam': fontFam,
      'textAlign': textAlign.name,
    };
  }

  factory ReaderPageSettings.fromMap(String hash, Map<String, dynamic> map) {
    final bookHash = hash;
    final isQasidah = map['isQasidah'] as bool?;
    final isQasidahCentered = map['isQasidahCentered'] as bool?;
    final qasidahLineNum = map['qasidahLineNum'] as bool?;
    final isRmTashkil = map['isRmTashkil'] as bool?;
    final isBmColored = map['isBmColored'] as bool?;

    final fontFam = arabicFonts.firstWhere(
      (e) => e == map['fontFam'],
      orElse: () => fontKitab,
    );

    final textAlign = TextAlign.values.firstWhere(
      (e) => e.name == map['textAlign'],
      orElse: () => TextAlign.justify,
    );

    return def(hash: hash).copyWith(
      bookHash: bookHash,
      isQasidah: isQasidah,
      isQasidahCentered: isQasidahCentered,
      qasidahLineNum: qasidahLineNum,
      isRmTashkil: isRmTashkil,
      isBmColored: isBmColored,
      fontFam: fontFam,
      textAlign: textAlign,
    );
  }

  String toJson() => jsonEncode(toMap());

  /// Deserialize from a JSON string
  factory ReaderPageSettings.fromJson(String hash, String source) =>
      ReaderPageSettings.fromMap(
        hash,
        jsonDecode(source) as Map<String, dynamic>,
      );

  static Future<String> get _confDir async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, 'reader_conf');
  }

  static Future<ReaderPageSettings> loadFromFile(
    String hash, {
    bool? isQasidah,
  }) async {
    if (hash.isEmpty) return def(isQasidah: isQasidah);

    try {
      final file = File(join(await _confDir, '$hash.json'));
      if (!await file.exists()) return def(hash: hash);

      final content = await file.readAsString();
      final rs = ReaderPageSettings.fromJson(hash, content);

      if (isQasidah != null) rs.isQasidah = isQasidah;

      return rs;
    } catch (e) {
      return def(hash: hash, isQasidah: isQasidah);
    }
  }

  /// Saves the settings to the given path, creating the file if needed
  Future<void> saveToFile() async {
    if (bookHash.isEmpty) return;

    final parent = Directory(await _confDir);
    await parent.create(recursive: true); // ensures parent dirs exist

    final file = File(join(parent.path, '$bookHash.json'));
    await file.writeAsString(toJson());
  }

  static Future<void> delete(String hash) async {
    if (hash.isEmpty) return;
    final f = File(join(await _confDir, '$hash.json'));
    if (await f.exists()) await f.delete();
  }
}
