import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ReaderPageSettings {
  final String bookHash;
  bool isQasidah;
  bool qasidahLineNum;
  bool isRmTashkil;
  // bool isOpenLexiconDirecly;
  TextAlign textAlign;

  ReaderPageSettings({
    required this.bookHash,
    required this.isQasidah,
    required this.qasidahLineNum,
    required this.isRmTashkil,
    // required this.isOpenLexiconDirecly,
    required this.textAlign,
  });

  static ReaderPageSettings def(String h) => ReaderPageSettings(
    bookHash: h,
    isQasidah: false,
    qasidahLineNum: true,
    isRmTashkil: false,
    // isOpenLexiconDirecly: appSettingsNotifier.readerIsOpenLexiconDirecly,
    textAlign: TextAlign.justify,
  );

  bool isEqual(ReaderPageSettings rs) {
    return isQasidah == rs.isQasidah &&
        qasidahLineNum == rs.qasidahLineNum &&
        isRmTashkil == rs.isRmTashkil &&
        // isOpenLexiconDirecly == rs.isOpenLexiconDirecly &&
        textAlign == rs.textAlign;
  }

  ReaderPageSettings copyWith({
    String? bookHash,
    bool? isQasidah,
    bool? qasidahLineNum,
    bool? isRmTashkil,
    bool? isOpenLexiconDirecly,
    TextAlign? textAlign,
  }) {
    return ReaderPageSettings(
      bookHash: bookHash ?? this.bookHash,
      isQasidah: isQasidah ?? this.isQasidah,
      qasidahLineNum: qasidahLineNum ?? this.qasidahLineNum,
      isRmTashkil: isRmTashkil ?? this.isRmTashkil,
      // isOpenLexiconDirecly: isOpenLexiconDirecly ?? this.isOpenLexiconDirecly,
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
      // 'isOpenLexiconDirecly': isOpenLexiconDirecly,
      'textAlign': textAlign.name, // ← directly here
    };
  }

  factory ReaderPageSettings.fromMap(String hash, Map<String, dynamic> map) {
    return ReaderPageSettings(
      bookHash: hash,
      isQasidah: map['isQasidah'] as bool,
      qasidahLineNum: map['qasidahLineNum'] as bool,
      isRmTashkil: map['isRmTashkil'] as bool,
      // isOpenLexiconDirecly: appSettingsNotifier.readerIsOpenLexiconDirecly,
      textAlign: TextAlign.values.firstWhere(
        (e) => e.name == map['textAlign'],
        orElse: () => TextAlign.justify,
      ),
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
