import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

AppBar lexAppBar(
  BuildContext context,
  SearchLexiconsDatas datas,
  VoidCallback onChange,
) {
  final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
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

  return AppBar(
    title: title,
    titleSpacing: 0.0,
    actions: [
      IconButton(
        icon: const Icon(Icons.auto_awesome),
        tooltip: 'Toggle search suggestions',
        onPressed:
            datas.selectedDict != Dict.arEn &&
                datas.selectedWord.isNotEmpty &&
                SearchSuggestions.shouldShow
            ? () {
                datas.getAndShowResORSugg(
                  context,
                  onChange,
                  forceSugg: !datas.isShowingSugg,
                );
              }
            : null,
      ),
      IconButton(
        icon: Icon(bm ? Icons.bookmark : Icons.bookmark_border),
        tooltip: bm ? 'Unbookmark' : 'BookMark',
        onPressed: datas.selectedWord.isEmpty
            ? null
            : () {
                if (bm) {
                  BookMarks.rm(datas.selectedWord);
                } else {
                  BookMarks.add(datas.selectedWord);
                }
                onChange();
              },
      ),
    ],
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
                                  color: s
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                )
                              : null,
                          label: Text(
                            tw,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                          ),
                          selected: s,
                          labelStyle: s
                              ? ts.copyWith(color: cs.onPrimary)
                              : ts,
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

Widget sshowSearchSugg(
  BuildContext context,
  TextEditingController controller,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
  VoidCallback onChange,
) {
  if (datas.sugg.isEmpty) {
    return noRes(ts, datas.selectedWord);
  }
  final List<Dict> currDictSort = [];
  if (datas.sugg[datas.selectedDict] != null) {
    currDictSort.add(datas.selectedDict);
  }

  for (final d in allDictsExpeptArEn) {
    if (d != datas.selectedDict && datas.sugg[d] != null) {
      currDictSort.add(d);
    }
  }

  return ListView.separated(
    reverse: true,
    padding: const EdgeInsets.all(8),
    itemCount: currDictSort.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final d = currDictSort[index];
      final res = datas.sugg[d];

      return Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dictionary name chip
          Chip(
            backgroundColor: cs.primary.withAlpha(15),
            label: Text(d.ar, style: ts.copyWith(fontWeight: FontWeight.bold)),
          ),

          const SizedBox(width: 8), // spacing
          // Suggestions
          if (res != null && res.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // scroll starts from right
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: res
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(
                              r.replaceAll('_', ' '),
                              textDirection: TextDirection.rtl,
                            ),
                            labelStyle: ts.copyWith(color: cs.onSurface),
                            selected: false,
                            onSelected: (_) {
                              final cleanR = r.split(' ').first;
                              datas.words = datas.words.map((i) {
                                if (i == datas.selectedWord) return cleanR;
                                return i;
                              }).toList();

                              controller.text = datas.words.join(' ');

                              datas.selectedWord = r;
                              datas.selectedDict = d;
                              datas.resetSugg();
                              datas.loadResults(context, onChange);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      );
    },
  );
}
