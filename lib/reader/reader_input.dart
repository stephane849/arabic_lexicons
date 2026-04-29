import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/reader.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/sv.dart';
import 'package:ara_dict/utils.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart'; // for hashing
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BookEntry {
  final String hash;
  final String name;
  final String nameCl;
  final bool pinned;

  bool selected;

  BookEntry({
    required this.hash,
    required this.name,
    required this.nameCl,
    required this.pinned,
    this.selected = false,
  });

  BookEntry copyWith({
    String? hash,
    String? name,
    String? nameCl,
    bool? pinned,
    bool? selected,
  }) {
    return BookEntry(
      hash: hash ?? this.hash,
      name: name ?? this.name,
      nameCl: nameCl ?? this.nameCl,
      pinned: pinned ?? this.pinned,
      selected: selected ?? this.selected,
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
  static const booksIndexName = 'books.txt';

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
      indexFile = File(join(booksDir!.path, booksIndexName));
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
    books = parseBooks(lines);
    setBookUnord();
    if (books.isNotEmpty) callback();
  }

  static List<BookEntry> parseBooks(Iterable<String> lines) {
    return lines
        .map((line) {
          final parts = line.split(':');
          if (parts.length == 3) {
            final pinned = parts[0] == '1';
            final hash = parts[1];
            final name = parts.sublist(2).join(':');
            return BookEntry(
              hash: hash,
              name: name,
              nameCl: ArabicNormalizer.cleanLineForSearch(name),
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
              nameCl: ArabicNormalizer.cleanLineForSearch(name),
              pinned: false,
            );
          }
          return null;
        })
        .whereType<BookEntry>()
        .toList();
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
      showSnack(context, 'Insert some text first!');
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

  Future<(String, bool)> _saveBookTxt(PeraEntries peras) async {
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

  Future<bool> _tglPinBookEntries(String hash) async {
    final idx = _ReaderInputPageData.books.indexWhere((b) => b.hash == hash);
    if (idx < 0) return false;
    final en = _ReaderInputPageData.books[idx];
    final nEn = en.copyWith(pinned: !en.pinned);
    _ReaderInputPageData.books[idx] = nEn;
    await _saveBookEntriesFile();
    return nEn.pinned;
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
        showSnack(context, 'Could not open book');
      }
      return;
    }
  }

  void _openReaderPage(
    BuildContext context,
    PeraEntries paras,
    ReaderPageSettings rs,
  ) {
    if (paras.isEmpty) {
      showSnack(context, 'Could not open book');
      return;
    }
    openReaderPage(context, paras, rs);
  }

  bool _isTempMode = false;
  bool _isQasidahMode = false;
  bool _isPinned = false;
  bool _isShowEntrieNewToOld = true;

  String _searchText = "";
  bool isSelecting = false;

  @override
  Widget build(BuildContext context) {
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final cs = Theme.of(context).colorScheme;

    // it's true sotaht it stats out as no color!
    bool lastListItemColored = false;

    return PopScope(
      canPop: !isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isSelecting) {
          setState(() => isSelecting = false);
          return;
        }
        Navigator.pop(context);
      },
      child: Scaffold(
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
                      style: TextStyle(fontFamily: fontTajawal),
                    ),

                    actions: [
                      if (isSelecting) ...[
                        IconButton(
                          icon: const Icon(Icons.checklist),
                          tooltip: 'Select all',
                          onPressed: () => setState(() {
                            final l = _ReaderInputPageData.booksUnord.length;
                            for (int i = 0; i < l; i++) {
                              _ReaderInputPageData.booksUnord[i].selected =
                                  true;
                            }
                          }),
                        ),

                        IconButton(
                          icon: const Icon(Icons.clear_all),
                          tooltip: 'Clear Selection',
                          onPressed: () => setState(() {
                            isSelecting = false;
                          }),
                        ),
                      ],

                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          switch (value) {
                            case 'delete_selected':
                              final List<BookEntry> selected = isSelecting
                                  ? _ReaderInputPageData.booksUnord
                                        .where((b) => b.selected)
                                        .toList()
                                  : [];

                              if (selected.isEmpty) {
                                showSnack(
                                  context,
                                  'Long press on the book entries to start selection',
                                );
                                return;
                              }

                              final confirm = await showConfirmDialog(
                                context,
                                'Delete ${selected.length} book${selected.length > 1 ? "s" : ""}',
                                message:
                                    'Delete selected books?'
                                    '\nThis action cannot be undone.',
                                confirmText: 'Delete Selected',
                                destructive: true,
                              );
                              if (confirm != true) return;

                              VoidCallback? stopSpiner;
                              if (context.mounted) {
                                stopSpiner = showSpinningDialog(
                                  context,
                                  'Deleting...',
                                );
                              }

                              final d = _ReaderInputPageData.booksDir!.path;
                              for (final b in selected) {
                                _ReaderInputPageData.books.removeWhere(
                                  (bb) => b.hash == bb.hash,
                                );
                                try {
                                  await File(join(d, '${b.hash}.txt')).delete();
                                  ReaderPageSettings.delete(b.hash);
                                } catch (_) {}
                              }
                              isSelecting = false;
                              _saveBookEntriesFile();

                              stopSpiner?.call();
                              if (context.mounted) {
                                showSnack(
                                  context,
                                  'Deleted: ${selected.length}',
                                );
                              }
                              break;

                            case 'delete_all':
                              final confirm = await showConfirmDialog(
                                context,
                                'Delete',
                                message:
                                    'Delete All Books?\n'
                                    'This action cannot be undone.',
                                confirmText: 'Delete All',
                                destructive: true,
                              );
                              if (confirm != true) return;

                              VoidCallback? stopSpinner;
                              if (context.mounted) {
                                stopSpinner = showSpinningDialog(
                                  context,
                                  'Deleting...',
                                );
                              }

                              int delCount = 0;
                              final books = _ReaderInputPageData.books;
                              final d = _ReaderInputPageData.booksDir!.path;

                              for (final b in books) {
                                try {
                                  await File(join(d, '${b.hash}.txt')).delete();
                                  delCount++;
                                  ReaderPageSettings.delete(b.hash);
                                } catch (_) {}
                              }
                              _ReaderInputPageData.books.clear();
                              isSelecting = false;
                              _saveBookEntriesFile();

                              stopSpinner?.call();
                              if (context.mounted) {
                                showSnack(context, 'Deleted: $delCount');
                              }
                              break;

                            case 'export':
                              if (!_ReaderInputPageData.isInited ||
                                  _ReaderInputPageData.books.isEmpty) {
                                if (context.mounted) {
                                  showSnack(context, 'No books to export');
                                }
                                return;
                              }

                              final confirmed = await showConfirmDialog(
                                context,
                                'Export',
                                message:
                                    'The entered books will be saved as a zip file. '
                                    'You can import them later. '
                                    'After exporting, make sure it was saved properly. '
                                    'Do you want to export?',
                                confirmText: 'Export',
                                constraints: true,
                              );
                              if (confirmed != true) return;

                              VoidCallback? stopSpinner;
                              if (context.mounted) {
                                stopSpinner = showSpinningDialog(
                                  context,
                                  'Exporting...',
                                );
                              }

                              final d = _ReaderInputPageData.booksDir!.path;
                              const fileName = 'Arabic_Lexicons_books.zip';
                              final zipFileOut = join(
                                (await getTemporaryDirectory()).path,
                                fileName,
                              );

                              final List<String> names = [
                                _ReaderInputPageData.booksIndexName,
                              ];
                              final List<String> sourcefiels = [
                                join(d, _ReaderInputPageData.booksIndexName),
                              ];

                              for (final b in _ReaderInputPageData.books) {
                                final name = '${b.hash}.txt';
                                names.add(name);
                                sourcefiels.add(join(d, name));
                              }

                              List<int> zippedData;
                              try {
                                (_, zippedData) = await zipFiles(
                                  names,
                                  sourcefiels,
                                  zipFileOut,
                                );
                              } catch (e) {
                                if (kDebugMode) {
                                  debugPrint('$e');
                                }

                                stopSpinner?.call();
                                if (context.mounted) {
                                  showSnack(context, 'Could not zip');
                                }
                                return;
                              }

                              stopSpinner?.call();
                              if (context.mounted) {
                                showBackupOptions(
                                  context,
                                  fileName: fileName,
                                  title: 'Export Ready',
                                  saveDialogTitle: 'Save books',
                                  filePaht: zipFileOut,
                                  fileData: zippedData,
                                  allowedExt: ['zip'],
                                );
                              }
                              break;

                            case 'import':
                              final confirmed = await showConfirmDialog(
                                context,
                                'Import',
                                message:
                                    'If the book in the backup already exists, then it is skipped. '
                                    'Do you want to import?',
                                confirmText: 'Select File',
                                constraints: true,
                              );
                              if (confirmed != true) return;

                              VoidCallback? stopSpinner;
                              if (context.mounted) {
                                stopSpinner = showSpinningDialog(
                                  context,
                                  'Importing...',
                                );
                              }

                              Archive archiveData;
                              List<BookEntry> books;
                              try {
                                FilePickerResult? result =
                                    await FilePicker.pickFiles(
                                      type: FileType.any,
                                      withData: true,
                                    );

                                if (result == null ||
                                    result.files.single.bytes == null) {
                                  return;
                                }

                                archiveData = ZipDecoder().decodeBytes(
                                  result.files.single.bytes!,
                                );

                                final idxFile = archiveData.files
                                    .where(
                                      (a) =>
                                          a.name ==
                                          _ReaderInputPageData.booksIndexName,
                                    )
                                    .firstOrNull;
                                if (idxFile == null) {
                                  throw Exception('Corrupted file');
                                }

                                final bytes = idxFile.readBytes();
                                if (bytes == null) {
                                  throw Exception('Corrupted file');
                                }
                                books = _ReaderInputPageData.parseBooks(
                                  LineSplitter.split(utf8.decode(bytes)),
                                );
                              } catch (e) {
                                stopSpinner?.call();
                                if (context.mounted) {
                                  showSnack(context, 'Import failed');
                                }
                                if (kDebugMode) {
                                  debugPrint('while reading zip: $e');
                                }
                                return;
                              }

                              int added = 0;
                              int skipped = 0;
                              for (final b in books) {
                                try {
                                  final idx = _ReaderInputPageData.books
                                      .indexWhere((bb) => b.hash == bb.hash);
                                  if (idx > -1) {
                                    skipped++;
                                    continue;
                                  }

                                  final d = archiveData.files
                                      .where((a) => a.name == '${b.hash}.txt')
                                      .firstOrNull;
                                  if (d == null) continue;

                                  final bytes = d.readBytes();
                                  if (bytes == null) continue;

                                  File(
                                    join(
                                      _ReaderInputPageData.booksDir!.path,
                                      '${b.hash}.txt',
                                    ),
                                  ).writeAsString(
                                    utf8.decode(bytes), // safeguard
                                  );
                                } catch (_) {}
                                _ReaderInputPageData.books.add(b);
                                added++;
                              }

                              stopSpinner?.call();
                              if (context.mounted) {
                                showSnack(
                                  context,
                                  'Added: $added Skipped: $skipped',
                                );
                              }
                              // this has setState
                              _saveBookEntriesFile();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(Icons.upload_file),
                                SizedBox(width: 10),
                                Text('Export'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'import',
                            child: Row(
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 10),
                                Text('Import'),
                              ],
                            ),
                          ),

                          const PopupMenuDivider(),

                          const PopupMenuItem(
                            value: 'delete_all',
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep),
                                SizedBox(width: 10),
                                Text('Delete All'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete_selected',
                            child: Row(
                              children: [
                                Icon(Icons.delete),
                                SizedBox(width: 10),
                                Text('Delete Selected'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
                                  onSelected: (_) => setState(
                                    () => _isTempMode = !_isTempMode,
                                  ),
                                ),
                                FilterChip(
                                  showCheckmark: false,
                                  avatar: const Icon(
                                    Icons.music_note,
                                    size: 18,
                                  ),
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
                                    confirmText: 'Clear',
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
                      if (_ReaderInputPageData.books.isNotEmpty) ...[
                        TextField(
                          controller: _searchController,
                          style: arabicFontStyle,
                          onChanged: (input) {
                            final s = ArabicNormalizer.cleanLineForSearch(
                              input,
                            );
                            if (s == _searchText) return;

                            _searchText = s;

                            _ReaderInputPageData.setBookUnord(
                              match: s,
                              newToOld: _isShowEntrieNewToOld,
                            );
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
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
                        Divider(),
                        ...List.generate(
                          _ReaderInputPageData.booksUnord.length,
                          (index) {
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
                                  if (isSelecting) {
                                    setState(() {
                                      _ReaderInputPageData
                                          .booksUnord[index]
                                          .selected = !_ReaderInputPageData
                                          .booksUnord[index]
                                          .selected;
                                    });
                                    return;
                                  }
                                  _openBook(context, en);
                                },
                                onLongPress: () {
                                  setState(() {
                                    if (isSelecting) {
                                      setState(() {
                                        isSelecting = false;
                                      });
                                      return;
                                    }
                                    final ln =
                                        _ReaderInputPageData.booksUnord.length;
                                    for (int i = 0; i < ln; i++) {
                                      _ReaderInputPageData
                                              .booksUnord[i]
                                              .selected =
                                          false;
                                    }
                                    isSelecting = true;
                                    _ReaderInputPageData
                                            .booksUnord[index]
                                            .selected =
                                        true;
                                  });
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
                                      if (isSelecting)
                                        Checkbox(
                                          value: _ReaderInputPageData
                                              .booksUnord[index]
                                              .selected,
                                          onChanged: (v) => setState(() {
                                            _ReaderInputPageData
                                                    .booksUnord[index]
                                                    .selected =
                                                v ?? false;
                                          }),
                                        )
                                      else ...[
                                        IconButton(
                                          tooltip: en.pinned ? 'Unpin' : 'Pin',
                                          icon: Icon(
                                            en.pinned
                                                ? Icons.push_pin
                                                : Icons.push_pin_outlined,
                                          ),
                                          onPressed: () async {
                                            if (en.pinned) {
                                              final confrim =
                                                  await showConfirmDialog(
                                                    context,
                                                    'Unpin a Book',
                                                    message:
                                                        'Unpin: ${en.name}',
                                                    confirmText: 'Unpin',
                                                    destructive: true,
                                                  );
                                              if (confrim != true) return;
                                            }
                                            final pinned =
                                                await _tglPinBookEntries(
                                                  en.hash,
                                                );
                                            if (context.mounted) {
                                              final p = pinned
                                                  ? 'Pinned'
                                                  : 'Unpinned';
                                              showSnack(
                                                context,
                                                '$p: ${en.name}',
                                              );
                                            }
                                          },
                                          style: en.pinned
                                              ? IconButton.styleFrom(
                                                  backgroundColor: cs
                                                      .inversePrimary
                                                      .withAlpha(80),
                                                  foregroundColor: cs.primary,
                                                )
                                              : null,
                                        ),
                                        IconButton(
                                          tooltip: 'Delete book',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: () async {
                                            final confirm =
                                                await showConfirmDialog(
                                                  context,
                                                  'Delete a Book',
                                                  message: 'Delete: ${en.name}',
                                                  confirmText: 'Delete',
                                                  destructive: true,
                                                  constraints:
                                                      en.name.length > 50,
                                                );
                                            if (confirm != true) return;
                                            await _deleteFile(en);
                                            if (context.mounted) {
                                              showSnack(
                                                context,
                                                'Deleted: ${en.name}',
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 120),
                      ],
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
}
