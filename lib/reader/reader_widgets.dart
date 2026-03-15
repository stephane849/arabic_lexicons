import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ClickableParagraph extends StatelessWidget {
  final List<WordEntry> pera;
  final ReaderPageSettings rs;
  final void Function() onChange;
  final String Function() fullTextFunc;
  final TextStyle textStyleBodyMedium;
  final TextStyle highTextStyleBodyMedium;
  final TextAlign textAlign;
  final ColorScheme cs;

  const ClickableParagraph({
    super.key,
    required this.pera,
    required this.rs,
    required this.onChange,
    required this.fullTextFunc,
    required this.textStyleBodyMedium,
    required this.highTextStyleBodyMedium,
    required this.cs,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        showSelectableParagraph(context, fullTextFunc, rs, textStyleBodyMedium);
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

    spans.add(TextSpan(children: [WidgetSpan(child: SizedBox(width: 20))]));
    for (final word in pera) {
      spans.add(
        _readerWordSpan(
          context: context,
          isRmTashkil: rs.isRmTashkil,
          isBmk: BookMarks.isSet(word.cl),
          word: word,
          onChange: onChange,
          textStyleBodyMedium: textStyleBodyMedium,
          highTextStyleBodyMedium: highTextStyleBodyMedium,
        ),
      );
    }
    return spans;
  }
}

class ClickableBayt extends StatelessWidget {
  final List<WordEntry> pera;
  final int peraIndex;
  final ReaderPageSettings rs;
  final void Function() onChange;
  final String Function() fullTextFunc;
  final TextStyle textStyleBodyMedium;
  final TextStyle highTextStyleBodyMedium;
  final TextAlign textAlign;
  final ColorScheme cs;

  const ClickableBayt({
    super.key,
    required this.pera,
    required this.peraIndex,
    required this.rs,
    required this.onChange,
    required this.fullTextFunc,
    required this.textStyleBodyMedium,
    required this.highTextStyleBodyMedium,
    required this.cs,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        showSelectableParagraph(context, fullTextFunc, rs, textStyleBodyMedium);
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

    for (final word in pera) {
      spans.add(
        _readerWordSpan(
          context: context,
          isRmTashkil: rs.isRmTashkil,
          isBmk: BookMarks.isSet(word.cl),
          word: word,
          onChange: onChange,
          textStyleBodyMedium: textStyleBodyMedium,
          highTextStyleBodyMedium: highTextStyleBodyMedium,
        ),
      );
    }
    return spans;
  }
}

TextSpan _readerWordSpan({
  required BuildContext context,
  required bool isRmTashkil,
  required bool isBmk,
  required WordEntry word,
  required void Function() onChange,
  required TextStyle textStyleBodyMedium,
  required TextStyle highTextStyleBodyMedium,
}) {
  return TextSpan(
    text: isRmTashkil ? '${word.nTk} ' : '${word.ar} ',
    recognizer: word.cl.isEmpty
        ? null
        : (TapGestureRecognizer()
            ..onTap = appSettingsNotifier.readerIsOpenLexiconDirecly
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
  );
}
