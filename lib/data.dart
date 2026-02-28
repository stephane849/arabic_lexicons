import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lex/sugg.dart';
import 'package:flutter/material.dart';

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

  String? suggLastWord;
  Map<Dict, Set<String>> sugg = {};
  bool isShowingSugg = false;
  List<Dict> suggDictSorted = [];

  List<String>? words;
  String? selectedWord;

  List<Map<String, dynamic>>? dbRes;
  List<Entry>? arEnRes;
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
    // resetSugg();
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
    isShowingSugg = false;
    onChange();

    await loadResults(onChange);
    if (resultsAreEmpty) loadSearchSugg(onChange);
  }

  void loadSearchSugg(VoidCallback onChange) {
    if (suggLastWord == selectedWord) {
      suggDictSorted.clear();
      isShowingSugg = selectedWord != null;
      onChange();
      return;
    }

    resetSugg();
    if (selectedWord == null || selectedWord!.isEmpty) return;

    isShowingSugg = true;
    suggLastWord = selectedWord;
    sugg = SearchSuggestions.getSuggestions(selectedWord!);
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
        arEnRes = ArEnDict.findWord(selectedWord);

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

final List<Dict> allDicts = List.unmodifiable(Dict.values);
final List<Dict> allDictsExpeptArEn = List.unmodifiable(
  allDicts.where((d) => d != Dict.arEn),
);

enum Dict {
  arEn(
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
    table: "hanswehr",
    ar: "هانز",
    en: "Hans Wehr Dictionary",
    description:
        "Modern Arabic–English dictionary compiled by Hans Wehr. "
        "Widely used academic reference organized by triliteral roots.",
    link: "https://en.wikipedia.org/wiki/Hans_Wehr_dictionary",
  ),

  laneLexicon(
    table: "lanelexcon",
    ar: "لين",
    en: "Lane’s Arabic-English Lexicon",
    description:
        "Comprehensive 19th-century Arabic-English lexicon by Edward William Lane, "
        "based on major classical sources.",
    link: "https://en.wikipedia.org/wiki/Edward_William_Lane",
  ),

  mujamulGhoni(
    table: "mujamul_ghoni",
    ar: "الغني",
    en: "Al-Muʿjam al-Ghani",
    description:
        "Contemporary Arabic dictionary focusing on modern vocabulary and usage.",
  ),

  mujamulShihah(
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
    table: "mujamul_muashiroh",
    ar: "المعاصرة",
    en: "Al-Muʿjam al-Muʿasirah",
    description:
        "Modern Arabic dictionary emphasizing contemporary terminology and usage.",
  ),

  mujamulWasith(
    table: "mujamul_wasith",
    ar: "الوسيط",
    en: "Al-Muʿjam al-Wasit",
    description:
        "Standard modern Arabic dictionary published by the Arabic Language Academy in Cairo.",
    link: "https://ar.wikipedia.org/wiki/المعجم_الوسيط",
  ),

  mujamulMuhith(
    table: "mujamul_muhith",
    ar: "المحيط",
    en: "Al-Qamus al-Muhit",
    description:
        "Influential classical dictionary by al-Firuzabadi (8th century AH), "
        "widely cited in later lexicons.",
    link: "https://ar.wikipedia.org/wiki/القاموس_المحيط",
  ),

  maqayeesulLuga(
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
    table: "mufradat_alfajul_quran",
    ar: "مفردات",
    en: "Mufradat Alfaz al-Qur’an",
    description:
        "Qur’anic lexicon by al-Raghib al-Isfahani, "
        "analyzing vocabulary and semantic nuances of Qur’anic terms.",
    link: "https://ar.wikipedia.org/wiki/المفردات_في_غريب_القرآن",
    hasRefs: true,
  );

  final String table;
  final String ar;
  final String en;
  final String description;
  final String? link;
  final bool hasRefs;

  const Dict({
    required this.table,
    required this.ar,
    required this.en,
    required this.description,
    this.link,
    this.hasRefs = false,
  });
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
  bool isQasidah;
  bool isRmTashkil;
  bool isOpenLexiconDirecly;
  TextAlign textAlign;

  ReaderPageSettings({
    required this.isQasidah,
    required this.isRmTashkil,
    required this.isOpenLexiconDirecly,
    required this.textAlign,
  });

  bool isEqual(ReaderPageSettings rs) {
    return isQasidah == rs.isQasidah &&
        isRmTashkil == rs.isRmTashkil &&
        isOpenLexiconDirecly == rs.isOpenLexiconDirecly &&
        textAlign == rs.textAlign;
  }

  ReaderPageSettings copyWith({
    bool? isQasidah,
    bool? isRmTashkil,
    bool? isOpenLexiconDirecly,
    TextAlign? textAlign,
  }) {
    return ReaderPageSettings(
      isQasidah: isQasidah ?? this.isQasidah,
      isRmTashkil: isRmTashkil ?? this.isRmTashkil,
      isOpenLexiconDirecly: isOpenLexiconDirecly ?? this.isOpenLexiconDirecly,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  @override
  String toString() {
    return 'ReaderPageSettings(isQasidah: $isQasidah, '
        'isRmTashkil: $isRmTashkil, '
        'isOpenLexiconDirecly: $isOpenLexiconDirecly, '
        'textAlign: $textAlign)';
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
