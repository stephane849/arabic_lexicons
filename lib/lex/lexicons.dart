import 'dart:async';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/lex_utils.dart';
import 'package:ara_dict/lex/lex_widgets.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/lex/sugg_widget.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchLexicons extends StatefulWidget {
  final bool isPopup;
  final String initialText;

  const SearchLexicons({
    super.key,
    this.isPopup = false,
    this.initialText = '',
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

    _isPopup = widget.isPopup;
    _controller = TextEditingController(text: widget.initialText);
    if (widget.initialText.isNotEmpty) _onChangeTxt();

    _datas = SearchLexiconsDatas(
      scrollController: AutoScrollController(
        viewportBoundaryGetter: () {
          final top = MediaQuery.of(context).padding.top + 18;
          return Rect.fromLTRB(0, top, 0, 0);
        },
      ),
      onChangeTxt: _onChangeTxt,
    );

    if (!_isPopup) {
      appSettingsNotifier.setRefetchLexResultsFunc = () =>
          _datas.getAndShowResORSugg(context, _setSate);

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _datas.scrollController.dispose();
    if (!_isPopup) {
      appSettingsNotifier.rmRefetchLexResultsFunc();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    super.dispose();
  }

  void _setSate() => setState(() {});

  Timer? _debouce;
  Future<void> _onChangeTxt({String? txt}) async {
    if (txt != null) {
      // final t = _controller.text;
      final t = _controller.text;
      final newText = "$t${t.isNotEmpty ? ' ' : ''}$txt";

      _controller.text = newText;

      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    }
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
      body: Column(
        children: [
          Expanded(
            child: Directionality(
              textDirection: dir,
              child: CustomScrollView(
                // physics: NeverScrollableScrollPhysics(),
                reverse: showingSugg,
                controller: _datas.scrollController,
                slivers: [
                  if (!showingSugg)
                    lexAppBar(context, _datas, _setSate, arTxtTheme),
                  if (showingSugg)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(
                            child: FilledButton.tonalIcon(
                              icon: const Icon(Icons.close),
                              iconAlignment: IconAlignment.start,
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text("Close Suggestions"),
                              ),
                              onPressed: () {
                                _datas.getAndShowResORSugg(
                                  context,
                                  _setSate,
                                  forceRes: true,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
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
                        ? noRes(arTxtTheme, null)
                        : showingSugg
                        ? showSearchSugg(
                            context,
                            _controller,
                            _focusNode,
                            arTxtTheme,
                            _datas,
                            cs,
                            _setSate,
                          )
                        : _datas.resLoaded
                        ? showRes(context, arTxtTheme, _datas, cs)
                        : const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ),
                ],
              ),
            ),
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

                    if (res == null) return;
                    if (res.word != null) {
                      _datas.selectedWord = res.word!;
                    }
                    if (res.d != null) {
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
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
