import 'dart:async';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/lex_utils.dart';
import 'package:ara_dict/lex/lex_widgets.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/lex/sugg_widget.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchLexicons extends StatefulWidget {
  final bool showDrawer;
  final String initialText;

  const SearchLexicons({
    super.key,
    this.showDrawer = true,
    this.initialText = '',
  });

  @override
  State<SearchLexicons> createState() => _SearchLexiconsState();
}

class _SearchLexiconsState extends State<SearchLexicons> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  // final _autoScrollControler = AutoScrollController();
  late bool _showDrawer;
  final _datas = SearchLexiconsDatas(scrollController: AutoScrollController());

  @override
  void initState() {
    super.initState();

    _showDrawer = widget.showDrawer;
    _controller = TextEditingController(text: widget.initialText);
    if (widget.initialText.isNotEmpty) _onChangeTxt();

    if (_showDrawer) {
      appSettingsNotifier.setRefetchLexResultsFunc = () =>
          _datas.getAndShowResORSugg(context, _setSate);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _datas.scrollController.dispose();
    if (_showDrawer) appSettingsNotifier.rmRefetchLexResultsFunc();
    super.dispose();
  }

  void _setSate() => setState(() {});

  Timer? _debouce;
  Future<void> _onChangeTxt() async =>
      await onTextChanged(context, _controller, _datas, _setSate);

  @override
  Widget build(BuildContext context) {
    final arTxtTheme = appSettingsNotifier.getArabicTextStyle(context);
    final cs = Theme.of(context).colorScheme;
    // final ltr =
    //     _datas.selectedDict == Dict.arEn ||
    //     _datas.selectedDict == Dict.hanswehr ||
    //     _datas.selectedDict == Dict.laneLexicon;

    // if (kDebugMode) debugPrint('rebuild at: ${formatDateTime(context)}');

    return Scaffold(
      appBar: lexAppBar(context, _datas, _setSate),
      drawer: _showDrawer ? buildDrawer(context) : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SearchSuggestions.shouldShow && _datas.isShowingSugg
                  ? showSearchSugg(
                      context,
                      _controller,
                      _focusNode,
                      arTxtTheme,
                      _datas,
                      cs,
                      _setSate,
                    )
                  : _datas.isSelectedWordEmpty
                  ? noRes(arTxtTheme, null)
                  : _datas.resLoaded
                  ? showRes(context, arTxtTheme, _datas, cs)
                  : const Center(child: CircularProgressIndicator()),
            ),

            Divider(thickness: 0.5, height: 0),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  IconButton.filledTonal(
                    icon: Icon(dictWordSelectModalOpenIcon),
                    onPressed: () async {
                      _focusNode.unfocus();

                      final res = await showWordPickerBottomSheet(
                        context,
                        _datas,
                        arTxtTheme,
                      );

                      if (res == null) {
                        setState(() {});
                        return;
                      }
                      if (res.word != null) {
                        _datas.selectedWord = res.word!;
                      } else if (res.d != null) {
                        _datas.selectedDict = res.d!;
                        _datas.suggDictSorted.clear();
                      }
                      if (context.mounted) {
                        _datas.getAndShowResORSugg(context, _setSate);
                      }
                    },
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      onChanged: (_) async {
                        if (_debouce?.isActive ?? false) _debouce!.cancel();
                        _debouce = Timer(
                          const Duration(milliseconds: 200),
                          () async => await _onChangeTxt(),
                        );
                      },
                      style: arTxtTheme,
                      decoration: InputDecoration(
                        hintText: 'ابحث',
                        prefixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _datas.resetAll();
                            });
                            // this is when it's focued but keyboard is not oppended
                            _focusNode.requestFocus();
                          },

                          icon: Icon(Icons.clear),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
