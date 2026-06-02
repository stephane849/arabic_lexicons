import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/word_store.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/luw.dart';
import 'package:ara_dict/reader/reader_utils.dart';
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
  Set<String> curr = {};

  @override
  void initState() {
    super.initState();
    _init();

    _scrollController.addListener(_scrollListener);
    touggleFullScreen();
  }

  bool _inited = false;
  Future<void> _init() async {
    await migrateForeigns();
    curr = WordStore.foreignWords;

    if (!context.mounted) return;
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
                            final bm = WordStore.isBm(word);

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
                                    } else {
                                      await WordStore.addBM(word);
                                    }
                                    if (context.mounted) setState(() {});
                                  },
                                ),
                                trailing: IconButton(
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
