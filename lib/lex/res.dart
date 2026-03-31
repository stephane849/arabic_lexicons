import 'package:ara_dict/ar_en/ar_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:ara_dict/data.dart';
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
    return _showArEnRes(ts, datas.arEnRes);
  }

  if (curDict == Dict.hanswehr || curDict == Dict.laneLexicon) {
    return _hansLaneView(ts, datas, cs);
  }
  return _arabicLexView(ts, datas);
}

Widget noRes(TextStyle ts, String? currWord) {
  String txt;
  if (currWord == null || currWord.isEmpty) {
    txt = "ابجث عن كلمة";
  } else {
    txt = "لا توجد نتائج لـ: $currWord";
  }

  return SliverFillRemaining(
    hasScrollBody: false,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(txt, textDirection: TextDirection.rtl, style: ts),
      ),
    ),
  );
}

Widget _showArEnRes(TextStyle ts, List<ArEnEntry> entries) {
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
          rows: entries.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(e.word)),
                DataCell(Text(e.def)),
                DataCell(Text(e.root)),
              ],
            );
          }).toList(),
        ),
      ),
    ),
  );
}

Widget _hansLaneView(TextStyle ts, SearchLexiconsDatas datas, ColorScheme cs) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _engMeaningView(txt, ts.fontSize!, cs, row.isHi),
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
      final txt = showWordTitle
          ? '${row.word}: ${row.meanings}'
          : row.meanings;
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
        lineHeight: LineHeight.number(1.6),
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
