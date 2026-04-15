import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/sv.dart';
import 'package:ara_dict/utils.dart';
import 'package:crypto/crypto.dart'; // for hashing
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BookEntry {
  final String hash;
  final String name;
  final String nameCl;
  final bool pinned;
  BookEntry({
    required this.hash,
    required this.name,
    required this.nameCl,
    required this.pinned,
  });

  BookEntry copyWith({
    String? hash,
    String? name,
    String? nameCl,
    bool? pinned,
  }) {
    return BookEntry(
      hash: hash ?? this.hash,
      name: name ?? this.name,
      nameCl: nameCl ?? this.nameCl,
      pinned: pinned ?? this.pinned,
    );
  }
}

class _ReaderInputPageData {
  static bool isInited = false;
  static Directory? booksDir;
  static File? indexFile;
  static File? tmpIndexFile;
  static List<BookEntry> books = [];
  static List<BookEntry> booksUnord = [];

  static Future<void> init(VoidCallback callback) async {
    if (isInited) {
      setBookUnord();
      if (books.isNotEmpty) callback();
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      booksDir = Directory(join(dir.path, 'books'));
      if (!await booksDir!.exists()) {
        await booksDir!.create();
      }
      indexFile = File(join(booksDir!.path, 'books.txt'));
      tmpIndexFile = File(join(booksDir!.path, 'books_tmp.txt'));
      isInited = true;
    } catch (e) {
      debugPrint('err while initing booksdir: $e');
      isInited = false;
      return;
    }

    if (!await indexFile!.exists()) return;
    final lines = await indexFile!.readAsLines();

    books.clear(); // just incase
    books = lines
        .map((line) {
          final parts = line.split(':');
          if (parts.length == 3) {
            final pinned = parts[0] == '1';
            final hash = parts[1];
            final name = parts.sublist(2).join(':');
            return BookEntry(
              hash: hash,
              name: name,
              nameCl: ArabicNormalizer.keepOnlyArWithSpace(name),
              pinned: pinned,
            );
          }
          // TODO: remove. keep legacy for now
          if (parts.length == 2) {
            final hash = parts[0];
            final name = parts.sublist(1).join(':');
            return BookEntry(
              hash: hash,
              name: name,
              nameCl: ArabicNormalizer.keepOnlyArWithSpace(name),
              pinned: false,
            );
          }
          return null;
        })
        .whereType<BookEntry>()
        .toList();

    setBookUnord();
    if (books.isNotEmpty) callback();
  }

  static void setBookUnord({String match = "", bool newToOld = true}) {
    List<BookEntry> nl = newToOld
        ? List.from(books.reversed)
        : List.from(books);

    if (match.isNotEmpty) {
      nl = nl.where((e) => e.nameCl.contains(match)).toList();
    }

    nl.sort((a, b) {
      if (a.pinned && b.pinned) return 0;
      if (a.pinned) return -1;
      if (b.pinned) return 1;
      return 0;
    });

    booksUnord = nl;
  }
}

class ReaderInputPage extends StatefulWidget {
  const ReaderInputPage({super.key});

  @override
  State<ReaderInputPage> createState() => _ReaderInputPageState();
}

class _ReaderInputPageState extends State<ReaderInputPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ReaderInputPageData.init(() {
      setState(() {});
    });

    hideStatusBar();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    // showStatusBar();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    hideStatusBar();
  }

  Future<void> _showText(BuildContext context) async {
    final text = _controller.text.trim();
    final paras = cleanReaderInputAndPrepare(text);
    if (text.isEmpty || paras.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Insert some text first!')));
      return;
    }

    String hash = "";
    bool fresh = true;
    if (!_isTempMode) {
      (hash, fresh) = await _saveBookTxt(paras);
    }

    final rs = fresh
        ? ReaderPageSettings.def(hash: hash, isQasidah: _isQasidahMode)
        : await ReaderPageSettings.loadFromFile(
            hash,
            isQasidah: _isQasidahMode,
          );

    if (context.mounted) {
      _openReaderPage(context, paras, rs);
    }
  }

  String _hashText(String text) {
    final bytes = utf8.encode(text);
    return sha1.convert(bytes).toString(); // short but unique
  }

  Future<(String, bool)> _saveBookTxt(List<List<WordEntry>> peras) async {
    if (!_ReaderInputPageData.isInited || peras.isEmpty) return ("", false);

    String displayName = peras.first.map((w) => w.ar).join(" ");
    if (displayName.length > 100) displayName = displayName.substring(0, 100);

    String content = peras.map((p) => p.map((w) => w.ar).join(" ")).join("\n");

    final hash = _hashText(content); // filename
    final exists = _ReaderInputPageData.books.indexWhere((b) => b.hash == hash);
    if (exists > -1) {
      final rd = _ReaderInputPageData.books[exists];
      if (rd.pinned != _isPinned) {
        _ReaderInputPageData.books[exists] = rd.copyWith(pinned: _isPinned);
        await _saveBookEntriesFile();
      }
      return (hash, false);
    }

    final file = File(join(_ReaderInputPageData.booksDir!.path, '$hash.txt'));
    try {
      await file.writeAsString(content);
      _ReaderInputPageData.books.add(
        BookEntry(
          hash: hash,
          name: displayName,
          nameCl: ArabicNormalizer.keepOnlyArWithSpace(displayName),
          pinned: _isPinned,
        ),
      );
      await _saveBookEntriesFile();
    } catch (_) {
      return ("", false);
    }

    return (hash, true);
  }

  Future<void> _deleteFile(BookEntry en) async {
    final index = _ReaderInputPageData.books.indexWhere(
      (e) => e.hash == en.hash,
    );
    if (index < 0) {
      return;
    }
    final be = _ReaderInputPageData.books.removeAt(index);
    final file = File(
      join(_ReaderInputPageData.booksDir!.path, '${be.hash}.txt'),
    );
    try {
      await file.delete();
    } catch (e) {
      return;
    }

    await _saveBookEntriesFile();
    ReaderPageSettings.delete(be.hash);
  }

  Future<void> _saveBookEntriesFile() async {
    if (!_ReaderInputPageData.isInited) return;

    final txt = _ReaderInputPageData.books
        .map((be) => '${be.pinned ? "1" : "0"}:${be.hash}:${be.name}')
        .join("\n");
    await _ReaderInputPageData.tmpIndexFile!.writeAsString(txt);
    await _ReaderInputPageData.tmpIndexFile!.rename(
      _ReaderInputPageData.indexFile!.path,
    );

    // whenever this is called
    _ReaderInputPageData.setBookUnord(
      match: _searchText,
      newToOld: _isShowEntrieNewToOld,
    );
    if (mounted) setState(() {});
  }

  Future<void> _tglPinBookEntries(String hash) async {
    final idx = _ReaderInputPageData.books.indexWhere((b) => b.hash == hash);
    if (idx < 0) return;
    final en = _ReaderInputPageData.books[idx];
    _ReaderInputPageData.books[idx] = en.copyWith(pinned: !en.pinned);
    await _saveBookEntriesFile();
  }

  Future<void> _openBook(BuildContext context, BookEntry entry) async {
    final file = File(
      join(_ReaderInputPageData.booksDir!.path, '${entry.hash}.txt'),
    );
    try {
      if (!await file.exists()) throw "";

      final content = await file.readAsString();
      final paras = cleanReaderInputAndPrepare(content);

      final rs = await ReaderPageSettings.loadFromFile(entry.hash);
      if (context.mounted) {
        _openReaderPage(context, paras, rs);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open book')));
      }
      return;
    }
  }

  void _openReaderPage(
    BuildContext context,
    List<List<WordEntry>> paras,
    ReaderPageSettings rs,
  ) {
    if (paras.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open book')));
      return;
    }
    openReaderPage(context, paras, rs);
  }

  bool _isTempMode = false;
  bool _isQasidahMode = false;
  bool _isPinned = false;
  bool _isShowEntrieNewToOld = true;

  String _searchText = "";

  @override
  Widget build(BuildContext context) {
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final cs = Theme.of(context).colorScheme;

    // it's true sotaht it stats out as no color!
    bool lastListItemColored = false;

    return Scaffold(
      drawer: buildDrawer(context),
      body: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomScrollView(
            slivers: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: false,
                  title: Text(
                    /*txt*/ 'مدخل القارئ',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _controller,
                          textDirection: TextDirection.rtl,
                          maxLines: 3,
                          style: arabicFontStyle,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'اكتب هنا…',
                            hintTextDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              FilterChip(
                                showCheckmark: false,
                                avatar: const Icon(Icons.save, size: 18),
                                label: const Text('Save'),
                                selected: !_isTempMode,
                                onSelected: (_) =>
                                    setState(() => _isTempMode = !_isTempMode),
                              ),
                              FilterChip(
                                showCheckmark: false,
                                avatar: const Icon(Icons.music_note, size: 18),
                                label: const Text('Qasidah'),
                                selected: _isQasidahMode,
                                onSelected: (v) =>
                                    setState(() => _isQasidahMode = v),
                              ),

                              FilterChip(
                                showCheckmark: false,
                                avatar: const Icon(Icons.push_pin, size: 18),
                                label: const Text('Pin'),
                                selected: _isPinned,
                                onSelected: (v) =>
                                    setState(() => _isPinned = v),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 6,
                          children: [
                            OutlinedButton(
                              // style: btnTheme,
                              child: Text('Paste'),
                              onPressed: () async {
                                final txt = await getClipboardText();
                                if (txt != null) {
                                  // _controller.clear();
                                  _controller.text = _controller.text + txt;
                                }
                              },
                              // icon: Icon(Icons.paste),
                            ),
                            OutlinedButton(
                              // style: btnTheme,
                              child: Text('Clear'),
                              onPressed: () async {
                                if (_controller.text.isEmpty) return;

                                final res = await showConfirmDialog(
                                  context,
                                  'Clear all text?',
                                  // message: 'Do you want to clear the texts?',
                                );
                                if (res != null && res) _controller.clear();
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: FilledButton.icon(
                            label: Text('Go', style: TextStyle(fontSize: 18)),
                            icon: Icon(Icons.start, size: 18),
                            // iconAlignment: IconAlignment.end,
                            onPressed: () => _showText(context),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 26),
                    if (_ReaderInputPageData.books.isNotEmpty)
                      Tooltip(
                        message: 'Click to reverse sorting order',
                        child: InkWell(
                          // borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            _isShowEntrieNewToOld = !_isShowEntrieNewToOld;
                            _ReaderInputPageData.setBookUnord(
                              match: _searchText,
                              newToOld: _isShowEntrieNewToOld,
                            );
                            setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              /* Txt */ 'قائمة النص [${enToArNum(_ReaderInputPageData.books.length)}] ${_isShowEntrieNewToOld ? "(جديد إلى قديم)" : "(قديم إلى جديد)"} ',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: arabicFontStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_ReaderInputPageData.books.isNotEmpty)
                      TextField(
                        controller: _searchController,
                        style: arabicFontStyle,
                        onChanged: (s) {
                          s = ArabicNormalizer.keepOnlyArWithSpace(s);
                          if (s == _searchText) return;
                          _searchText = s;

                          _ReaderInputPageData.setBookUnord(
                            match: s,
                            newToOld: _isShowEntrieNewToOld,
                          );
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          suffixIcon: _searchText.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchText = "";

                                    _ReaderInputPageData.setBookUnord(
                                      match: "",
                                      newToOld: _isShowEntrieNewToOld,
                                    );
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                          border: OutlineInputBorder(),
                          hintText: 'ابحث عن الكتب…',
                          hintTextDirection: TextDirection.rtl,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    if (_ReaderInputPageData.booksUnord.isNotEmpty) Divider(),
                    if (_ReaderInputPageData.booksUnord.isNotEmpty)
                      ...List.generate(_ReaderInputPageData.booksUnord.length, (
                        index,
                      ) {
                        final en = _ReaderInputPageData.booksUnord[index];

                        // 1st index always no color
                        lastListItemColored = !lastListItemColored;
                        return Ink(
                          decoration: lastListItemColored
                              ? null
                              : BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(30),
                                ),
                          child: InkWell(
                            onTap: () {
                              _openBook(context, en);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ).copyWith(left: 1),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      en.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                      style: arabicFontStyle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: en.pinned ? 'Unpin' : 'Pin',
                                    icon: Icon(
                                      en.pinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                    ),
                                    onPressed: () =>
                                        _tglPinBookEntries(en.hash),
                                    style: en.pinned
                                        ? IconButton.styleFrom(
                                            backgroundColor: cs.inversePrimary
                                                .withAlpha(80),
                                            foregroundColor: cs.primary,
                                          )
                                        : null,
                                  ),
                                  IconButton(
                                    tooltip: 'Delete book',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      final res = await showConfirmDialog(
                                        context,
                                        /*txt*/ 'حذف الكتاب',
                                        message:
                                            /* txt */ 'هل تريد حذف ${en.name}؟',
                                        dir: TextDirection.rtl,
                                      );
                                      if (res ?? false) {
                                        _deleteFile(en);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    if (_ReaderInputPageData.booksUnord.isNotEmpty)
                      const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
