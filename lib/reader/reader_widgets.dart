import 'dart:math';

import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:ara_dict/widgets/selectable_text_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const paraSpacerStart = WidgetSpan(child: SizedBox(width: 20));
const paraSpaceInbetween = EdgeInsets.symmetric(vertical: 8);

class ClickableParagraph extends StatelessWidget {
  final int index;
  final PeraEntries peras;
  final ReaderPageSettings rs;
  final void Function() onChange;
  final TextStyle style;
  final TextStyle styleLU;
  final TextStyle highStyletyle;
  final TextAlign textAlign;
  final ColorScheme cs;

  const ClickableParagraph({
    super.key,
    required this.index,
    required this.peras,
    required this.rs,
    required this.onChange,
    required this.style,
    required this.styleLU,
    required this.highStyletyle,
    required this.cs,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        SelectableTextScreen.show(
          context,
          ({start, end}) => _peraSelectTxt(peras, rs, start: start, end: end),
          rs.textAlign,
          TextDirection.rtl,
          style,
          currentIdx: index,
          length: peras.length,
        );
      },
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
        text: TextSpan(style: style, children: _buildSpans(context)),
      ),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final spans = <TextSpan>[];

    spans.add(TextSpan(children: [paraSpacerStart]));
    for (final word in peras[index]) {
      spans.add(
        _readerWordSpan(
          context: context,
          rs: rs,
          isBmk: BookMarks.isSet(word.cl),
          word: word,
          onChange: onChange,
          style: style,
          styleLU: styleLU,
          highStyle: highStyletyle,
        ),
      );
    }
    return spans;
  }
}

class ClickableBayt extends StatelessWidget {
  final PeraEntries peras;
  final int index;
  final ReaderPageSettings rs;
  final void Function() onChange;
  final TextStyle style;
  final TextStyle styleLU;
  final TextStyle highStyletyle;
  final TextAlign textAlign;
  final ColorScheme cs;

  const ClickableBayt({
    super.key,
    required this.peras,
    required this.index,
    required this.rs,
    required this.onChange,
    required this.style,
    required this.styleLU,
    required this.highStyletyle,
    required this.cs,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        int? end;
        int? start;

        if (index % 2 == 0) {
          start = index;
          end = min(peras.length - 1, index + 2);
        } else {
          start = index - 1;
          end = index + 1;
        }

        SelectableTextScreen.show(
          context,
          ({start, end}) => _peraSelectTxt(peras, rs, start: start, end: end),
          rs.textAlign,
          TextDirection.rtl,
          style,
          currentIdx: index,
          length: peras.length,
          start: start,
          end: end,
        );
      },
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
        text: TextSpan(style: style, children: _buildSpans(context)),
      ),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final spans = <TextSpan>[];

    if (index % 2 == 0) {
      if (rs.qasidahLineNum) {
        spans.add(
          TextSpan(
            text: '${enToArNum((index ~/ 2) + 1)}- ',
            style: style.copyWith(fontWeight: FontWeight.bold, color: cs.error),
          ),
        );
      }
    } else if (!rs.isQasidahCentered) {
      spans.add(
        TextSpan(children: [const WidgetSpan(child: SizedBox(width: 30))]),
      );
    }

    for (final word in peras[index]) {
      spans.add(
        _readerWordSpan(
          context: context,
          rs: rs,
          isBmk: BookMarks.isSet(word.cl),
          word: word,
          onChange: onChange,
          style: style,
          styleLU: styleLU,
          highStyle: highStyletyle,
        ),
      );
    }
    return spans;
  }
}

TextSpan _readerWordSpan({
  required BuildContext context,
  required ReaderPageSettings rs,
  required bool isBmk,
  required WordEntry word,
  required void Function() onChange,
  required TextStyle style,
  required TextStyle styleLU,
  required TextStyle highStyle,
}) {
  TextStyle ts;
  if (rs.isBmColored && BookMarks.isSet(word.cl)) {
    ts = highStyle;
  } else {
    final lu = rs.luContains(word.cl);
    ts = lu ? styleLU : style;
  }

  return TextSpan(
    text: rs.isRmTashkil ? '${word.nTk} ' : '${word.ar} ',
    recognizer: word.cl.isEmpty
        ? null
        : (TapGestureRecognizer()
            ..onTap = appConf.readerIsOpenLexiconDirecly
                ? () {
                    openDict(context, word.cl).then((_) {
                      if (context.mounted) onChange();
                    });
                    rs.luAdd(word.cl);
                  }
                : () => showWordReadeActionsDialog(
                    context,
                    word.cl,
                    isBmk,
                    () async {
                      if (isBmk) {
                        await BookMarks.rm(word.cl);
                      } else {
                        await BookMarks.add(word.cl);
                      }
                      if (context.mounted) onChange();
                    },
                    () {
                      openDict(context, word.cl).then((_) {
                        if (context.mounted) onChange();
                      });
                    },
                    style,
                  )),
    style: ts,
  );
}

String _peraSelectTxt(
  PeraEntries peras,
  ReaderPageSettings rs, {
  int? start,
  int? end,
}) {
  // print('$start, $end -> ${peras.length}');
  return peras
      .getRange(start!, end!)
      .map((p) => p.map((w) => rs.isRmTashkil ? w.nTk : w.ar).join(' '))
      .join('\n');
}
