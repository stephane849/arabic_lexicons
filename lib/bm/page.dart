import 'package:ara_dict/bm/book_makrs_utils.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/word_store.dart';
import 'package:ara_dict/multi_selection.dart';
import 'package:ara_dict/reader/luw_all.dart';
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
  final ScrollController _scrollController = ScrollController();
  late final SelectionController<String> _selection;

  @override
  void initState() {
    super.initState();

    _selection = SelectionController(() {
      if (mounted) setState(() {});
    });

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

  Iterable<String> _selectedWordsList() {
    return _selection.selected;
  }

  @override
  Widget build(BuildContext context) {
    final isFabVisable = appConf.hideAppbar ? _isFabVisable : true;

    return PopScope(
      canPop: !_selection.hasSelection,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selection.hasSelection) {
          _selection.clear();
          return;
        }
        Navigator.pop(context);
      },
      child: Scaffold(
        // appBar: AppBar(),
        // drawer: buildDrawer(context),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: GestureStack(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SliverAppBar(
                    floating: true,
                    snap: appConf.hideAppbar,
                    pinned: !appConf.hideAppbar,
                    title: _selection.appBarTitle(
                      def:
                          'Bookmarks${WordStore.bmEmpty ? "" : " (${WordStore.bmLen})"}',
                      // style: L.arStyleIf,
                    ),
                    actions: [
                      if (_selection.hasSelection)
                        ..._selection.genricAppBarActions(
                          context,
                          all: () => WordStore.bookmarkedWords,
                          rm: null,
                          deleteAll: false,
                        ),
                      // ...[
                      // IconButton(
                      //   icon: const Icon(Icons.checklist),
                      //   tooltip: L.p('Select all', 'تحديد الكل'),
                      //   onPressed: () => setState(() {
                      //     if (_selectedWords.length != WordStore.bmLen) {
                      //       _selectedWords = List.filled(WordStore.bmLen, true);
                      //     } else {
                      //       _selectedWords.fillRange(
                      //         0,
                      //         _selectedWords.length,
                      //         true,
                      //       );
                      //     }
                      //   }),
                      // ),
                      // IconButton(
                      //   icon: const Icon(Icons.clear_all),
                      //   tooltip: L.p('Deselect all', 'إلغاء التحديد'),
                      //   onPressed: () => setState(() {
                      //     _isSelecting = false;
                      //     _selectedWords = List.filled(WordStore.bmLen, false);
                      //   }),
                      // ),
                      // ],
                      buildBookmarkMenu(
                        context,
                        _selection.clear,
                        _selectedWordsList,
                      ),
                    ],
                  ),
                ),
                if (WordStore.bmEmpty)
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
                      itemCount: WordStore.bmLen,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, visualIndex) {
                        final index = _isShowNewToOld
                            ? WordStore.bmLen - 1 - visualIndex
                            : visualIndex;

                        final word = WordStore.bmAt(index);

                        return SelectableWordListTitle(
                          word: word,
                          selection: _selection,
                          setState: setState,
                          deleteBtn: false,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: WordStore.bmNotEmpty
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
      ),
    );
  }
}
