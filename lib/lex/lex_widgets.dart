import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/res.dart';
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
  if (datas.selectedWord != null) {
    title = Text.rich(
      TextSpan(
        // style: ,
        children: [
          TextSpan(text: datas.selectedDict.ar, style: fontStyle),
          TextSpan(
            text: ': ${datas.selectedWord!.replaceAll('_', ' ')} ',
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
        icon: Icon(bm ? Icons.bookmark : Icons.bookmark_border),
        onPressed: datas.selectedWord == null
            ? null
            : () {
                if (bm) {
                  BookMarks.rm(datas.selectedWord!);
                } else {
                  BookMarks.add(datas.selectedWord!);
                }
                onChange();
              },
      ),
    ],
  );
}

Future<({Dict de, String? word})?> showWordPickerBottomSheet(
  BuildContext context,
  SearchLexiconsDatas datas,
  TextStyle ts,
) {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<({Dict de, String? word})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final sh = MediaQuery.of(context).size.height;
          final maxHeight = sh * 0.9;
          final minHeight = sh * 0.4;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                minHeight: minHeight,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16).copyWith(top: 12),
                child: Column(
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,

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
                          child: Wrap(
                            textDirection: TextDirection.rtl,
                            spacing: 8,
                            runSpacing: 8,
                            children: datas.words!.map((word) {
                              final s = datas.selectedWord == word;
                              final bm = BookMarks.isSet(word);
                              var tw = word.replaceAll('_', ' ').trim();
                              if (tw.length > 30) {
                                tw = '${tw.substring(0, 30)}…';
                              }
                              return InkWell(
                                onLongPress: () {
                                  if (bm) {
                                    BookMarks.rm(word);
                                  } else {
                                    BookMarks.add(word);
                                  }
                                  setState(() {});
                                },
                                child: ChoiceChip(
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

                                  labelStyle: ts.copyWith(
                                    color: s ? cs.onPrimary : cs.onSurface,
                                  ),
                                  selectedColor: cs.primary,
                                  onSelected: (value) {
                                    Navigator.pop(context, (
                                      de: datas.selectedDict,
                                      word: word,
                                    ));
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    if (!datas.areWordsEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        child: Divider(),
                      ),

                    Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: Dict.values.map((dict) {
                        final s = datas.selectedDict == dict;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(dict.ar),
                          tooltip: dict.en,
                          selected: s,
                          labelStyle: ts.copyWith(
                            color: s ? cs.onPrimary : cs.onSurface,
                          ),
                          selectedColor: cs.primary,
                          onSelected: (value) {
                            Navigator.pop(context, (
                              de: dict,
                              word: datas.selectedWord,
                            ));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                              datas.words = datas.words!.map((i) {
                                if (i == datas.selectedWord) return cleanR;
                                return i;
                              }).toList();

                              controller.text = datas.words!.join(' ');

                              datas.selectedWord = r;
                              datas.selectedDict = d;
                              datas.resetSugg();
                              datas.loadResults(onChange);
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
