import 'package:ara_dict/lex/data.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/txt.dart';
import 'package:flutter/material.dart';

const int _maxTextSize = 500;

Future<void> onTextChanged(
  BuildContext context,
  TextEditingController controller,
  SearchLexiconsDatas datas,
  VoidCallback afterChange,
) async {
  String value = controller.text.trim();
  // if (datas.preQuery == value) return;

  datas.preQuery = value;

  if (value.length > _maxTextSize) {
    value = value.length > _maxTextSize
        ? value.substring(0, _maxTextSize)
        : value;

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );

    showSnack(context, 'Text too long, reduced to $_maxTextSize chars');
  }

  final (parts, currWord) = getNextWord(
    value,
    controller.selection.base.offset,
  );

  if (currWord == datas.selectedWord) {
    if (parts.length != datas.words.length) {
      datas.words = parts;
    }
    return;
  }

  if (currWord == null) {
    datas.resetAll();
    afterChange();
    return;
  }

  datas.words = parts;
  datas.selectedWord = currWord;

  datas.getAndShowResORSugg(context);
}
