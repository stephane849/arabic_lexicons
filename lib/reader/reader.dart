import 'dart:async';
import 'dart:io';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/inspect.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/reader/reader_widgets.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ReaderPage extends StatefulWidget {
  final PeraEntries paras;
  final ReaderPageSettings rs;

  const ReaderPage({super.key, required this.paras, required this.rs});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final PeraEntries _paras;
  late String _title;
  late ReaderPageSettings _rs;
  late final List<GlobalKey> _keys;
  late final AutoScrollController _sc;

  bool _isFabVisable = true;

  File? _peraIndexSave;

  /// this is used for indicating that it's auto scrolling
  bool _initalAutoScrolling = false;

  int _currPeraIndex = 0;

  @override
  void initState() {
    super.initState();

    hideStatusBar();

    _paras = widget.paras;
    _rs = widget.rs;

    _keys = List.generate(_paras.length, (_) => GlobalKey());
    _title = readerAppbarTitle(_paras, _rs.isRmTashkil);

    _sc = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, MediaQuery.of(context).padding.top + 18, 0, 0),
    );

    if (_rs.bookHash.isNotEmpty && _rs.saveLastPeraIdx) {
      _sc.addListener(_onScroll);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_rs.bookHash.isEmpty) return;

      final dataDir = await getApplicationDocumentsDirectory();
      final peraScrollDir = Directory(
        path.join(dataDir.path, readerConfDirName),
      );
      peraScrollDir.create();

      _peraIndexSave = File(
        path.join(peraScrollDir.path, '${_rs.bookHash}_scrollIdx.txt'),
      );

      // inilization done, now check if we need to scroll
      if (!_rs.saveLastPeraIdx) return;

      int idx = 0;
      try {
        final idxStr = await _peraIndexSave?.readAsString();
        if (idxStr != null) idx = int.tryParse(idxStr) ?? 0;
      } catch (_) {}

      if (idx == 0 || !_sc.hasClients) return;

      _currPeraIndex = idx;
      _initalAutoScrolling = true;

      _sc.scrollToIndex(
        idx,
        preferPosition: AutoScrollPosition.begin,
        duration: const Duration(microseconds: 100),
      );
    });

    _rs.saveToFile();
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    hideStatusBar();
  }

  Timer? _scrollPosBuf;
  void _onScroll() {
    final sd = _sc.position.userScrollDirection;
    if (sd == ScrollDirection.reverse && _isFabVisable) {
      setState(() {
        _isFabVisable = false;
      });
    } else if (sd == ScrollDirection.forward && !_isFabVisable) {
      setState(() {
        _isFabVisable = true;
      });
    }
    _scrollPosBuf?.cancel();
    _scrollPosBuf = Timer(const Duration(milliseconds: 500), () async {
      if (_initalAutoScrolling) {
        _initalAutoScrolling = false;
        return;
      }
      final height = MediaQuery.of(context).size.height;
      final minVisableHeight = height / 4;

      int? bestIndex;

      for (int i = 0; i < _keys.length; i++) {
        final ctx = _keys[i].currentContext;
        if (ctx == null) continue;

        final box = ctx.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);

        // pos.dy is negetive so we are subtracting
        final visableAmmount = box.size.height + pos.dy;

        if (pos.dy >= 0 || visableAmmount > minVisableHeight) {
          bestIndex = i;
          if (_rs.isQasidah && i % 2 != 0) {
            bestIndex = i - 1;
          }
          break;
        }
      }

      if (bestIndex != null) {
        if (_currPeraIndex == bestIndex) return;
        _currPeraIndex = bestIndex;
        try {
          await _peraIndexSave?.writeAsString('$bestIndex');
          if (kDebugMode) {
            // debugPrint('saved: $bestIndex -> ${_peraIndexSave?.path}');
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _settingsDrawer() async {
    final res = await showReaderModeSettings(context, _rs, _paras);
    if (res == null || _rs.isEqual(res)) {
      return;
    }

    if (res.bookHash.isNotEmpty && res.saveLastPeraIdx != _rs.saveLastPeraIdx) {
      if (res.saveLastPeraIdx) {
        _sc.addListener(_onScroll);
      } else {
        _sc.removeListener(_onScroll);
      }
    }

    if (_rs.isRmTashkil != res.isRmTashkil) {
      _title = readerAppbarTitle(_paras, res.isRmTashkil);
    }

    _rs = res;
    setState(() {});
    _rs.saveToFile();
  }

  Widget _buildSliverAppBar(BuildContext context, TextStyle arabicFontStyle) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SliverAppBar(
        titleSpacing: 0.0,
        floating: true,
        snap: true,
        pinned: false,
        title: Text(
          _title,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
        ),
        // actions: [
        //   IconButton(
        //     tooltip: 'Reader Mode settings',
        //     onPressed: _settingsDrawer,
        //     icon: const Icon(Icons.tune),
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.exit_to_app_outlined),
        //     tooltip: 'Exit Reader',
        //     onPressed: () => exitReaderPage(context),
        //   ),
        // ],
      ),
    );
  }

  Widget _buildQasidahSliver(BuildContext context, TextStyle arabicFontStyle) {
    final cs = Theme.of(context).colorScheme;
    final highWordStyle = arabicFontStyle.copyWith(color: cs.error);
    final align = _rs.isQasidahCentered ? TextAlign.center : TextAlign.right;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return AutoScrollTag(
          controller: _sc,
          key: _keys[index],
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ClickableBayt(
              peraIndex: index,
              rs: _rs,
              pera: _paras[index],
              textStyleBodyMedium: arabicFontStyle,
              highTextStyleBodyMedium: highWordStyle,
              cs: cs,
              textAlign: align,
              onChange: () => setState(() {}),
              fullTextFunc: () {
                PeraEntries currPeras;
                if (index % 2 == 0) {
                  if (_paras.length > index + 1) {
                    currPeras = [_paras[index], _paras[index + 1]];
                  } else {
                    currPeras = [_paras[index]];
                  }
                } else {
                  currPeras = [_paras[index - 1], _paras[index]];
                }

                return currPeras
                    .map(
                      (p) => p
                          .map((w) => _rs.isRmTashkil ? w.nTk : w.ar)
                          .join(' '),
                    )
                    .join('\n');
              },
            ),
          ),
        );
      }, childCount: _paras.length),
    );
  }

  Widget _buildParagraphSliver(
    BuildContext context,
    TextStyle arabicFontStyle,
  ) {
    final cs = Theme.of(context).colorScheme;
    final highWordStyle = arabicFontStyle.copyWith(color: cs.error);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final currPera = _paras[index];

        return AutoScrollTag(
          controller: _sc,
          key: _keys[index],
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ClickableParagraph(
              rs: _rs,
              index: index,
              pera: currPera,
              textStyleBodyMedium: arabicFontStyle,
              highTextStyleBodyMedium: highWordStyle,
              cs: cs,
              textAlign: _rs.textAlign,
              fullTextFunc: () {
                return currPera
                    .map((w) => _rs.isRmTashkil ? w.nTk : w.ar)
                    .join(' ');
              },
              onChange: () => setState(() {}),
            ),
          ),
        );
      }, childCount: _paras.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arFont = appSettingsNotifier
        .getArabicTextStyle(context)
        .copyWith(fontFamily: _rs.fontFam, fontFamilyFallback: [fontKitab]);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        exitReaderPage(context);
      },
      child: Scaffold(
        drawer: buildDrawer(context),
        body: SafeArea(
          top: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(
              controller: _sc,
              slivers: [
                _buildSliverAppBar(context, arFont),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ).copyWith(bottom: 128),
                  sliver: _rs.isQasidah
                      ? _buildQasidahSliver(context, arFont)
                      : _buildParagraphSliver(context, arFont),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: AnimatedSlide(
          duration: Duration(milliseconds: 300),
          offset: _isFabVisable ? Offset.zero : Offset(0, 2),
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _isFabVisable ? 1.0 : 0.0,
            child: FloatingActionButton(
              child: Icon(Icons.menu_book),
              onPressed: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  useSafeArea: true,
                  constraints: BoxConstraints(maxWidth: 600),
                  isScrollControlled: true,
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        child: Column(
                          // mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.tune),
                              title: const Text('Settings'),
                              subtitle: const Text('Open Reader Settings'),
                              trailing: const Icon(Icons.arrow_right),
                              onTap: () => Navigator.pop(context, 'settings'),
                            ),
                            Divider(height: 0),
                            ListTile(
                              leading: const Icon(Icons.list_alt),
                              title: const Text('Chapters & Paragraphs'),
                              subtitle: const Text('Navigate Book'),
                              trailing: const Icon(Icons.arrow_right),
                              onTap: () => Navigator.pop(context, 'inspect'),
                            ),
                            Divider(height: 0),
                            ListTile(
                              title: const Text('Copy Text'),
                              subtitle: const Text('Copy the original text'),
                              leading: const Icon(Icons.copy_all),
                              trailing: const Icon(Icons.arrow_right),
                              onTap: () => Navigator.pop(context, 'copy-txt'),
                            ),
                            Divider(height: 0),
                            ListTile(
                              leading: const Icon(Icons.exit_to_app_outlined),
                              title: const Text('Exit Reader'),
                              subtitle: const Text('Go to Reader Input'),
                              trailing: const Icon(Icons.arrow_right),
                              onTap: () => Navigator.pop(context, 'exit'),
                            ),

                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (result == null || !context.mounted) return;

                switch (result) {
                  case 'exit':
                    exitReaderPage(context);
                    break;

                  case 'settings':
                    _settingsDrawer();
                    break;

                  case 'inspect':
                    final idx = await showNavigateBook(
                      context,
                      _rs,
                      _paras,
                      _currPeraIndex,
                    );
                    if (idx == null) return;

                    _sc.scrollToIndex(
                      idx,
                      duration: const Duration(milliseconds: 100),
                      preferPosition: AutoScrollPosition.begin,
                    );
                    break;

                  case 'copy-txt':
                    await Clipboard.setData(
                      ClipboardData(
                        text: _paras
                            .map((p) => p.map((w) => w.ar).join(" "))
                            .join("\n"),
                      ),
                    );

                    if (context.mounted) showSnack(context, 'Text Copied');

                    break;
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

void openReaderPage(
  BuildContext context,
  PeraEntries paras,
  ReaderPageSettings rs,
) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: Routes.readerPage),
      builder: (_) => ReaderPage(paras: paras, rs: rs),
    ),
  );
}

Future<void> exitReaderPage(BuildContext context) async {
  if (!context.mounted) return;
  if (await showConfirmDialog(
        context,
        'Exit Reader',
        message: 'Go to reader input page?',
        // confirmText: 'Exit'
      ) ??
      false) {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, Routes.readerInput);
  }
}
