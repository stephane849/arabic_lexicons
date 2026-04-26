import 'package:ara_dict/ar_en/ar_en.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/lex/sugg_cache.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchLexiconsDatas {
  final AutoScrollController scrollController;
  final FocusNode inputFocusNode;
  final Future<void> Function({String? txt}) onChangeTxt;
  final void Function(void Function()) setState;

  SearchLexiconsDatas({
    required this.scrollController,
    required this.onChangeTxt,
    required this.setState,
    required this.inputFocusNode,
    // this.selectedDict = Dict.arEn,
  });

  Dict selectedDict = allDicts.first;

  String preQuery = '';

  bool isShowingSugg = false;
  SuggestionEntries sugg = {};
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

  // Future<void> setSelectWord(BuildContext context, String? word) async {
  //   word ??= '';
  //   if (word == selectedWord) return;
  //   selectedWord = word;

  //   await getAndShowResORSugg(context);
  // }

  // Future<void> setSelectDict(BuildContext context, Dict de) async {
  //   if (selectedDict == de) return;

  //   selectedDict = de;

  //   await getAndShowResORSugg(context);
  // }

  Future<void> _loadSearchSugg() async {
    sugg = await SearchSuggestions.getSuggestions(selectedWord);
    isShowingSugg = true;
    rebuild();
  }

  void scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        // print("scroll b: ${scrollController.offset}");
        scrollController.jumpTo(0);
        // print("scroll a: ${scrollController.offset}");
      }
    });
  }

  void rebuild() => setState(() {});

  Future<void> _loadResults(BuildContext context) async {
    if (selectedDict == Dict.arEn) {
      arEnRes = await ArEnDict.findWord(selectedWord);
    } else {
      dbRes = await DbService.search(selectedDict, selectedWord);
    }

    resLoaded = true;
    rebuild();

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
  Future<void> getAndShowResORSugg(
    BuildContext context, {
    // bool reset = true,
    bool forceSugg = false,
    bool forceRes = false,
  }) async {
    if (forceSugg && forceRes) {
      throw Exception('Can not have both forceSugg and forceRes == true');
    }

    resetRes();
    resetSugg();
    if (selectedWord.isEmpty) {
      resLoaded = true;
      rebuild();
      return;
    }
    rebuild();
    scrollToTop();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (forceSugg) {
        await _loadSearchSugg();
        rebuild();
        return;
      }

      if (forceRes ||
          Dict.arEn == selectedDict ||
          appSettingsNotifier.showResutlsDirecly) {
        await _loadResults(context);

        if (forceRes) {
          rebuild();
          return;
        }
      }

      if (resultsAreEmpty && SearchSuggestions.shouldShow) {
        await _loadSearchSugg();
      }
      // rebuild only once
      rebuild();
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
