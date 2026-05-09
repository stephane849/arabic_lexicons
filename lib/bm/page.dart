import 'package:ara_dict/bm/book_makrs_utils.dart';
import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BookMarkPage extends StatefulWidget {
  const BookMarkPage({super.key});

  @override
  State<BookMarkPage> createState() => _BookMarkPageState();
}

class _BookMarkPageState extends State<BookMarkPage> {
  bool _isShowNewToOld = true;
  bool _isFabVisable = true;
  bool _isSelecting = false;
  List<bool> _selectedWords = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    hideStatusBar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    hideStatusBar();
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

  List<String> _selectedWordsList() {
    if (!_isSelecting) return const [];

    final res = <String>[];
    for (int i = 0; i < _selectedWords.length; i++) {
      if (_selectedWords[i]) res.add(BookMarks.words.elementAt(i));
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isSelecting) {
          setState(() => _isSelecting = false);
          return;
        }
        Navigator.pop(context);
      },
      child: Scaffold(
        // appBar: AppBar(),
        drawer: buildDrawer(context),
        body: GestureStack(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: false,
                  title: Text(
                    L.p(
                      'Bookmarks${BookMarks.isEmpty ? "" : " (${BookMarks.length})"}',
                      /* ar */ 'المحفوظات${BookMarks.isEmpty ? "" : " (${enToArNum(BookMarks.length)})"}',
                    ),
                    style: L.arStyleIf,
                  ),
                  actions: [
                    if (_isSelecting) ...[
                      IconButton(
                        icon: const Icon(Icons.checklist),
                        tooltip: L.p('Select all', 'تحديد الكل'),
                        onPressed: () => setState(() {
                          if (_selectedWords.length != BookMarks.length) {
                            _selectedWords = List.filled(
                              BookMarks.length,
                              true,
                            );
                          } else {
                            _selectedWords.fillRange(
                              0,
                              _selectedWords.length,
                              true,
                            );
                          }
                        }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear_all),
                        tooltip: L.p('Deselect all', 'إلغاء التحديد'),
                        onPressed: () => setState(() {
                          _isSelecting = false;
                          _selectedWords = List.filled(BookMarks.length, false);
                        }),
                      ),
                    ],
                    buildBookmarkMenu(
                      context,
                      () => setState(() {
                        _isSelecting = false;
                        _selectedWords = List.filled(BookMarks.length, false);
                      }),
                      _selectedWordsList,
                    ),
                  ],
                ),
              ),
              if (BookMarks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: Center(
                      child: Text(
                        L.p('Bookmark some words', 'احفظ بعض الكلمات'),
                        style: L.arStyleIf,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: scrollPaddingW(bottom: 128),
                  sliver: SliverList.separated(
                    itemCount: BookMarks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, visualIndex) {
                      final index = _isShowNewToOld
                          ? BookMarks.length - 1 - visualIndex
                          : visualIndex;

                      final word = BookMarks.list.elementAt(index);

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
                          onTap: () {
                            if (_isSelecting) {
                              setState(() {
                                _selectedWords[index] = !_selectedWords[index];
                              });
                              return;
                            }
                            openDict(context, word);
                          },
                          onLongPress: () {
                            setState(() {
                              if (_isSelecting) {
                                _isSelecting = false;
                                _selectedWords = List.filled(
                                  BookMarks.length,
                                  false,
                                );
                                return;
                              }

                              if (_selectedWords.length != BookMarks.length) {
                                _selectedWords = List.filled(
                                  BookMarks.length,
                                  false,
                                );
                              } else {
                                _selectedWords.fillRange(
                                  0,
                                  _selectedWords.length,
                                  false,
                                );
                              }

                              _isSelecting = true;
                              _selectedWords[index] = true;
                            });
                          },
                          leading: _isSelecting
                              ? Checkbox(
                                  value: _selectedWords[index],
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedWords[index] = v ?? false;
                                    });
                                  },
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: L.p(
                                    'Remove bookmark',
                                    'حذف المحفوظة',
                                  ),
                                  onPressed: () async {
                                    final confirm = await showConfirmDialog(
                                      context,
                                      L.p('Remove Bookmark', 'حذف المحفوظة'),
                                      message: L.p(
                                        'Remove: $word',
                                        'حذف: $word',
                                      ),
                                      destructive: true,
                                      confirmText: L.p('Remove', 'حذف'),
                                      dir: L.dir,
                                    );
                                    if (confirm != true) return;

                                    if (await BookMarks.rm(word) &&
                                        context.mounted) {
                                      showSnackL(
                                        context,
                                        en: 'Deleted: $word',
                                        ar: 'تم الحذف: $word',
                                      );
                                    }
                                  },
                                ),
                          title: Text(
                            word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: L.arStyle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: BookMarks.isNotEmpty
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
      ),
    );
  }
}
