import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/txt.dart';
import 'package:flutter/material.dart';

const int _maxTextSize = 500;

void onTextChanged(
  BuildContext context,
  TextEditingController controller,
  SearchLexiconsDatas datas,
  VoidCallback afterChange,
) {
  String value = controller.text;
  if (value.length > _maxTextSize) {
    value = value.length > _maxTextSize
        ? value.substring(0, _maxTextSize)
        : value;

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Text too long, reduced to $_maxTextSize chars'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  final (parts, currWord) = getNextWord(
    value,
    controller.selection.base.offset,
  );

  if (currWord == datas.selectedWord) return;

  datas.resetAll();
  if (currWord == null) {
    afterChange();
    return;
  }

  datas.words = parts;
  datas.selectedWord = currWord;

  if (datas.selectedDict == Dict.arEn) {
    datas.arEnRes = ArEnDict.findWord(currWord);
    if (datas.arEnRes != null && datas.arEnRes!.isNotEmpty) {
      datas.resLoaded = true;
      afterChange();
      return;
    }
  }

  datas.setSearchSugg(afterChange);
  afterChange();
}
