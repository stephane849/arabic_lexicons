import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ClickableParagraph extends StatelessWidget {
  final List<WordEntry> pera;
  final int peraIndex;
  final ReaderPageSettings rs;
  final void Function() onChange;
  final TextStyle textStyleBodyMedium;
  final TextStyle highTextStyleBodyMedium;
  final TextAlign textAlign;
  final ColorScheme cs;

  const ClickableParagraph({
    super.key,
    required this.pera,
    required this.peraIndex,
    required this.rs,
    required this.onChange,
    required this.textStyleBodyMedium,
    required this.highTextStyleBodyMedium,
    required this.cs,
    this.textAlign = TextAlign.justify,
  });

  // @override
  // Widget build(BuildContext context) {
  //   return RichText(
  //     textDirection: TextDirection.rtl,
  //     textAlign: textAlign,
  //     text: TextSpan(
  //       style: textStyleBodyMedium,
  //       children: _buildSpans(context),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        showSelectableParagraph(context, pera, rs, textStyleBodyMedium);
      },
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
        text: TextSpan(
          style: textStyleBodyMedium,
          children: _buildSpans(context),
        ),
      ),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final spans = <TextSpan>[];

    if (rs.isQasidah) {
      if (peraIndex % 2 == 0) {
        if (rs.qasidahLineNum) {
          spans.add(
            TextSpan(
              text: '${enToArNum((peraIndex ~/ 2) + 1)}- ',
              style: textStyleBodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.error,
              ),
            ),
          );
        }
      } else {
        spans.add(TextSpan(children: [WidgetSpan(child: SizedBox(width: 30))]));
      }
    } else {
      spans.add(TextSpan(children: [WidgetSpan(child: SizedBox(width: 20))]));
    }

    for (final word in pera) {
      final isBmk = BookMarks.isSet(word.cl);
      spans.add(
        TextSpan(
          text: rs.isRmTashkil ? '${word.nTk} ' : '${word.ar} ',
          recognizer: word.cl.isEmpty
              ? null
              : (TapGestureRecognizer()
                  ..onTap = rs.isOpenLexiconDirecly
                      ? () => openDict(context, word.cl).then((_) {
                          if (context.mounted) onChange();
                        })
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
                          textStyleBodyMedium,
                        )),
          style: isBmk ? highTextStyleBodyMedium : null,
        ),
      );
    }
    return spans;
  }
}
