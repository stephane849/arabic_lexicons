import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/ar_en/ar_en.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

final appSettingsNotifier = AppSettingsController();

const appName = 'Arabic Lexcions';

const fontAmiri = 'Amiri';
const fontKitab = 'Kitab';

const scrollPadding = EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 40);

const dictWordSelectModalOpenIcon = Icons.swap_horiz_rounded;

class Routes {
  static const dictionary = '/dictionary';
  static const readerInput = '/readerInput';
  static const readerPage = '/readerPage';
  static const bookMarks = '/bookMarks';
  static const startupscreen = '/startupscreen';
  // static const help = '/help';
}

const routesToBeSavedInPref = [Routes.dictionary, Routes.readerInput];

// class DictEntry {
//   final Dict d;
//   final String ar;
//   final String en;

//   const DictEntry({required this.d, required this.ar, required this.en});
// }

class SearchLexiconsDatas {
  Dict selectedDict = Dict.values.first;

  String preQuery = '';
  // String? suggLastWord;
  Map<Dict, Set<String>> sugg = {};
  bool isShowingSugg = false;
  List<Dict> suggDictSorted = [];

  List<String>? words;
  String? selectedWord;

  List<Map<String, dynamic>>? dbRes;
  List<ArEnEntry>? arEnRes;
  bool resLoaded = false;

  void resetSugg() {
    sugg = {};
    isShowingSugg = false;
  }

  void resetWords() {
    words = null;
    selectedWord = null;
  }

  void resetRes() {
    resLoaded = false;
    dbRes = null;
    arEnRes = null;
  }

  void resetAll() {
    resetSugg();
    resetWords();
    resetRes();
  }

  bool get isSelectedWordEmpty {
    return selectedWord == null || selectedWord!.isEmpty;
  }

  bool get areWordsEmpty {
    return words == null || words!.isEmpty;
  }

  bool get resultsAreEmpty =>
      (dbRes == null || dbRes!.isEmpty) &&
      (arEnRes == null || arEnRes!.isEmpty);

  Future<void> setSelectWord(String? word, VoidCallback onChange) async {
    if (word == selectedWord) return;

    selectedWord = word;

    resetRes();
    resetSugg();
    onChange();

    await loadResults(onChange);
    if (resultsAreEmpty) loadSearchSugg(onChange);
  }

  Future<void> setSelectDict(Dict de, VoidCallback onChange) async {
    if (selectedDict == de) return;

    selectedDict = de;

    resetRes();
    resetSugg();
    onChange();

    await loadResults(onChange);
    if (resultsAreEmpty) loadSearchSugg(onChange);
  }

  Future<void> loadSearchSugg(VoidCallback onChange) async {
    if (!SearchSuggestions.shouldShow) return;

    resetSugg();
    if (selectedWord == null || selectedWord!.isEmpty) return;

    isShowingSugg = true;
    // suggLastWord = selectedWord;
    sugg = await SearchSuggestions.getSuggestions(selectedWord!);
    onChange();
  }

  Future<void> loadResults(VoidCallback after) async {
    if (isSelectedWordEmpty) {
      resLoaded = true;
      after();
      return;
    }
    resLoaded = false;

    switch (selectedDict) {
      case Dict.arEn:
        arEnRes = await ArEnDict.findWord(selectedWord);

      case Dict.hanswehr:
        dbRes = await DbService.getByWordHans(selectedWord);

      case Dict.laneLexicon:
        dbRes = await DbService.getByWordLane(selectedWord);

      case Dict.mujamulGhoni:
        dbRes = await DbService.getByWordGoni(selectedWord);

      case Dict.mujamulShihah:
      case Dict.lisanAlArab:
      case Dict.mujamulMuashiroh:
      case Dict.mujamulWasith:
      case Dict.mujamulMuhith:
      case Dict.mufradatAlfajulQuran:
      case Dict.maqayeesulLuga:
        dbRes = await DbService.getByWordWith3Rows(selectedDict, selectedWord);
    }

    // await Future.delayed(
    //   Duration(seconds: 1),
    // ); // for testing, looking at the loader lol
    resLoaded = true;
    after();
  }

  /// for onSettings change
  void getAndShowResORSugg(VoidCallback onChange, {bool reset = true}) async {
    if (reset) {
      if (selectedWord == null || selectedWord!.isEmpty) return;

      resetRes();
      resetSugg();
      onChange();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Dict.arEn == selectedDict ||
          !appSettingsNotifier.showSearchSugg ||
          appSettingsNotifier.showResutlsDirecly) {
        await loadResults(onChange);
      }

      if (SearchSuggestions.shouldShow && resultsAreEmpty) {
        loadSearchSugg(onChange);
      }
    });
  }

  @override
  String toString() {
    return '''
SearchLexiconsDatas(
  selectedDict: $selectedDict,
  words: $words,
  selectedWord: $selectedWord,
  dbRes length: ${dbRes?.length},
  arEnRes length: ${arEnRes?.length},
  resLoaded: $resLoaded
)
''';
  }
}

const List<Dict> allDicts = [
  Dict.arEn,
  Dict.hanswehr,
  Dict.laneLexicon,
  Dict.mujamulGhoni,
  Dict.mujamulShihah,
  Dict.lisanAlArab,
  Dict.mujamulMuashiroh,
  Dict.mujamulWasith,
  Dict.mujamulMuhith,
  Dict.maqayeesulLuga,
  Dict.mufradatAlfajulQuran,
];

const List<Dict> allDictsExpeptArEn = [
  Dict.hanswehr,
  Dict.laneLexicon,
  Dict.mujamulGhoni,
  Dict.mujamulShihah,
  Dict.lisanAlArab,
  Dict.mujamulMuashiroh,
  Dict.mujamulWasith,
  Dict.mujamulMuhith,
  Dict.maqayeesulLuga,
  Dict.mufradatAlfajulQuran,
];

enum Dict {
  arEn(
    id: 1,
    table: "arEn",
    ar: "مباشر",
    en: "Aratools Arabic–English",
    description:
        "GPL-licensed components of the Aratools Arabic-English dictionary. "
        "Based on Tim Buckwalter’s Aramorph Arabic morphological analyzer "
        "(dictprefixes, dictstems, dictsuffixes, tableab, tableac, tablebc). "
        "Distributed via Aramorph and Linguistic Data Consortium sources.",
    link: "http://www.nongnu.org/aramorph/",
  ),

  hanswehr(
    id: 2,
    table: "hanswehr",
    ar: "هانز",
    en: "Hans Wehr Dictionary",
    description:
        "Modern Arabic–English dictionary compiled by Hans Wehr. "
        "Widely used academic reference organized by triliteral roots.",
    link: "https://en.wikipedia.org/wiki/Hans_Wehr_dictionary",
  ),

  laneLexicon(
    id: 2,
    table: "lanelexcon",
    ar: "لين",
    en: "Lane’s Arabic-English Lexicon",
    description:
        "Comprehensive 19th-century Arabic-English lexicon by Edward William Lane, "
        "based on major classical sources.",
    link: "https://en.wikipedia.org/wiki/Edward_William_Lane",
  ),

  mujamulGhoni(
    id: 4,
    table: "mujamul_ghoni",
    ar: "الغني",
    en: "Al-Muʿjam al-Ghani",
    description:
        "Contemporary Arabic dictionary focusing on modern vocabulary and usage.",
  ),

  mujamulShihah(
    id: 5,
    table: "mujamul_shihah",
    ar: "الصحاح",
    en: "Al-Sihah (al-Jawhari)",
    description:
        "Classical Arabic dictionary by al-Jawhari (4th century AH), "
        "one of the foundational root-based lexicons.",
    link: "https://ar.wikipedia.org/wiki/الصحاح_في_اللغة",
    hasRefs: true,
  ),

  lisanAlArab(
    id: 6,
    table: "lisanularab",
    ar: "لسان",
    en: "Lisan al-Arab",
    description:
        "Major classical Arabic lexicon compiled by Ibn Manzur (7th century AH), "
        "drawing from earlier authoritative sources.",
    link: "https://en.wikipedia.org/wiki/Lisan_al-Arab",
    hasRefs: true,
  ),

  mujamulMuashiroh(
    id: 7,
    table: "mujamul_muashiroh",
    ar: "المعاصرة",
    en: "Al-Muʿjam al-Muʿasirah",
    description:
        "Modern Arabic dictionary emphasizing contemporary terminology and usage.",
  ),

  mujamulWasith(
    id: 8,
    table: "mujamul_wasith",
    ar: "الوسيط",
    en: "Al-Muʿjam al-Wasit",
    description:
        "Standard modern Arabic dictionary published by the Arabic Language Academy in Cairo.",
    link: "https://ar.wikipedia.org/wiki/المعجم_الوسيط",
  ),

  mujamulMuhith(
    id: 9,
    table: "mujamul_muhith",
    ar: "المحيط",
    en: "Al-Qamus al-Muhit",
    description:
        "Influential classical dictionary by al-Firuzabadi (8th century AH), "
        "widely cited in later lexicons.",
    link: "https://ar.wikipedia.org/wiki/القاموس_المحيط",
  ),

  maqayeesulLuga(
    id: 10,
    table: "maqayeesul_luga",
    ar: "مقاييس",
    en: "Maqayis al-Lugha",
    description:
        "Root-based semantic analysis by Ibn Faris (4th century AH), "
        "reducing each root to its core conceptual meanings.",
    link: "https://ar.wikipedia.org/wiki/مقاييس_اللغة",
    hasRefs: true,
  ),

  mufradatAlfajulQuran(
    id: 11,
    table: "mufradat_alfajul_quran",
    ar: "مفردات",
    en: "Mufradat Alfaz al-Qur’an",
    description:
        "Qur’anic lexicon by al-Raghib al-Isfahani, "
        "analyzing vocabulary and semantic nuances of Qur’anic terms.",
    link: "https://ar.wikipedia.org/wiki/المفردات_في_غريب_القرآن",
    hasRefs: true,
  );

  final int id; // must be unique
  final String table;
  final String ar;
  final String en;
  final String description;
  final String? link;
  final bool hasRefs;

  const Dict({
    required this.id,
    required this.table,
    required this.ar,
    required this.en,
    required this.description,
    this.link,
    this.hasRefs = false,
  });
}

int encode(Set<Dict> selected) {
  int mask = 0;
  for (final d in selected) {
    mask |= (1 << d.index);
  }
  return mask;
}

Set<Dict> decode(int mask) {
  final result = <Dict>{};

  for (final d in Dict.values) {
    if ((mask & (1 << d.index)) != 0) {
      result.add(d);
    }
  }

  return result;
}

// enum Dict {
//   arEn(table: "arEn", ar: "مباشر", en: "Direct Dictionary"),
//   hanswehr(table: "hanswehr", ar: "هانز", en: "Hans Wehr"),
//   laneLexicon(table: "lanelexcon", ar: "لين", en: "Lane Lexicon"),
//   mujamulGhoni(table: "mujamul_ghoni", ar: "الغني", en: "Al-Ghani"),
//   mujamulShihah(
//     table: "mujamul_shihah",
//     ar: "الصحاح",
//     en: "As-Shihah",
//     hasRefs: true,
//   ),
//   lisanAlArab(
//     table: "lisanularab",
//     ar: "لسان",
//     en: "Lisan Al-Arab",
//     hasRefs: true,
//   ),
//   mujamulMuashiroh(
//     table: "mujamul_muashiroh",
//     ar: "المعاصرة",
//     en: "Al-Muashirah",
//   ),
//   mujamulWasith(table: "mujamul_wasith", ar: "الوسيط", en: "Al-Waseet"),
//   mujamulMuhith(table: "mujamul_muhith", ar: "المحيط", en: "Al-Muhit"),
//   maqayeesulLuga(
//     table: "maqayeesul_luga",
//     ar: "مقاييس",
//     en: "Maqayeesul-Luga",
//     hasRefs: true,
//   ),
//   mufradatAlfajulQuran(
//     table: "mufradat_alfajul_quran",
//     ar: "ألفاظ القرآن",
//     en: "Mufradat-Alfajul-Quraan",
//     hasRefs: true,
//   );

//   final String table;
//   final String ar;
//   final String en;
//   final bool hasRefs;

//   const Dict({
//     required this.table,
//     required this.ar,
//     required this.en,
//     this.hasRefs = false,
//   });
// }

enum Ddict {
  arEn,
  hanswehr,
  laneLexicon,
  mujamulGhoni,
  mujamulShihah, // has ref
  lisanAlArab, // has ref
  mujamulMuashiroh,
  mujamulWasith,
  mujamulMuhith,
  mufradatAlfajulQuran, // has ref
  maqayeesulLuga, // has ref
}

bool isDictHasRefs(Dict d) {
  return switch (d) {
    Dict.mujamulShihah ||
    Dict.lisanAlArab ||
    Dict.mufradatAlfajulQuran ||
    Dict.maqayeesulLuga => true,
    _ => false,
  };
}

String getDictTableName(Dict d) {
  switch (d) {
    case Dict.arEn:
      return "arEn";
    case Dict.hanswehr:
      return "hanswehr";
    case Dict.laneLexicon:
      return "lanelexcon";
    case Dict.mujamulGhoni:
      return "mujamul_ghoni";
    case Dict.mujamulShihah:
      return "mujamul_shihah";
    case Dict.lisanAlArab:
      return "lisanularab";
    case Dict.mujamulMuashiroh:
      return "mujamul_muashiroh";
    case Dict.mujamulWasith:
      return "mujamul_wasith";
    case Dict.mujamulMuhith:
      return "mujamul_muhith";
    case Dict.mufradatAlfajulQuran:
      return "mufradat_alfajul_quran";
    case Dict.maqayeesulLuga:
      return "maqayeesul_luga";
  }
}

// final List<DictEntry> dictNames = [
//   DictEntry(d: Dict.arEn, ar: "مباشر", en: "Dicrect dictionary"),
//   DictEntry(d: Dict.hanswehr, ar: "هانز", en: "Hans"),
//   DictEntry(d: Dict.laneLexicon, ar: "لين", en: "Lane"),
//   DictEntry(d: Dict.mujamulGhoni, ar: "الغني", en: "Ghani"),
//   DictEntry(d: Dict.mujamulShihah, ar: "مختار", en: "Mukhtar"),
//   DictEntry(d: Dict.lisanAlArab, ar: "لسان", en: "Lisan"),
//   DictEntry(d: Dict.mujamulMuashiroh, ar: "المعاصرة", en: "Muasiroh"),
//   DictEntry(d: Dict.mujamulWasith, ar: "الوسيط", en: "Wasat"),
//   DictEntry(d: Dict.mujamulMuhith, ar: "المحيط", en: "Muthktar"),
// ];

class ReaderPageSettings {
  final String bookHash;
  bool isQasidah;
  bool qasidahLineNum;
  bool isRmTashkil;
  bool isOpenLexiconDirecly;
  TextAlign textAlign;

  ReaderPageSettings({
    required this.bookHash,
    required this.isQasidah,
    required this.qasidahLineNum,
    required this.isRmTashkil,
    required this.isOpenLexiconDirecly,
    required this.textAlign,
  });

  static ReaderPageSettings def(String h) => ReaderPageSettings(
    bookHash: h,
    isQasidah: false,
    qasidahLineNum: true,
    isRmTashkil: false,
    isOpenLexiconDirecly: appSettingsNotifier.readerIsOpenLexiconDirecly,
    textAlign: TextAlign.justify,
  );

  bool isEqual(ReaderPageSettings rs) {
    return isQasidah == rs.isQasidah &&
        qasidahLineNum == rs.qasidahLineNum &&
        isRmTashkil == rs.isRmTashkil &&
        isOpenLexiconDirecly == rs.isOpenLexiconDirecly &&
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
      isOpenLexiconDirecly: isOpenLexiconDirecly ?? this.isOpenLexiconDirecly,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  @override
  String toString() {
    return 'ReaderPageSettings(isQasidah: $isQasidah, '
        'qliasidahLineNum: $qasidahLineNum, '
        'isRmTashkil: $isRmTashkil, '
        'isOpenLexiconDirecly: $isOpenLexiconDirecly, '
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
      isOpenLexiconDirecly: appSettingsNotifier.readerIsOpenLexiconDirecly,
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
      final file = File(join(parent.path, _readerSettingsSaveDir, '$hash.json'));
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

// final List<DictEntry> dictNames = [
//   DictEntry(d: Dict.arEn, ar: "مباشر", en: "Direct Dictionary"),
//   DictEntry(d: Dict.hanswehr, ar: "هانز", en: "Hans Wehr"),
//   DictEntry(d: Dict.laneLexicon, ar: "لين", en: "Lane Lexicon"),
//   DictEntry(d: Dict.mujamulGhoni, ar: "الغني", en: "Al-Ghani"),
//   DictEntry(d: Dict.mujamulShihah, ar: "مختار", en: "Mukhtar"),
//   DictEntry(d: Dict.lisanAlArab, ar: "لسان", en: "Lisan Al-Arab"),
//   DictEntry(d: Dict.mujamulMuashiroh, ar: "المعاصرة", en: "Al-Muashirah"),
//   DictEntry(d: Dict.mujamulWasith, ar: "الوسيط", en: "Al-Waseet"),
//   DictEntry(d: Dict.mujamulMuhith, ar: "المحيط", en: "Al-Muhit"),
//   DictEntry(d: Dict.mujamulShihah, ar: "الصحاح", en: "As-Shihah"),
//   DictEntry(d: Dict.maqayeesulLuga, ar: "مقاييس", en: "Maqayeesul-Luga"),
//   DictEntry(
//     d: Dict.mufradatAlfajulQuran,
//     ar: "ألفاظ القرآن",
//     en: "Mufradat-Alfajul-Quraan",
//   ),
// ];

class WordEntry {
  final String ar;
  final String nTk;
  final String cl;

  WordEntry({required this.ar, required this.cl, required this.nTk});
}
