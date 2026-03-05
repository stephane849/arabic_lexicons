import 'package:ara_dict/ar_en/ar_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:ara_dict/data.dart';

Widget showRes(TextStyle ts, SearchLexiconsDatas datas, ColorScheme cs) {
  if (datas.resultsAreEmpty) {
    return noRes(ts, datas.selectedWord);
  }

  final curDict = datas.selectedDict;
  if (curDict == Dict.arEn) {
    return _showArEnRes(ts, datas.arEnRes!);
  }

  var showWordTitle = datas.selectedDict == Dict.mujamulGhoni;
  final dbRes = datas.dbRes!;

  return ListView.separated(
    // padding: EdgeInsets.only(top: 16),
    padding: scrollPadding,
    itemCount: dbRes.length,
    separatorBuilder: (context, index) =>
        const Divider(height: 0, thickness: 0.5),
    itemBuilder: (context, index) {
      final row = dbRes[index];
      String txt;
      if (showWordTitle) {
        final word = row['word'] ?? '';
        final meaning = row['meanings'] ?? '';
        txt = '$word: $meaning';
      } else {
        txt = row['meanings'] ?? '';
      }

      final isHi = row['isHi'] ?? false;
      // return RichText(text: TextSpan(text: row['meanings']));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: curDict == Dict.hanswehr || curDict == Dict.laneLexicon
            ? _engMeaningView(txt, ts.fontSize!, cs, isHi)
            : _arMeaningView(txt, ts),
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

Widget noRes(TextStyle ts, String? currWord) {
  String txt;
  if (currWord == null || currWord.isEmpty) {
    txt = "ابجث عن كلمة";
  } else {
    txt = "لا توجد نتائج لـ: $currWord";
  }

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Center(
      child: Text(txt, textDirection: TextDirection.rtl, style: ts),
    ),
  );
}

Widget _showArEnRes(TextStyle ts, List<ArEnEntry> entries) {
  return SingleChildScrollView(
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: scrollPadding,
        child: DataTable(
          dataTextStyle: ts,
          // dividerThickness: 0.5,
          columnSpacing: 18.0,
          // checkboxHorizontalMargin: 50,
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
