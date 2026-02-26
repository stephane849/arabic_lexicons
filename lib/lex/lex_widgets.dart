import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
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
            text: ': ${datas.selectedWord} ',
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

Future<({DictEntry de, String? word})?> showWordPickerBottomSheet(
  BuildContext context,
  SearchLexiconsDatas datas,
  TextStyle ts,
) {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<({DictEntry de, String? word})?>(
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
          final maxHeight = sh * 0.8;
          final minHeight = sh * 0.35;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                minHeight: minHeight,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    // drag handle
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withAlpha(70),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Text('${words.length}'),
                    const SizedBox(height: 12),

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
                                  label: Text(word),
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
                      children: dictNames.map((dict) {
                        final s = datas.selectedDict.d == dict.d;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(dict.ar),
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
