import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LuwPage extends StatefulWidget {
  final ReaderPageSettings rs;
  const LuwPage({super.key, required this.rs});

  static Future<void> open(BuildContext context, ReaderPageSettings rs) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LuwPage(rs: rs)),
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
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: SliverAppBar(
                  floating: true,
                  snap: appConf.hideAppbar,
                  pinned: !appConf.hideAppbar,
                  title: Text(
                    L.p(
                      'Lookedup${rs.luw.isEmpty ? "" : " ${rs.luw.length}"}',
                      /* ar */ 'مبحوث ${rs.luw.isEmpty ? "" : " ${enToArNum(rs.luw.length)}"}',
                    ),
                    textDirection: L.dir,
                    style: L.arStyleIf,
                  ),
                  actions: [
                    if (rs.luw.isNotEmpty)
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
                          await rs.luwRmAll();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
              if (rs.luw.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: Center(
                      child: Text(
                        L.p('Search some words', /*ar */ 'ابحث بعض الكلمات'),
                        style: L.arStyleIf,
                        textDirection: L.dir,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: scrollPaddingW(bottom: 128),
                  sliver: SliverList.separated(
                    itemCount: rs.luw.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, visualIndex) {
                      final index = _isShowNewToOld
                          ? rs.luw.length - 1 - visualIndex
                          : visualIndex;

                      final word = rs.luw.elementAt(index);
                      final bm = BookMarks.isSet(word);

                      return Material(
                        color: cs.surfaceContainer,
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
                                BookMarks.rm(word);
                              } else {
                                BookMarks.add(word);
                              }
                              setState(() {});
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

                              await rs.luwRm(word);
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
      floatingActionButton: rs.luw.isNotEmpty
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: isFabVisable ? Offset.zero : const Offset(0, 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isFabVisable ? 1.0 : 0.0,
                child: FloatingActionButton(
                  onPressed: () {
                    _isShowNewToOld = !_isShowNewToOld;
                    setState(() {});
                  },
                  child: const Icon(Icons.swap_vert),
                ),
              ),
            )
          : null,
    );
  }
}
