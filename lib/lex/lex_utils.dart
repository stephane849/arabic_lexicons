import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/txt.dart';
import 'package:flutter/material.dart';

const int _maxTextSize = 500;

Future<void> onTextChanged(
  BuildContext context,
  TextEditingController controller,
  SearchLexiconsDatas datas,
  VoidCallback afterChange,
) async {
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

  datas.isShowingSugg = false;
  await datas.loadResults(afterChange);

  if (SearchSuggestions.shouldShow && datas.resultsAreEmpty) {
    datas.loadSearchSugg(afterChange);
  }
}
