import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/history/history.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HistPage extends StatefulWidget {
  const HistPage({super.key});

  @override
  State<HistPage> createState() => _HistPageState();
}

class _HistPageState extends State<HistPage> {
  bool _isShowNewToOld = true;
  bool _isFabVisable = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

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
                      'History${SearchHist.isEmpty ? "" : " ${SearchHist.length}/${SearchHist.maxSize}"}',
                      /* ar */ 'سجل ${SearchHist.isEmpty ? "" : " ${enToArNum(SearchHist.length)}/${enToArNum(SearchHist.maxSize)}"}',
                    ),
                    textDirection: L.dir,
                    style: L.arStyleIf,
                  ),
                  actions: [
                    if (SearchHist.isNotEmpty)
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
                          await SearchHist.rmAll();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
              if (SearchHist.isEmpty)
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
                    itemCount: SearchHist.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, visualIndex) {
                      final index = _isShowNewToOld
                          ? SearchHist.length - 1 - visualIndex
                          : visualIndex;

                      final itm = SearchHist.item(index);
                      final bm = BookMarks.isSet(itm.word);

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
                            vertical: 4,
                          ),

                          title: Text(
                            // '${itm.word} • ${itm.dict.name}',
                            itm.word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: L.arStyle,
                          ),
                          subtitle: Text(
                            itm.dict.name,
                            style: Theme.of(context).textTheme.bodySmall?.ar,
                            textAlign: TextAlign.right,
                          ),
                          onTap: () {
                            openDict(
                              context,
                              itm.word,
                              dict: itm.dict,
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
                                  'Remove Bookmark',
                                  message: 'Remove: ${itm.word}',
                                  destructive: true,
                                  confirmText: 'Remove',
                                );
                                if (confirm != true) return;
                                BookMarks.rm(itm.word);
                              } else {
                                BookMarks.add(itm.word);
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
                                '${L.p('Delete: ', 'حذف:')} ${itm.word}',
                                destructive: true,
                                confirmText: L.p('Delete', 'حذف'),
                                dir: L.dir,
                              );
                              if (confirm != true) return;

                              final deleted = await SearchHist.rm(itm.word);
                              setState(() {});
                              if (deleted && context.mounted) {
                                showSnackL(
                                  context,
                                  en: 'Deleted: ${itm.word}',
                                  ar: 'تم الحذف: ${itm.word}',
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
      floatingActionButton: SearchHist.isNotEmpty
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _isFabVisable ? Offset.zero : const Offset(0, 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isFabVisable ? 1.0 : 0.0,
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
