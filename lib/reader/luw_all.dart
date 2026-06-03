import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/word_store.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/multi_selection.dart';
import 'package:ara_dict/reader/luw.dart';
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

  List<String> _curr = [];

  late final SelectionController<String> _selection;

  @override
  void initState() {
    super.initState();

    _selection = SelectionController(() {
      if (mounted) setState(() {});
    });

    _init();

    _scrollController.addListener(_scrollListener);
    touggleFullScreen();
  }

  bool _inited = false;
  Future<void> _init() async {
    await migrateForeigns();
    _curr = WordStore.foreignWords;

    if (!mounted) return;
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
                          title: _selection.appBarTitle(
                            'All Foreign${_curr.isEmpty ? "" : " ${_curr.length}"}',
                          ),
                          centerTitle: !_selection.hasSelection,
                          actions: _selection.hasSelection
                              ? _selection.genricAppBarActions(
                                  context,
                                  all: () => _curr,
                                  rm: (itms) async =>
                                      await WordStore.removeForeignMany(itms),
                                )
                              : [
                                  IconButton(
                                    icon: const Icon(Icons.info_outlined),
                                    tooltip: 'Info',
                                    onPressed: () => showLuwAllInfo(context),
                                  ),
                                ],
                        ),
                      ),
                      if (_curr.isEmpty)
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
                            itemCount: _curr.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, visualIndex) {
                              final index = _isShowNewToOld
                                  ? _curr.length - 1 - visualIndex
                                  : visualIndex;

                              final word = _curr[index];

                              return SelectableWordListTitle(
                                word: word,
                                selection: _selection,
                                setState: setState,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        floatingActionButton: _curr.isNotEmpty
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
      ),
    );
  }
}

class SelectableWordListTitle extends StatelessWidget {
  final Function(VoidCallback) setState;
  final String word;
  final SelectionController<String> selection;
  final EdgeInsetsGeometry contentPadding;
  final Widget? subtitle;
  final bool deleteBtn;
  final Future<void> Function()? remove;

  const SelectableWordListTitle({
    super.key,
    required this.word,
    required this.selection,
    required this.setState,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    this.subtitle,
    this.deleteBtn = true,
    this.remove,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selection.isSelected(word);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bm = WordStore.isBm(word);

    return Material(
      color: selected ? cs.secondaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: selected,
        onLongPress: () {
          selection.toggle(word);
        },
        contentPadding: contentPadding,
        title: Text(
          word,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: L.arStyle,
        ),
        subtitle: subtitle,
        onTap: () {
          if (selection.hasSelection) {
            selection.toggle(word);
          } else {
            openDict(context, word).then((_) => setState(() {}));
          }
        },
        leading: IconButton(
          icon: bm
              ? Icon(Icons.bookmark, color: cs.error)
              : const Icon(Icons.bookmark_outline),
          onPressed: () async {
            if (bm) {
              final confirm = await showConfirmDialog(
                context,
                'Remove Bookmark: $word',
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
        trailing: selection.hasSelection
            ? Checkbox(
                value: selected,
                onChanged: (_) => selection.toggle(word),
              )
            : deleteBtn
            ? IconButton(
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

                  if (remove != null) {
                    await remove?.call();
                  } else {
                    await WordStore.removeForeign(word);
                  }
                  if (context.mounted) setState(() {});
                },
              )
            : null,
      ),
    );
  }
}
