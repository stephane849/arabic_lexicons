import 'dart:async';
import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:flutter/material.dart';

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
) {
  return showModalBottomSheet<int?>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      return _PeraPickerSheet(rs: rs, peras: peras);
    },
  );
}

class _PeraPickerSheet extends StatefulWidget {
  final ReaderPageSettings rs;
  final PeraEntries peras;

  const _PeraPickerSheet({required this.rs, required this.peras});

  @override
  State<_PeraPickerSheet> createState() => _PeraPickerSheetState();
}

class _PeraPickerSheetState extends State<_PeraPickerSheet>
    with TickerProviderStateMixin {
  static final RegExp _digitOnly = RegExp(r'^[\u0660-\u0669]+$');

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

    _filteredLines = _allLines;

    _searchController = TextEditingController();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _chapterLines.isNotEmpty ? 1 : 0,
    );

    _tabController.addListener(_onTabChange);
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

    if (mounted) setState(() {});
  }

  void _onSearchChanged(String input) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _applySearch(input);
    });
  }

  String _shorten(String text, [int max = 70]) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }

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

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            child: TextField(
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: arFont,
                              decoration: InputDecoration(
                                hintText: 'ابحث عن النص…',
                                suffix: IconButton(
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
  }) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: scrollPadding,
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final item = items[index];

        return InkWell(
          onTap: () => onTapItem(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(
              _shorten(itemBuilder(item)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: arFont,
            ),
          ),
        );
      },
    );
  }
}
