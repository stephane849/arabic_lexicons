import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

Widget showSearchSugg(
  BuildContext context,
  TextEditingController controller,
  FocusNode focus,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
  VoidCallback onChange,
) {
  if (datas.sugg.isEmpty) return noRes(ts, datas.selectedWord);

  if (datas.suggDictSorted.isEmpty) {
    datas.suggDictSorted.add(datas.selectedDict);
    for (final d in allDictsExpeptArEn) {
      if (d != datas.selectedDict && datas.sugg[d] != null) {
        datas.suggDictSorted.add(d);
      }
    }
  }
  List<Widget> resList = [];

  for (int i = datas.suggDictSorted.length - 1; i >= 0; i--) {
    final d = datas.suggDictSorted[i];
    final Set<String>? res = datas.sugg[d];
    final bool isPrimary = d == datas.selectedDict;

    if (!isPrimary && (res?.isEmpty ?? true)) {
      continue;
    }

    resList.add(Divider(height: 12));
    resList.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
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
                    Icons.star,
                    size: 14,
                    color: isPrimary ? cs.primary : null,
                  ),
                Text(
                  d.ar,
                  style: ts.copyWith(
                    fontSize: (ts.fontSize ?? defaultArabicFontSize) * 0.8,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? cs.primary : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            res == null || res.isEmpty
                ? Center(
                    child: Text(
                      /* txt */ 'لا توجد نتائج في المعجم الحالي',
                      style: ts.copyWith(
                        fontSize: (ts.fontSize ?? defaultArabicFontSize) * 0.9,
                      ),
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
                            label: Text(
                              r.replaceAll('_', ' '),
                              textDirection: TextDirection.rtl,
                              style: ts.copyWith(
                                fontSize:
                                    (ts.fontSize ?? defaultArabicFontSize) *
                                    0.9,
                              ),
                            ),
                            onPressed: () {
                              focus.unfocus();
                              if (r != datas.selectedWord) {
                                final wordSet = datas.words.map((i) {
                                  if (i == datas.selectedWord) {
                                    return r;
                                  }
                                  return i;
                                }).toSet();

                                // bring the new word to the end
                                wordSet.remove(r);
                                wordSet.add(r);

                                datas.words = wordSet.toList();

                                controller.text = wordSet.join(' ');
                                controller
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(offset: controller.text.length),
                                );
                                datas.selectedWord = r;
                              }

                              // here we don't need to care about showing searchSuggestions
                              if (datas.selectedDict != d) {
                                datas.selectedDict = d;
                                datas.suggDictSorted.clear();
                              }
                              datas.isShowingSugg = false;

                              datas.loadResults(context, onChange);
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

  return Directionality(
    textDirection: TextDirection.rtl,
    child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16),
      reverse: true,
      child: Column(children: resList),
    ),
  );
}
