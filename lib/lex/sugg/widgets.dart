import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/data.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/lex/sugg/data.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

Widget showSearchSugg(
  BuildContext context,
  TextEditingController controller,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
) {
  if (datas.sugg.isEmpty) return noRes(ts, datas.selectedWord);

  if (datas.suggDictSorted.isEmpty) {
    datas.suggDictSorted.add(datas.selectedDict);
    for (final d in allDictsExpeptArEn) {
      if (d != datas.selectedDict) {
        datas.suggDictSorted.add(d);
      }
    }
  }

  List<Widget> resList = [];

  final titleStyle = ts.copyWith(
    fontSize: (ts.fontSize ?? defaultArabicFontSize) * 0.8,
    fontWeight: FontWeight.bold,
  );

  final choiceChipTxtStyle = ts.copyWith(
    fontSize: (ts.fontSize ?? defaultArabicFontSize) * 0.9,
  );
  final choiceChiprootIcosize = (ts.fontSize ?? defaultArabicFontSize) * 0.65;

  final entryPadd = const EdgeInsets.symmetric(
    horizontal: 16,
  ).copyWith(bottom: 8);

  resList.add(SizedBox(height: 130));
  for (int i = datas.suggDictSorted.length - 1; i >= 0; i--) {
    final d = datas.suggDictSorted[i];
    final Set<SuggestionEntry>? res = datas.sugg[d];
    final bool isPrimary = d == datas.selectedDict;

    if (!isPrimary && (res?.isEmpty ?? true)) {
      continue;
    }

    resList.add(Divider(height: 12));
    resList.add(
      Padding(
        padding: entryPadd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 4,
              // crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPrimary)
                  Icon(
                    Icons.check_circle,
                    size: choiceChiprootIcosize,
                    color: isPrimary ? cs.primary : null,
                  ),
                Text(
                  d.ar,
                  style: isPrimary
                      ? titleStyle.copyWith(color: cs.primary)
                      : titleStyle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            res == null || res.isEmpty
                ? Center(
                    child: Text(
                      /* txt */ 'لا توجد نتائج لـ ${datas.selectedWord}',
                      style: choiceChipTxtStyle,
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: res.map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ActionChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 5,
                              children: [
                                if (r.isRoot)
                                  Icon(
                                    Icons.star,
                                    size: choiceChiprootIcosize,
                                    color: cs.primary,
                                  ),
                                Text(
                                  r.word.replaceAll('_', ' '),
                                  textDirection: TextDirection.rtl,
                                  style: choiceChipTxtStyle,
                                ),
                              ],
                            ),
                            onPressed: () {
                              datas.inputFocusNode.unfocus();
                              if (r.word != datas.selectedWord) {
                                final wordSet = datas.words.map((i) {
                                  if (i == datas.selectedWord) {
                                    return r.word;
                                  }
                                  return i;
                                }).toSet();

                                // bring the new word to the end
                                wordSet.remove(r.word);
                                wordSet.add(r.word);

                                datas.words = wordSet.toList();

                                controller.text = wordSet.join(' ');
                                controller
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(offset: controller.text.length),
                                );
                                datas.selectedWord = r.word;
                              }

                              // here we don't need to care about showing searchSuggestions
                              if (datas.selectedDict != d) {
                                datas.selectedDict = d;
                                datas.suggDictSorted.clear();
                              }
                              datas.isShowingSugg = false;

                              datas.getAndShowResORSugg(
                                context,
                                forceRes: true,
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  resList.add(SizedBox(height: 8));
  return SliverToBoxAdapter(child: Column(children: resList));
}
