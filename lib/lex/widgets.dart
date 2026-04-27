import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/data.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

Widget lexAppBar(
  BuildContext context,
  SearchLexiconsDatas datas,
  VoidCallback onChange,
  TextStyle arabicFontStyle,
) {
  final fontStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontFamily: arabicFontStyle.fontFamily,
  );

  Widget title;
  if (datas.selectedWord.isNotEmpty) {
    title = Text.rich(
      TextSpan(
        // style: ,
        children: [
          TextSpan(text: datas.selectedDict.ar, style: fontStyle),
          TextSpan(
            text: ': ${datas.selectedWord.replaceAll('_', ' ')} ',
            style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
          ),
          // if (bm) WidgetSpan(child: Icon(Icons.bookmark)),
        ],
      ),
      textDirection: TextDirection.rtl,
    );
  } else {
    title = Text.rich(TextSpan(text: datas.selectedDict.ar, style: fontStyle));
  }

  final bm = BookMarks.isSet(datas.selectedWord);

  return Directionality(
    textDirection: TextDirection.ltr,
    child: SliverAppBar(
      title: title,
      titleSpacing: 0.0,
      floating: true,
      snap: true,
      pinned: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          tooltip: 'Toggle search suggestions',
          onPressed:
              datas.selectedWord.isNotEmpty && SearchSuggestions.shouldShow
              ? () {
                  datas.inputFocusNode.unfocus();
                  final ss = datas.isShowingSugg;
                  datas.getAndShowResORSugg(
                    context,
                    forceSugg: !ss,
                    forceRes: ss,
                  );
                }
              : null,
        ),
        IconButton(
          icon: Icon(bm ? Icons.bookmark : Icons.bookmark_border),
          tooltip: bm ? 'Unbookmark' : 'BookMark',
          onPressed: datas.selectedWord.isEmpty || datas.isShowingSugg
              ? null
              : () async {
                  if (bm) {
                    final confirm = await showConfirmDialog(
                      context,
                      'Remove Bookmark',
                      message: 'Remove: ${datas.selectedWord}',
                      distructive: true,
                      confirmText: 'Remove',
                    );
                    if (confirm != true) return;
                    BookMarks.rm(datas.selectedWord);
                  } else {
                    BookMarks.add(datas.selectedWord);
                  }
                  onChange();
                },
        ),
      ],
    ),
  );
}

class WordDictPickerResult {
  final Dict? d;
  final String? word;

  const WordDictPickerResult({this.d, this.word});
}

Future<WordDictPickerResult?> showWordPickerBottomSheet(
  BuildContext context,
  SearchLexiconsDatas datas,
  TextStyle ts,
) {
  final cs = Theme.of(context).colorScheme;
  final isEng = appSettingsNotifier.dictNamesEn;

  ts = ts.copyWith(fontSize: 0.85 * (ts.fontSize ?? defaultArabicFontSize));

  return showModalBottomSheet<WordDictPickerResult?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final sh = MediaQuery.of(context).size.height;
      final maxHeight = sh * 0.9;
      final minHeight = sh * 0.4;

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          minHeight: minHeight,
          minWidth: double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            // textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withAlpha(70),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Scroll
              if (!datas.areWordsEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: datas.words.map((word) {
                        final s = datas.selectedWord == word;
                        final bm = BookMarks.isSet(word);
                        var tw = word.replaceAll('_', ' ').trim();
                        if (tw.length > 30) {
                          tw = '${tw.substring(0, 30)}…';
                        }
                        return ChoiceChip(
                          showCheckmark: false,
                          avatar: bm
                              ? Icon(
                                  Icons.bookmark,
                                  color: s ? cs.onPrimary : cs.onSurfaceVariant,
                                )
                              : null,
                          label: Text(
                            tw,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                          ),
                          selected: s,
                          labelStyle: s ? ts.copyWith(color: cs.onPrimary) : ts,
                          selectedColor: cs.primary,
                          onSelected: (value) {
                            if (s) {
                              Navigator.pop(context);
                              return;
                            }
                            Navigator.pop(
                              context,
                              WordDictPickerResult(word: word),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),

              if (!datas.areWordsEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Divider(height: 0),
                ),

              Align(
                alignment: isEng ? Alignment.topLeft : Alignment.topRight,
                child: Wrap(
                  textDirection: isEng ? TextDirection.ltr : TextDirection.rtl,
                  spacing: 8,
                  runSpacing: 8,
                  children: allDicts.map((dict) {
                    final s = datas.selectedDict == dict;
                    return ChoiceChip(
                      showCheckmark: false,
                      label: Text(isEng ? dict.en : dict.ar),
                      tooltip: dict.enLong,
                      selected: s,
                      labelStyle: isEng
                          ? TextStyle(color: s ? cs.onPrimary : cs.onSurface)
                          : s
                          ? ts.copyWith(color: cs.onPrimary)
                          : ts,
                      selectedColor: cs.primary,
                      onSelected: (value) {
                        if (s) {
                          Navigator.pop(context);
                          return;
                        }
                        Navigator.pop(context, WordDictPickerResult(d: dict));
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
