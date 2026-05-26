import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/input.dart';
import 'package:ara_dict/reader/luw.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LuwAllPage extends StatefulWidget {
  const LuwAllPage({super.key});

  static Future<void> open(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LuwAllPage()),
    );
  }

  @override
  State<LuwAllPage> createState() => _LuwAllPageState();
}

class _LuwAllPageState extends State<LuwAllPage> {
  bool _isShowNewToOld = true;
  bool _isFabVisable = true;
  final _scrollController = ScrollController();
  final Set<String> curr = {};

  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(_scrollListener);
    touggleFullScreen();
  }

  bool _inited = false;
  Future<void> _init() async {
    if (!ReaderInputPageData.isInited) {
      await ReaderInputPageData.init();
      if (!ReaderInputPageData.isInited) return;
    }

    for (final b in ReaderInputPageData.books) {
      final f = await ReaderPageSettings.lurFile(b.hash);
      try {
        for (final l in await f.readAsLines()) {
          if (l.isEmpty) return;
          curr.add(l);
        }
      } catch (_) {}
    }
    setState(() {
      _inited = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isFabVisable) {
      setState(() {
        _isFabVisable = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isFabVisable) {
      setState(() {
        _isFabVisable = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFabVisable = appConf.hideAppbar ? _isFabVisable : true;

    return Scaffold(
      body: GestureStack(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: !_inited
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  // key: ValueKey(_isShowNewToOld),
                  controller: _scrollController,
                  slivers: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SliverAppBar(
                        floating: true,
                        snap: appConf.hideAppbar,
                        pinned: !appConf.hideAppbar,
                        title: Text(
                          'All Foreign${curr.isEmpty ? "" : " ${curr.length}"}',
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.info_outlined),
                            tooltip: 'Info',
                            onPressed: () => showLuwAllInfo(context),
                          ),
                        ],
                      ),
                    ),
                    if (curr.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.3,
                          ),
                          child: Center(
                            child: Text('No Words', textDirection: L.dir),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: scrollPaddingW(bottom: 128),
                        sliver: SliverList.separated(
                          itemCount: curr.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, visualIndex) {
                            final index = _isShowNewToOld
                                ? curr.length - 1 - visualIndex
                                : visualIndex;

                            final word = curr.elementAt(index);
                            final bm = BookMarks.isSet(word);

                            return Material(
                              color: cs.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: cs.outlineVariant),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),

                                title: Text(
                                  // '${itm.word} • ${itm.dict.name}',
                                  word,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: L.arStyle,
                                ),
                                onTap: () {
                                  openDict(
                                    context,
                                    word,
                                  ).then((_) => setState(() {}));
                                },
                                leading: IconButton(
                                  icon: bm
                                      ? Icon(Icons.bookmark, color: cs.error)
                                      : Icon(Icons.bookmark_outline),
                                  onPressed: () async {
                                    if (bm) {
                                      final confirm = await showConfirmDialog(
                                        context,
                                        'Remove Bookmark: $word',
                                        // message: 'Remove: $word',
                                        destructive: true,
                                        confirmText: 'Remove',
                                      );
                                      if (confirm != true) return;
                                      await BookMarks.rm(word);
                                    } else {
                                      BookMarks.add(word);
                                    }
                                    if (context.mounted) setState(() {});
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ),
      floatingActionButton: curr.isNotEmpty
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: isFabVisable ? Offset.zero : const Offset(0, 4),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isFabVisable ? 1.0 : 0.0,
                child: FloatingActionButton(
                  onPressed: () =>
                      setState(() => _isShowNewToOld = !_isShowNewToOld),
                  child: const Icon(Icons.swap_vert),
                ),
              ),
            )
          : null,
    );
  }
}
