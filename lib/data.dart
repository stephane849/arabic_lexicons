import 'package:ara_dict/ar_en/ar_en.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

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
  final AutoScrollController scrollController;

  SearchLexiconsDatas({required this.scrollController});

  Dict selectedDict = Dict.values.first;

  String preQuery = '';
  // String? suggLastWord;
  Map<Dict, Set<String>> sugg = {};
  bool isShowingSugg = false;
  List<Dict> suggDictSorted = [];

  List<String> words = [];
  String selectedWord = "";

  List<DbRow> dbRes = [];
  List<ArEnEntry> arEnRes = [];
  bool resLoaded = false;

  void resetSugg() {
    sugg = {};
    isShowingSugg = false;
  }

  void resetWords() {
    words.clear();
    selectedWord = "";
  }

  void resetRes() {
    resLoaded = false;
    dbRes = [];
    arEnRes = [];
  }

  void resetAll() {
    resetSugg();
    resetWords();
    resetRes();
  }

  bool get isSelectedWordEmpty {
    return selectedWord.isEmpty;
  }

  bool get areWordsEmpty {
    return words.isEmpty;
  }

  bool get resultsAreEmpty => (dbRes.isEmpty) && (arEnRes.isEmpty);

  Future<void> setSelectWord(
    BuildContext context,
    String? word,
    VoidCallback onChange,
  ) async {
    word ??= '';
    if (word == selectedWord) return;

    selectedWord = word;

    resetRes();
    resetSugg();
    onChange();

    await loadResults(context, onChange);
    if (resultsAreEmpty) loadSearchSugg(onChange);
  }

  Future<void> setSelectDict(
    BuildContext context,
    Dict de,
    VoidCallback onChange,
  ) async {
    if (selectedDict == de) return;

    selectedDict = de;

    resetRes();
    resetSugg();
    onChange();

    await loadResults(context, onChange);
    if (resultsAreEmpty) loadSearchSugg(onChange);
  }

  Future<void> loadSearchSugg(
    VoidCallback onChange, {
    bool force = false,
  }) async {
    if (!SearchSuggestions.shouldShow) return;

    resetSugg();
    if (selectedWord.isEmpty) return;

    isShowingSugg = true;
    // suggLastWord = selectedWord;
    sugg = await SearchSuggestions.getSuggestions(selectedWord);
    onChange();
  }

  Future<void> loadResults(BuildContext context, VoidCallback after) async {
    if (isSelectedWordEmpty) {
      resLoaded = true;
      after();
      return;
    }
    resLoaded = false;

    switch (selectedDict) {
      case Dict.arEn:
        arEnRes = await ArEnDict.findWord(selectedWord);
      default:
        dbRes = await DbService.search(selectedDict, selectedWord);
    }

    // await Future.delayed(
    //   Duration(seconds: 1),
    // ); // for testing, looking at the loader lol
    resLoaded = true;
    after();

    if (dbRes.isNotEmpty &&
        (selectedDict == Dict.hanswehr || selectedDict == Dict.laneLexicon)) {
      for (int i = 0; i < dbRes.length; i++) {
        if (dbRes[i].isHi) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            scrollController.scrollToIndex(
              i,
              preferPosition: AutoScrollPosition.begin,
              duration: const Duration(milliseconds: 120),
            );
          });
          break;
        }
      }
    }
  }

  /// for onSettings change
  void getAndShowResORSugg(
    BuildContext context,
    VoidCallback onChange, {
    bool reset = true,
    bool forceSugg = false,
    bool forceRes = false,
  }) async {
    if (reset) {
      resetRes();
      resetSugg();
      onChange();
      if (selectedWord.isEmpty) return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (forceSugg) {
        await loadSearchSugg(onChange);
        return;
      }

      if (forceRes ||
          Dict.arEn == selectedDict ||
          !appSettingsNotifier.showSearchSugg ||
          appSettingsNotifier.showResutlsDirecly) {
        await loadResults(context, onChange);
        if (forceRes) return;
      }

      if (resultsAreEmpty && SearchSuggestions.shouldShow) {
        await loadSearchSugg(onChange);
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
  dbRes length: ${dbRes.length},
  arEnRes length: ${arEnRes.length},
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
    table: "arEn",
    ar: "مباشر",
    en: "Direct",
    enLong: "Aratools Arabic–English",
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
    en: "Hanswehr",
    enLong: "Hans Wehr Dictionary",
    description:
        "Modern Arabic–English dictionary compiled by Hans Wehr. "
        "Widely used academic reference organized by triliteral roots.",
    link: "https://en.wikipedia.org/wiki/Hans_Wehr_dictionary",
  ),

  laneLexicon(
    table: "lanelexcon",
    ar: "لين",
    en: "Lanes",
    enLong: "Lane’s Arabic-English Lexicon",
    description:
        "Comprehensive 19th-century Arabic-English lexicon by Edward William Lane, "
        "based on major classical sources.",
    link: "https://en.wikipedia.org/wiki/Edward_William_Lane",
  ),

  mujamulGhoni(
    table: "mujamul_ghoni",
    ar: "الغني",
    en: "Ghani",
    enLong: "Al-Muʿjam al-Ghani",
    description:
        "Contemporary Arabic dictionary focusing on modern vocabulary and usage.",
  ),

  mujamulShihah(
    table: "mujamul_shihah",
    ar: "الصحاح",
    en: "Sihah",
    enLong: "Al-Sihah (al-Jawhari)",
    description:
        "Classical Arabic dictionary by al-Jawhari (4th century AH), "
        "one of the foundational root-based lexicons.",
    link: "https://ar.wikipedia.org/wiki/الصحاح_في_اللغة",
    hasRefs: true,
  ),

  lisanAlArab(
    table: "lisanularab",
    ar: "لسان",
    en: "Lisan",
    enLong: "Lisan al-Arab",
    description:
        "Major classical Arabic lexicon compiled by Ibn Manzur (7th century AH), "
        "drawing from earlier authoritative sources.",
    link: "https://en.wikipedia.org/wiki/Lisan_al-Arab",
    hasRefs: true,
  ),

  mujamulMuashiroh(
    table: "mujamul_muashiroh",
    ar: "المعاصرة",
    en: "Muasiroh",
    enLong: "Al-Muʿjam al-Muʿasirah",
    description:
        "Modern Arabic dictionary emphasizing contemporary terminology and usage.",
  ),

  mujamulWasith(
    table: "mujamul_wasith",
    ar: "الوسيط",
    en: "Wasit",
    enLong: "Al-Muʿjam al-Wasit",
    description:
        "Standard modern Arabic dictionary published by the Arabic Language Academy in Cairo.",
    link: "https://ar.wikipedia.org/wiki/المعجم_الوسيط",
  ),

  mujamulMuhith(
    table: "mujamul_muhith",
    ar: "المحيط",
    en: "Muhit",
    enLong: "Al-Qamus al-Muhit",
    description:
        "Influential classical dictionary by al-Firuzabadi (8th century AH), "
        "widely cited in later lexicons.",
    link: "https://ar.wikipedia.org/wiki/القاموس_المحيط",
  ),

  maqayeesulLuga(
    table: "maqayeesul_luga",
    ar: "مقاييس",
    en: "Maqayes",
    enLong: "Maqayis al-Lugha",
    description:
        "Root-based semantic analysis by Ibn Faris (4th century AH), "
        "reducing each root to its core conceptual meanings.",
    link: "https://ar.wikipedia.org/wiki/مقاييس_اللغة",
    hasRefs: true,
  ),

  mufradatAlfajulQuran(
    table: "mufradat_alfajul_quran",
    ar: "مفردات",
    en: "Mufradat",
    enLong: "Mufradat Alfaz al-Qur’an",
    description:
        "Qur’anic lexicon by al-Raghib al-Isfahani, "
        "analyzing vocabulary and semantic nuances of Qur’anic terms.",
    link: "https://ar.wikipedia.org/wiki/المفردات_في_غريب_القرآن",
    hasRefs: true,
  );

  final String table;
  final String ar;
  final String en;
  final String enLong;
  final String description;
  final String? link;
  final bool hasRefs;

  const Dict({
    required this.table,
    required this.ar,
    required this.en,
    required this.enLong,
    required this.description,
    this.link,
    this.hasRefs = false,
  });

  bool get showTitle => this == mujamulGhoni;
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

bool isDictHasRefs(Dict d) {
  return switch (d) {
    Dict.mujamulShihah ||
    Dict.lisanAlArab ||
    Dict.mufradatAlfajulQuran ||
    Dict.maqayeesulLuga => true,
    _ => false,
  };
}

class WordEntry {
  final String ar;
  final String nTk;
  final String cl;

  WordEntry({required this.ar, required this.cl, required this.nTk});
}
