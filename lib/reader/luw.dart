import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/word_store.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LuwPage extends StatefulWidget {
  final ReaderPageSettings rs;
  final PeraEntries paras;

  const LuwPage({super.key, required this.rs, required this.paras});

  static Future<void> open(
    BuildContext context,
    PeraEntries paras,
    ReaderPageSettings rs,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LuwPage(rs: rs, paras: paras),
      ),
    );
  }

  @override
  State<LuwPage> createState() => _LuwPageState();
}

class _LuwPageState extends State<LuwPage> {
  bool _isShowNewToOld = true;
  bool _isFabVisable = true;
  final _scrollController = ScrollController();
  late final ReaderPageSettings rs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    rs = widget.rs;
    touggleFullScreen();

    loop:
    for (final l in widget.paras) {
      for (final e in l) {
        if (WordStore.isForeign(e.cl)) {
          _fws.add(e.cl);
          if (WordStore.foreignLen == _fws.length) {
            break loop;
          }
        }
      }
    }
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

  int _currentTab = 0;

  bool _bookmarkedInited = false;
  bool _bookmarkedShowing = false;
  final Set<String> _bookmarked = {};

  final Set<String> _fws = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFabVisable = appConf.hideAppbar ? _isFabVisable : true;
    final Set<String> curr = _bookmarkedShowing ? _bookmarked : _fws;

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) {
          _bookmarkedShowing = i == 1;

          if (_bookmarkedShowing && !_bookmarkedInited) {
            loop:
            for (final l in widget.paras) {
              for (final e in l) {
                if (WordStore.isBm(e.cl)) {
                  _bookmarked.add(e.cl);
                  if (WordStore.bmLen == _bookmarked.length) {
                    break loop;
                  }
                }
              }
            }
            _bookmarkedInited = true;
          }

          setState(() => _currentTab = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.visibility_rounded),
            label: 'Lookeup',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_added),
            label: 'Bookmarked',
          ),
        ],
      ),
      body: GestureStack(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomScrollView(
            key: ValueKey((_isShowNewToOld, _currentTab)),
            controller: _scrollController,
            slivers: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: SliverAppBar(
                  floating: true,
                  snap: appConf.hideAppbar,
                  pinned: !appConf.hideAppbar,
                  title: Text(
                    _bookmarkedShowing
                        ? 'Bookmarked${_bookmarked.isEmpty ? '' : ' ${_bookmarked.length}'}'
                        : 'Foreign${_fws.isEmpty ? "" : " ${_fws.length}"}',
                  ),
                  actions: [
                    if (_bookmarked.isNotEmpty && _bookmarkedShowing)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: 'Clear Current books bookmarks',
                        onPressed: () async {
                          final confirm = await showConfirmDialog(
                            context,
                            'Clear all bookmarks for current book',
                            destructive: true,
                            confirmText: 'Clear',
                          );
                          if (confirm != true) return;
                          await WordStore.rmBMs(_bookmarked);
                          _bookmarked.clear();
                          if (context.mounted) setState(() {});
                        },
                      ),

                    if (_fws.isNotEmpty && !_bookmarkedShowing)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: 'Clear history',
                        onPressed: () async {
                          final confirm = await showConfirmDialog(
                            context,
                            'Clear History',
                            destructive: true,
                            confirmText: 'Clear',
                          );
                          if (confirm != true) return;
                          await WordStore.removeForeignMany(_fws);
                          if (context.mounted) setState(() {});
                        },
                      ),
                    if (!_bookmarkedShowing)
                      IconButton(
                        icon: const Icon(Icons.info_outlined),
                        tooltip: 'Info',
                        onPressed: () => showLuwInfo(context),
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
                      final bm = _bookmarkedShowing || WordStore.isBm(word);

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
                                await WordStore.rmBM(word);
                                if (_bookmarkedShowing) {
                                  _bookmarked.remove(word);
                                }
                              } else {
                                WordStore.addBM(word);
                              }
                              if (context.mounted) setState(() {});
                            },
                          ),
                          trailing: _bookmarkedShowing
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: L.p('Delete', 'حذف'),
                                  onPressed: () async {
                                    final confirm = await showConfirmDialog(
                                      context,
                                      '${L.p('Delete: ', 'حذف:')} $word',
                                      destructive: true,
                                      confirmText: L.p('Delete', 'حذف'),
                                      dir: L.dir,
                                    );
                                    if (confirm != true) return;

                                    await WordStore.removeForeign(word);
                                    setState(() {});
                                    if (context.mounted) {
                                      showSnackL(
                                        context,
                                        en: 'Deleted: $word',
                                        ar: 'تم الحذف: $word',
                                      );
                                    }
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

Future<void> showLuwInfo(BuildContext ctx) async {
  await showInfoDialog(
    ctx,
    'Foreign Words',
    message:
        'While reading, words you look up are saved and highlighted (if enabled). '
        'This is a list of all looked-up words from the current book.',
    constraints: true,
  );
}

Future<void> showLuwAllInfo(BuildContext ctx) async {
  await showInfoDialog(
    ctx,
    'Foreign Words',
    message:
        'While reading, words you look up are saved and highlighted (if enabled). '
        'This is a combined list of all looked-up words from all book entries.',
    constraints: true,
  );
}
