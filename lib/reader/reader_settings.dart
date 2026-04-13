import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ReaderPageSettings {
  final String bookHash;
  bool isQasidah;
  bool qasidahLineNum;
  bool isRmTashkil;
  // bool isOpenLexiconDirecly;
  TextAlign textAlign;
  String fontFam;

  ReaderPageSettings({
    required this.bookHash,
    required this.isQasidah,
    required this.qasidahLineNum,
    required this.isRmTashkil,
    // required this.isOpenLexiconDirecly,
    required this.fontFam,
    required this.textAlign,
  });

  static ReaderPageSettings def(String h) => ReaderPageSettings(
    bookHash: h,
    isQasidah: false,
    qasidahLineNum: true,
    isRmTashkil: false,
    fontFam: fontKitab,
    textAlign: TextAlign.justify,
  );

  bool isEqual(ReaderPageSettings rs) {
    return isQasidah == rs.isQasidah &&
        qasidahLineNum == rs.qasidahLineNum &&
        isRmTashkil == rs.isRmTashkil &&
        fontFam == rs.fontFam &&
        textAlign == rs.textAlign;
  }

  ReaderPageSettings copyWith({
    String? bookHash,
    bool? isQasidah,
    bool? qasidahLineNum,
    bool? isRmTashkil,
    bool? isOpenLexiconDirecly,
    String? fontFam,
    TextAlign? textAlign,
  }) {
    return ReaderPageSettings(
      bookHash: bookHash ?? this.bookHash,
      isQasidah: isQasidah ?? this.isQasidah,
      qasidahLineNum: qasidahLineNum ?? this.qasidahLineNum,
      isRmTashkil: isRmTashkil ?? this.isRmTashkil,
      fontFam: fontFam ?? this.fontFam,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  @override
  String toString() {
    return 'ReaderPageSettings(isQasidah: $isQasidah, '
        'qliasidahLineNum: $qasidahLineNum, '
        'isRmTashkil: $isRmTashkil, '
        // 'isOpenLexiconDirecly: $isOpenLexiconDirecly, '
        'textAlign: $textAlign)';
  }

  Map<String, dynamic> toMap() {
    return {
      'isQasidah': isQasidah,
      'qasidahLineNum': qasidahLineNum,
      'isRmTashkil': isRmTashkil,
      'fontFam': fontFam,
      'textAlign': textAlign.name, // ← directly here
    };
  }

  factory ReaderPageSettings.fromMap(String hash, Map<String, dynamic> map) {
    final bookHash = hash;
    final isQasidah = map['isQasidah'] as bool?;
    final qasidahLineNum = map['qasidahLineNum'] as bool?;
    final isRmTashkil = map['isRmTashkil'] as bool?;
    final fontFam = map['fontFam'] as String?;
    final textAlign = TextAlign.values.firstWhere(
      (e) => e.name == map['textAlign'],
      orElse: () => TextAlign.justify,
    );

    return def("").copyWith(
      bookHash: bookHash,
      isQasidah: isQasidah,
      qasidahLineNum: qasidahLineNum,
      isRmTashkil: isRmTashkil,
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

  static const String _readerSettingsSaveDir = 'reader_conf';

  static Future<ReaderPageSettings> loadFromFile(String hash) async {
    if (hash.isEmpty) return def("");
    try {
      final parent = await getApplicationCacheDirectory();
      final file = File(
        join(parent.path, _readerSettingsSaveDir, '$hash.json'),
      );
      if (!await file.exists()) return def(hash);

      final content = await file.readAsString();
      return ReaderPageSettings.fromJson(hash, content);
    } catch (e) {
      return def(hash);
    }
  }

  /// Saves the settings to the given path, creating the file if needed
  Future<void> saveToFile() async {
    if (bookHash.isEmpty) return;

    final parentsParent = await getApplicationCacheDirectory();
    final parent = Directory(join(parentsParent.path, _readerSettingsSaveDir));
    await parent.create(recursive: true); // ensures parent dirs exist

    final file = File(join(parent.path, '$bookHash.json'));
    await file.writeAsString(toJson());
  }
}
