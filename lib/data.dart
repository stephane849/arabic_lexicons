import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/db.dart';
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

class DictEntry {
  final Dict d;
  final String ar;
  final String en;

  const DictEntry({required this.d, required this.ar, required this.en});
}

class SearchLexiconsDatas {
  DictEntry selectedDict;

  List<String>? words;
  String? selectedWord;

  List<Map<String, dynamic>>? dbRes;
  List<Entry>? arEnRes;
  bool _resLoaded = false;

  SearchLexiconsDatas({
    required this.selectedDict,
    this.words,
    this.selectedWord,
    this.dbRes,
    this.arEnRes,
  });

  void resetWords() {
    words = null;
    selectedWord = null;
  }

  void resetRes() {
    _resLoaded = false;
    dbRes = null;
    arEnRes = null;
  }

  void resetAll() {
    resetWords();
    resetRes();
  }

  bool get isSelectedWordEmpty {
    return selectedWord == null || selectedWord!.isEmpty;
  }

  bool get areWordsEmpty {
    return words == null || words!.isEmpty;
  }

  bool get hasResuts {
    return dbRes != null || arEnRes != null;
  }

  bool get resLoaded {
    return _resLoaded;
  }

  bool selectWord(String? word, VoidCallback onChange) {
    if (word == null || word.isEmpty || word == selectedWord) return false;

    selectedWord = word;
    resetRes();
    onChange();

    loadResults(onChange);
    return true;
  }

  bool selectDict(DictEntry de, VoidCallback onChange) {
    if (selectedDict.d == de.d) return false;

    selectedDict = de;
    resetRes();
    onChange();

    loadResults(onChange);
    return true;
  }

  Future<void> loadResults(VoidCallback after) async {
    _resLoaded = false;
    if (isSelectedWordEmpty) {
      return;
    }

    switch (selectedDict.d) {
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
        dbRes = await DbService.getByWordWith3Rows(
          getDictTableName(selectedDict.d),
          selectedWord,
        );
    }

    // await Future.delayed(
    //   Duration(seconds: 1),
    // ); // for testing, looking at the loader lol
    _resLoaded = true;
    after();
  }
}

enum Dict {
  arEn,
  hanswehr,
  laneLexicon,
  mujamulGhoni,
  mujamulShihah,
  lisanAlArab,
  mujamulMuashiroh,
  mujamulWasith,
  mujamulMuhith,
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

final List<DictEntry> dictNames = [
  DictEntry(d: Dict.arEn, ar: "مباشر", en: "Direct Dictionary"),
  DictEntry(d: Dict.hanswehr, ar: "هانز", en: "Hans Wehr"),
  DictEntry(d: Dict.laneLexicon, ar: "لين", en: "Lane Lexicon"),
  DictEntry(d: Dict.mujamulGhoni, ar: "الغني", en: "Al-Ghani"),
  DictEntry(d: Dict.mujamulShihah, ar: "مختار", en: "Mukhtar"),
  DictEntry(d: Dict.lisanAlArab, ar: "لسان", en: "Lisan Al-Arab"),
  DictEntry(d: Dict.mujamulMuashiroh, ar: "المعاصرة", en: "Al-Muashirah"),
  DictEntry(d: Dict.mujamulWasith, ar: "الوسيط", en: "Al-Waseet"),
  DictEntry(d: Dict.mujamulMuhith, ar: "المحيط", en: "Al-Muhit"),
];

class WordEntry {
  final String ar;
  final String nTk;
  final String cl;

  WordEntry({required this.ar, required this.cl, required this.nTk});
}
