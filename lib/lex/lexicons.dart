import 'dart:async';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/lex_utils.dart';
import 'package:ara_dict/lex/lex_widgets.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/lex/data.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/lex/sugg_widget.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchLexicons extends StatefulWidget {
  final bool isPopup;
  final String initialText;
  final Dict? initialDict;

  const SearchLexicons({
    super.key,
    this.isPopup = false,
    this.initialText = kDebugMode ? 'عمل وقت' : '',
    this.initialDict = kDebugMode ? Dict.hanswehr : null,
  });

  @override
  State<SearchLexicons> createState() => _SearchLexiconsState();
}

class _SearchLexiconsState extends State<SearchLexicons> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  // final _autoScrollControler = AutoScrollController();
  late bool _isPopup;

  late final SearchLexiconsDatas _datas;

  @override
  void initState() {
    super.initState();

    setState(() {});

    _isPopup = widget.isPopup;
    _controller = TextEditingController(text: widget.initialText);

    _datas = SearchLexiconsDatas(
      inputFocusNode: _focusNode,
      scrollController: AutoScrollController(
        viewportBoundaryGetter: () {
          final top = MediaQuery.of(context).padding.top + 18;
          return Rect.fromLTRB(0, top, 0, 0);
        },
      ),
      onChangeTxt: _onChangeTxt,
      setState: setState,
    );

    if (widget.initialDict != null) _datas.selectedDict = widget.initialDict!;

    if (!_isPopup) {
      appSettingsNotifier.setRefetchLexResultsFunc = () =>
          _datas.getAndShowResORSugg(context);

      hideStatusBar();
      // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    // after initing
    if (widget.initialText.isNotEmpty) _onChangeTxt();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _datas.scrollController.dispose();
    if (!_isPopup) {
      appSettingsNotifier.rmRefetchLexResultsFunc();
      // showStatusBar();
      // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    hideStatusBar();
  }

  void _setSate() => setState(() {});

  int? _selectionOffsetOld;
  Timer? _debouce;
  Future<void> _onChangeTxt({String? txt}) async {
    // this is for adding words by clicking on roots in the results it
    if (txt != null) {
      final t = _controller.text;
      final newText = "$t${t.isNotEmpty ? ' ' : ''}$txt";

      _controller.text = newText;

      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    }
    _selectionOffsetOld = _controller.selection.base.offset;
    await onTextChanged(context, _controller, _datas, _setSate);
  }

  @override
  Widget build(BuildContext context) {
    final arTxtTheme = appSettingsNotifier.getArabicTextStyle(context);
    final cs = Theme.of(context).colorScheme;
    final showingSugg = SearchSuggestions.shouldShow && _datas.isShowingSugg;
    final dir = showingSugg
        ? TextDirection.rtl
        : _datas.selectedDict == Dict.arEn ||
              _datas.selectedDict == Dict.hanswehr ||
              _datas.selectedDict == Dict.laneLexicon
        ? TextDirection.ltr
        : TextDirection.rtl;

    // if (kDebugMode) debugPrint('rebuild at: ${formatDateTime(context)}');

    return Scaffold(
      // appBar: lexAppBar(context, _datas, _setSate),
      drawer: _isPopup ? null : buildDrawer(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _focusNode.unfocus(),
                child: Directionality(
                  textDirection: dir,
                  child: CustomScrollView(
                    // physics: NeverScrollableScrollPhysics(),
                    reverse: showingSugg && _datas.sugg.isNotEmpty,
                    controller: _datas.scrollController,
                    slivers: [
                      if (!showingSugg || _datas.sugg.isEmpty)
                        lexAppBar(context, _datas, _setSate, arTxtTheme),

                      SliverPadding(
                        padding: showingSugg
                            ? scrollPadding.copyWith(bottom: 0)
                            : scrollPadding,
                        sliver:
                            _datas.isSelectedWordEmpty ||
                                (showingSugg && _datas.sugg.isEmpty) ||
                                (!showingSugg &&
                                    _datas.resLoaded &&
                                    _datas.resultsAreEmpty)
                            ? noRes(arTxtTheme, _datas.selectedWord)
                            : showingSugg
                            ? showSearchSugg(
                                context,
                                _controller,
                                arTxtTheme,
                                _datas,
                                cs,
                              )
                            : _datas.resLoaded
                            ? showRes(context, arTxtTheme, _datas, cs)
                            : const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Divider(thickness: 0.5, height: 0),
            if (showingSugg && _datas.sugg.isNotEmpty)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Center(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      iconAlignment: IconAlignment.start,
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text("Close Suggestions"),
                      ),
                      onPressed: () {
                        _datas.getAndShowResORSugg(context, forceRes: true);
                      },
                    ),
                  ),
                ),
              ),
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

                      if (res == null) return;
                      if (res.word != null) {
                        _datas.selectedWord = res.word!;
                      }
                      if (res.d != null) {
                        _datas.selectedDict = res.d!;
                        _datas.suggDictSorted.clear();
                      }
                      if (context.mounted) {
                        _datas.getAndShowResORSugg(
                          context,
                          forceRes: res.word != null,
                        );
                      }
                    },
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      onTap: () async {
                        if (_controller.selection.base.offset !=
                            _selectionOffsetOld) {
                          await _onChangeTxt();
                        }
                      },
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
            // SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
