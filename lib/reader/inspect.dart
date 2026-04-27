import 'dart:async';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

// keep your existing _tashkil regex here
String cleanBookTitle(String title) {
  return ArabicNormalizer.cleanLineForSearch(title);
}

class _PeraLine {
  final int index;
  final String clPera;
  final String arPera;

  const _PeraLine({
    required this.index,
    required this.clPera,
    required this.arPera,
  });
}

Future<int?> showNavigateBook(
  BuildContext context,
  ReaderPageSettings rs,
  PeraEntries peras,
  int currPeraIdx,
) {
  return showModalBottomSheet<int?>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      return _PeraPickerSheet(rs: rs, peras: peras, currPeraIdx: currPeraIdx);
    },
  );
}

class _PeraPickerSheet extends StatefulWidget {
  final ReaderPageSettings rs;
  final PeraEntries peras;
  final int currPeraIdx;

  const _PeraPickerSheet({
    required this.rs,
    required this.peras,
    required this.currPeraIdx,
  });

  @override
  State<_PeraPickerSheet> createState() => _PeraPickerSheetState();
}

class _PeraPickerSheetState extends State<_PeraPickerSheet>
    with TickerProviderStateMixin {
  static final RegExp _digitOnly = RegExp(r'^[\u0660-\u0669]+$');

  late final int _currPeraIdx;
  int? _currChapterIdx;

  final _sc = AutoScrollController();
  late final TabController _tabController;
  late final TextEditingController _searchController;

  late final List<_PeraLine> _allLines;
  late final List<_PeraLine> _chapterLines;

  List<_PeraLine> _filteredLines = [];

  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _currPeraIdx = widget.currPeraIdx;

    const takeWordsCount = 15;
    _allLines = widget.peras.indexed.map((e) {
      final isSub = e.$2.length > takeWordsCount;
      final words = isSub ? e.$2.sublist(0, takeWordsCount) : e.$2;

      var arPera = words.map((w) => w.ar).join(' ');
      final clPera = cleanBookTitle(words.map((w) => w.cl).join(' '));

      if (isSub) arPera = '$arPera...';

      return _PeraLine(index: e.$1, arPera: arPera, clPera: clPera);
    }).toList();

    _chapterLines = _allLines.where((p) {
      final words = widget.peras[p.index];
      return words.length == 1 && _digitOnly.hasMatch(words.first.ar);
    }).toList();

    if (_chapterLines.isNotEmpty) {
      for (final (idx, c) in _chapterLines.indexed) {
        if (c.index > _currPeraIdx) break;
        if (_currPeraIdx >= c.index) {
          _currChapterIdx = idx;
        }
      }
    }

    _filteredLines = _allLines;

    _searchController = TextEditingController();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _chapterLines.isNotEmpty ? 1 : 0,
    );

    _tabController.addListener(_onTabChange);

    // if (_chapterLines.isEmpty && _currPeraIdx > 0) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     // here we don't need to care about is index same or not
    //     _scrollToCurrPeraIdx();
    //   });
    // }
  }

  void _scrollToCurrPeraIdx() {
    if (!_sc.hasClients) return;
    _sc.scrollToIndex(
      _currPeraIdx,
      preferPosition: AutoScrollPosition.begin,
      duration: const Duration(milliseconds: 100),
    );
  }

  void _onTabChange() {
    // if (!mounted) return;
    // setState(() {});
  }

  void _applySearch(String input) {
    final cleaned = cleanBookTitle(input);

    if (cleaned == _query) return;
    _query = cleaned;

    if (_query.isEmpty) {
      _filteredLines = _allLines;
    } else {
      _filteredLines = _allLines.where((p) {
        return p.clPera.toLowerCase().contains(_query);
      }).toList();
    }

    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) _sc.jumpTo(0);
      });
    }
  }

  void _onSearchChanged(String input) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _applySearch(input);
    });
  }

  // String _shorten(String text, [int max = 70]) {
  //   if (text.length <= max) return text;
  //   return '${text.substring(0, max)}…';
  // }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arFont = appSettingsNotifier.getArabicTextStyle(context);
    // .copyWith(fontFamily: widget.rs.fontFam);

    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 12, bottom: 12),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withAlpha(70),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Paragraphs'),
                    Tab(text: 'Chapters'),
                  ],
                ),
                SizedBox(height: 8),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 18,
                              left: 18,
                              bottom: 10,
                            ),
                            child: TextField(
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: arFont,
                              decoration: InputDecoration(
                                hintText: 'ابحث عن النص…',
                                prefixIcon: IconButton(
                                  icon: Icon(Icons.location_pin),
                                  onPressed: _scrollToCurrPeraIdx,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() {
                                    setState(() {
                                      _searchController.clear();
                                      _filteredLines = _allLines;
                                    });
                                  }),
                                  icon: Icon(Icons.clear),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildList(
                              items: _filteredLines,
                              emptyText: 'No peras found',
                              arFont: arFont,
                              onTapItem: (item) =>
                                  Navigator.of(context).pop(item.index),
                              itemBuilder: (item) => item.arPera,
                              isHigh: (_, itm) => itm.index == _currPeraIdx,
                            ),
                          ),
                        ],
                      ),
                      _buildList(
                        items: _chapterLines,
                        emptyText: 'No chapters found',
                        arFont: arFont,
                        onTapItem: (item) =>
                            Navigator.of(context).pop(item.index),
                        itemBuilder: (item) {
                          final chapterWord = widget.peras[item.index].first.ar;
                          return 'الباب $chapterWord';
                        },
                        isHigh: (index, _) => index == _currChapterIdx,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList({
    required List<_PeraLine> items,
    required String emptyText,
    required TextStyle arFont,
    required ValueChanged<_PeraLine> onTapItem,
    required String Function(_PeraLine item) itemBuilder,
    required bool Function(int index, _PeraLine itm) isHigh,
  }) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }

    final cs = Theme.of(context).colorScheme;

    final highDecor = BoxDecoration(color: cs.primary.withAlpha(50));

    return Material(
      color: cs.surface,
      child: ListView.separated(
        controller: _sc,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: scrollPadding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final item = items[index];

          return AutoScrollTag(
            controller: _sc,
            key: ValueKey(item.index),
            index: item.index,
            child: Ink(
              decoration: isHigh(index, item) ? highDecor : null,
              child: InkWell(
                onTap: () => onTapItem(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Text(
                    itemBuilder(item),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: arFont,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
