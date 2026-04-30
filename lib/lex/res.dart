import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/data.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

Widget showRes(
  BuildContext context,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
) {
  if (datas.resultsAreEmpty) {
    return noRes(ts, datas.selectedWord);
  }

  final curDict = datas.selectedDict;
  if (curDict == Dict.arEn) {
    return _showArEnRes(ts, datas);
  }

  if (curDict == Dict.hanswehr || curDict == Dict.laneLexicon) {
    return _hansLaneView(context, ts, datas, cs);
  }
  return _arabicLexView(ts, datas);
}

Widget noRes(TextStyle ts, String? currWord) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.all(16.0).copyWith(top: 32),
      child: Center(child: noResUniversal(currWord)),
    ),
  );
}

Widget noResUniversal(
  String? currWord, {
  String noWordAr = 'ابجث عن كلمة',
  String noWordEn = 'Search for a word',
  String noResAr = "لا توجد نتائج لـ",
  String noResEn = "No resuts for",
}) {
  final inAr = appSettingsNotifier.useMoreArabic;
  final arStyle = TextStyle(
    fontFamily: fontTajawal,
    fontWeight: FontWeight.w500,
  );

  Widget w;
  if (currWord == null || currWord.isEmpty) {
    w = Text(
      inAr ? noWordAr : noWordEn,
      textDirection: inAr ? TextDirection.rtl : TextDirection.ltr,
      style: inAr ? arStyle : null,
    );
  } else {
    w = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: inAr ? noResAr : noResEn),
          TextSpan(text: ' $currWord', style: inAr ? null : arStyle),
        ],
      ),
      style: inAr ? arStyle : null,
      textDirection: inAr ? TextDirection.rtl : TextDirection.ltr,
    );
  }

  return w;
}

Widget _showArEnRes(TextStyle ts, SearchLexiconsDatas datas) {
  return SliverToBoxAdapter(
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // padding: scrollPadding,
        child: DataTable(
          dataTextStyle: ts,
          // dividerThickness: 0.5,
          columnSpacing: 18.0,
          headingTextStyle: ts.copyWith(fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Word')),
            DataColumn(label: Text('Meanings')),
            DataColumn(label: Text('Root')),
          ],
          rows: datas.arEnRes.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(e.word)),
                // DataCell(Text(e.def)),
                DataCell(SelectableText(e.def, style: ts)),
                // DataCell(Text(e.root)),
                DataCell(
                  InkWell(
                    onTap: () {
                      datas.onChangeTxt(appendTxt: e.root.split('/')[0]);
                    },
                    child: Text(e.root),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ),
  );
}

Widget _hansLaneView(
  BuildContext context,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
) {
  return SliverList.separated(
    itemCount: datas.dbRes.length,
    separatorBuilder: (context, index) =>
        const Divider(height: 0, thickness: 0.5),
    itemBuilder: (context, index) {
      final row = datas.dbRes[index];
      String txt = row.meanings;
      return AutoScrollTag(
        key: ValueKey(index),
        controller: datas.scrollController,
        index: index,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () {
            final cleanTxt = htmlToPlainText(txt);
            final cleanTxtBr = htmlToPlainTextWithLineBr(txt);
            showSelectableParagraph(
              context,
              () => cleanTxt,
              TextAlign.left,
              TextDirection.ltr,
              ts.copyWith(fontFamily: fontAmiri, height: fontAmiriLineHeight),
              fullTextFuncSecondary: () => cleanTxtBr,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _engMeaningView(txt, ts.fontSize!, cs, row.isHi),
          ),
        ),
      );
    },
  );
}

Widget _arabicLexView(TextStyle ts, SearchLexiconsDatas datas) {
  final showWordTitle = datas.selectedDict.showTitle;
  return SliverList.separated(
    itemCount: datas.dbRes.length,
    separatorBuilder: (context, index) =>
        const Divider(height: 0, thickness: 0.5),
    itemBuilder: (context, index) {
      final row = datas.dbRes[index];
      final txt = showWordTitle ? '${row.word}: ${row.meanings}' : row.meanings;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _arMeaningView(txt, ts),
      );
    },
  );
}

Widget _arMeaningView(String txt, TextStyle ts) {
  return SelectionArea(
    magnifierConfiguration: TextMagnifierConfiguration.disabled,
    child: Text(
      txt,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: ts.copyWith(
        // height: 2,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    ),
  );
}

Widget _engMeaningView(
  String html,
  double fsz,
  ColorScheme cs,
  bool isHighResult,
) {
  return Html(
    data: html,
    style: {
      'body': Style(
        fontFamily: fontAmiri,
        lineHeight: LineHeight.number(fontAmiriLineHeight),
        direction: TextDirection.ltr,
        textAlign: TextAlign.left,
        fontSize: FontSize(fsz),
        color: isHighResult ? cs.primary : null,
      ),
      'strong': Style(fontWeight: FontWeight.bold),
      'i': Style(fontStyle: FontStyle.italic),
      'center': Style(textAlign: TextAlign.center),
      '.high': Style(color: cs.onPrimary, backgroundColor: cs.primary),
    },
  );
}
