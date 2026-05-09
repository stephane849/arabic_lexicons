import 'dart:async';

import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/first_run.dart';
import 'package:ara_dict/lex/isolate.dart';
import 'package:ara_dict/lex/rearrange_dicts.dart';
import 'package:ara_dict/lex/utils.dart';
import 'package:ara_dict/lex/widgets.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/lex/data.dart';

import 'package:ara_dict/lex/sugg/widgets.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchLexicons extends StatefulWidget {
  final bool isPopup;
  final String initialText;

  const SearchLexicons({
    super.key,
    this.isPopup = false,
    this.initialText = kDebugMode ? 'عمل وقت' : '',
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

    final sc = AutoScrollController(
      viewportBoundaryGetter: () {
        final top = MediaQuery.of(context).padding.top + 18;
        return Rect.fromLTRB(0, top, 0, 0);
      },
    );

    _datas = SearchLexiconsDatas(
      selectedDict: allDictsOrd.first,
      inputFocusNode: _focusNode,
      scrollController: sc,
      onChangeTxt: _onChangeTxt,
      setState: setState,
    );

    // this is mainly for the appbar

    sc.addListener(() {
      final appbarColor = readerAppBarColorBg(sc.offset);

      if (_datas.appbarColorBg != appbarColor) {
        setState(() => _datas.appbarColorBg = appbarColor);
      }
    });

    if (!_isPopup) {
      appConf.setRefetchLexResultsFunc = () =>
          _datas.getAndShowResORSugg(context);

      hideStatusBar();

      // show msg
      showFirstRunPopupPostFrame(context);
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
      appConf.rmRefetchLexResultsFunc();
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
  Future<void> _onChangeTxt({String? appendTxt}) async {
    // this is for adding words by clicking on roots in the results it
    if (appendTxt != null) {
      final t = _controller.text;
      final newText = "$t${t.isNotEmpty ? ' ' : ''}$appendTxt";

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
    final arTxtTheme = appConf.readerTS(context);
    // final isAr = appSettingsNotifier.useMoreArabic;

    final cs = Theme.of(context).colorScheme;
    final showingSugg = Isolates.suggCanBeShown && _datas.isShowingSugg;
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
              child: ColoredBox(
                color: appConf.readerSurface(context),
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
                          sliver: _datas.isSelectedWordEmpty
                              ? noRes()
                              : showingSugg &&
                                    _datas.sugg.isEmpty &&
                                    _datas.resLoaded &&
                                    _datas.resultsAreEmpty
                              ? noRes(
                                  currWord: _datas.selectedWord,
                                  noResAr: 'لا توجد نتائج أو اقتراحات لـ',
                                  noResEn: 'No Results or Suggestions for',
                                )
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
            ),

            Divider(thickness: 0.5, height: 0),
            if (showingSugg && _datas.sugg.isNotEmpty)
              Directionality(
                textDirection: L.dir,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Stack(
                    children: [
                      if (_isPopup)
                        Align(
                          alignment: AlignmentGeometry.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: IconButton(
                              tooltip: 'Close Lexicon',
                              icon: Icon(
                                Icons.arrow_back,
                                textDirection: TextDirection.ltr,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      Align(
                        alignment: AlignmentGeometry.center,
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.close),
                          iconAlignment: IconAlignment.start,
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              L.p("Close Suggestions", "إغلاق الاقتراحات"),
                              style: L.arStyleIf,
                            ),
                          ),
                          onPressed: () {
                            _datas.getAndShowResORSugg(context, forceRes: true);
                          },
                        ),
                      ),
                    ],
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
                      );

                      if (res == null) return;

                      if (res.openSettings == true) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => showDictReorderSheet(
                            context,
                            after: () {
                              if (context.mounted) setState(() {});
                            },
                          ),
                        );
                        return;
                      }

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
                      textAlign: TextAlign.start,
                      onChanged: (_) async {
                        if (_debouce?.isActive ?? false) _debouce!.cancel();
                        _debouce = Timer(
                          const Duration(milliseconds: 200),
                          () async => await _onChangeTxt(),
                        );
                      },
                      // style: arTxtTheme,
                      style: L.arStyle,
                      decoration: InputDecoration(
                        hintText: L.p('Search Words', 'ابحث'),
                        hintTextDirection: L.dir,
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => showDictReorderSheet(context),
      // ),
    );
  }
}
