import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/first_run.dart';
import 'package:ara_dict/helper_widgets.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/reader.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
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

String bookPath(String bookHash) =>
    path.join(_ReaderInputPageData.booksDir!.path, '$bookHash.txt');

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
      booksDir = Directory(path.join(dir.path, 'books'));
      if (!await booksDir!.exists()) {
        await booksDir!.create(recursive: true);
      }
      indexFile = File(path.join(booksDir!.path, booksIndexName));
      tmpIndexFile = File(path.join(booksDir!.path, 'books_tmp.txt'));
      isInited = true;
    } catch (e) {
      debugPrint('err while initing booksdir: $e');
      isInited = false;
      return;
    }

    if (!await indexFile!.exists()) return;
    final lines = await indexFile!.readAsLines();

    books.clear();
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

          // legacy
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
    final source = newToOld ? books.reversed : books;

    final List<({int idx, BookEntry book})> indexed = [];

    for (final (idx, bk) in source.indexed) {
      indexed.add((idx: idx, book: bk));
    }

    // source.asMap().entries.map((e) {
    //   return (idx: e.key, book: e.value);
    // }).toList();

    indexed.sort((a, b) {
      final pinA = a.book.pinned ? 0 : 1;
      final pinB = b.book.pinned ? 0 : 1;
      if (pinA != pinB) return pinA.compareTo(pinB);
      return a.idx.compareTo(b.idx);
    });

    if (match.isEmpty) {
      booksUnord = indexed.map((e) => e.book).toList(growable: false);
      return;
    }

    final List<({int idx, int matchIdx})> matchIndexs = [];

    for (int i = 0; i < indexed.length; i++) {
      final idx = indexed[i].book.nameCl.indexOf(match);
      if (idx > -1) matchIndexs.add((idx: i, matchIdx: idx));
    }

    matchIndexs.sort((a, b) => a.matchIdx.compareTo(b.matchIdx));

    final List<BookEntry> matches = [];

    for (final idx in matchIndexs) {
      matches.add(indexed[idx.idx].book);
    }
    booksUnord = matches;
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

  bool _isTempMode = false;
  bool _isQasidahMode = false;
  bool _isPinned = false;
  bool _isShowEntrieNewToOld = true;

  String _searchText = "";
  bool isSelecting = false;

  @override
  void initState() {
    super.initState();
    _ReaderInputPageData.init(() {
      setState(() {});
    });

    touggleFullScreen();

    showFirstRunPopupPostFrame(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  void _clearAllSelections() {
    for (final b in _ReaderInputPageData.books) {
      b.selected = false;
    }
  }

  void _stopSelectionMode() {
    _clearAllSelections();
    isSelecting = false;
  }

  List<BookEntry> _selectedBooks() {
    return _ReaderInputPageData.books.where((b) => b.selected).toList();
  }

  String _hashText(String text) {
    final bytes = utf8.encode(text);
    return sha1.convert(bytes).toString();
  }

  Future<void> _showText(BuildContext context) async {
    final text = _controller.text.trim();
    final paras = cleanReaderInputAndPrepare(text);

    if (text.isEmpty || paras.isEmpty) {
      showSnackL(
        context,
        en: 'Insert some text first!',
        ar: 'أدخل نصًا أولًا!',
      );
      return;
    }

    String? bookHash;
    bool fresh = true;

    if (!_isTempMode) {
      (bookHash, fresh) = await _saveBookTxt(paras);
      if (bookHash.isEmpty) {
        if (context.mounted) {
          showSnackL(context, en: 'Could not save book', ar: 'تعذر حفظ الكتاب');
        }
        return;
      }
    }

    // final rs = fresh
    //     ? ReaderPageSettings.def(hash: bookHash, isQasidah: _isQasidahMode)
    //     : await ReaderPageSettings.loadFromFile(
    //         bookHash,
    //         isQasidah: _isQasidahMode,
    //       );

    if (context.mounted) {
      _openReaderPage(
        context,
        paras: paras,
        bookHash: bookHash,
        isQasidah: fresh ? _isQasidahMode : null,
      );
    }
  }

  Future<(String, bool)> _saveBookTxt(PeraEntries peras) async {
    if (!_ReaderInputPageData.isInited || peras.isEmpty) return ("", false);

    String displayName = peras.first.map((w) => w.ar).join(" ").trim();
    if (displayName.length > 100) {
      displayName = displayName.substring(0, 100);
    }

    final content = peras.map((p) => p.map((w) => w.ar).join(" ")).join("\n");
    final hash = _hashText(content);

    final exists = _ReaderInputPageData.books.indexWhere((b) => b.hash == hash);
    if (exists > -1) {
      final rd = _ReaderInputPageData.books[exists];
      if (rd.pinned != _isPinned) {
        _ReaderInputPageData.books[exists] = rd.copyWith(pinned: _isPinned);
        await _saveBookEntriesFile();
      }
      return (hash, false);
    }

    final file = File(
      path.join(_ReaderInputPageData.booksDir!.path, '$hash.txt'),
    );
    try {
      await file.writeAsString(content, flush: true);
      _ReaderInputPageData.books.add(
        BookEntry(
          hash: hash,
          name: displayName,
          nameCl: ArabicNormalizer.keepOnlyArWithSpace(displayName),
          pinned: _isPinned,
        ),
      );
      await _saveBookEntriesFile();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('save book failed: $e');
      }
      return ("", false);
    }

    return (hash, true);
  }

  Future<void> _saveBookEntriesFile() async {
    if (!_ReaderInputPageData.isInited) return;
    if (_ReaderInputPageData.indexFile == null ||
        _ReaderInputPageData.tmpIndexFile == null) {
      return;
    }

    final txt = _ReaderInputPageData.books
        .map((be) => '${be.pinned ? "1" : "0"}:${be.hash}:${be.name}')
        .join("\n");

    try {
      await _ReaderInputPageData.tmpIndexFile!.writeAsString(txt, flush: true);

      if (await _ReaderInputPageData.indexFile!.exists()) {
        await _ReaderInputPageData.indexFile!.delete();
      }

      await _ReaderInputPageData.tmpIndexFile!.rename(
        _ReaderInputPageData.indexFile!.path,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('save books index failed: $e');
      }
    }

    _ReaderInputPageData.setBookUnord(
      match: _searchText,
      newToOld: _isShowEntrieNewToOld,
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteFile(BookEntry en) async {
    final index = _ReaderInputPageData.books.indexWhere(
      (e) => e.hash == en.hash,
    );
    if (index < 0) return;

    final file = File(
      path.join(_ReaderInputPageData.booksDir!.path, '${en.hash}.txt'),
    );

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('delete book file failed: $e');
      }
      return;
    }

    final be = _ReaderInputPageData.books.removeAt(index);
    await _saveBookEntriesFile();
    ReaderPageSettings.delete(be.hash);
  }

  Future<void> _openBook(BuildContext context, BookEntry entry) async {
    if (context.mounted) {
      _openReaderPage(context, bookHash: entry.hash);
    }
  }

  void _openReaderPage(
    BuildContext context, {
    PeraEntries? paras,
    String? bookHash,
    bool? isQasidah,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: Routes.readerPage),
        builder: (_) =>
            ReaderPage(paras: paras, bookHash: bookHash, isQasidah: isQasidah),
      ),
    );
  }

  Future<void> _deleteSelectedBooks(BuildContext context) async {
    final selected = _selectedBooks();
    if (selected.isEmpty) {
      showSnackL(
        context,
        en: 'Long press on a book to start selection',
        ar: 'اضغط مطولًا على كتاب لبدء التحديد',
      );
      return;
    }

    final confirm = await showConfirmDialog(
      context,
      L.p(
        'Delete ${selected.length} book${selected.length > 1 ? "s" : ""}',
        'حذف ${enToArNum(selected.length)} كتاب${selected.length > 1 ? "ًا" : ""}',
      ),
      message: L.p(
        'Delete selected books?\nThis action cannot be undone.',
        'حذف الكتب المحددة؟\nلا يمكن التراجع عن هذا الإجراء.',
      ),
      confirmText: L.p('Delete Selected', 'حذف المحدد'),
      destructive: true,
      useLClass: true,
    );

    if (confirm != true) return;

    VoidCallback? stopSpinner;
    if (context.mounted) {
      stopSpinner = showSpinningDialog(
        context,
        L.p('Deleting...', 'جارٍ الحذف...'),
        textDir: L.dir,
      );
    }

    int deleted = 0;
    int failed = 0;
    final d = _ReaderInputPageData.booksDir!.path;

    try {
      for (final b in selected) {
        final file = File(path.join(d, '${b.hash}.txt'));
        try {
          if (await file.exists()) {
            await file.delete();
          }
          _ReaderInputPageData.books.removeWhere((bb) => bb.hash == b.hash);
          ReaderPageSettings.delete(b.hash);
          deleted++;
        } catch (_) {
          failed++;
        }
      }

      if (mounted) {
        setState(() {
          _stopSelectionMode();
        });
      }
      await _saveBookEntriesFile();
    } finally {
      stopSpinner?.call();
    }

    if (context.mounted) {
      showSnackL(
        context,
        en: failed > 0
            ? 'Deleted: $deleted, Failed: $failed'
            : 'Deleted: $deleted',
        ar: failed > 0
            ? 'تم الحذف: ${enToArNum(deleted)}، فشل: ${enToArNum(failed)}'
            : 'تم الحذف: ${enToArNum(deleted)}',
      );
    }
  }

  Future<void> _deleteAllBooks(BuildContext context) async {
    if (_ReaderInputPageData.books.isEmpty) return;

    final confirm = await showConfirmDialog(
      context,
      L.p('Delete All', 'حذف الكل'),
      message: L.p(
        'Delete all books?\nThis action cannot be undone.',
        'حذف جميع الكتب؟\nلا يمكن التراجع عن هذا الإجراء.',
      ),
      confirmText: L.p('Delete All', 'حذف الكل'),
      destructive: true,
      useLClass: true,
    );

    if (confirm != true) return;

    VoidCallback? stopSpinner;
    if (context.mounted) {
      stopSpinner = showSpinningDialog(
        context,
        L.p('Deleting...', 'جارٍ الحذف...'),
      );
    }

    int deleted = 0;
    int failed = 0;
    final d = _ReaderInputPageData.booksDir!.path;
    final books = List<BookEntry>.from(_ReaderInputPageData.books);

    try {
      for (final b in books) {
        final file = File(path.join(d, '${b.hash}.txt'));
        try {
          if (await file.exists()) {
            await file.delete();
          }
          ReaderPageSettings.delete(b.hash);
          deleted++;
        } catch (_) {
          failed++;
        }
      }

      _ReaderInputPageData.books.clear();
      if (mounted) {
        setState(() {
          _stopSelectionMode();
        });
      }
      await _saveBookEntriesFile();
    } finally {
      stopSpinner?.call();
    }

    if (context.mounted) {
      showSnackL(
        context,
        en: failed > 0
            ? 'Deleted: $deleted, Failed: $failed'
            : 'Deleted: $deleted',
        ar: failed > 0
            ? 'تم الحذف: ${enToArNum(deleted)}، فشل: ${enToArNum(failed)}'
            : 'تم الحذف: ${enToArNum(deleted)}',
      );
    }
  }

  Future<void> _exportBooks(BuildContext context) async {
    if (!_ReaderInputPageData.isInited || _ReaderInputPageData.books.isEmpty) {
      if (context.mounted) {
        showSnackL(
          context,
          en: 'No books to export',
          ar: 'لا توجد كتب للتصدير',
        );
      }
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      L.p('Export', 'تصدير'),
      message: L.p(
        'The entered books will be saved as a zip file. You can import them later. '
            'After exporting, make sure it was saved properly.\n\n'
            'Do you want to export?',
        /* ar */ 'سيتم حفظ الكتب المدخلة كملف مضغوط.'
            /* ar */ 'يمكنك استيرادها لاحقًا. بعد التصدير، تأكد من أنه حُفظ بشكل صحيح.\n\n'
            /* ar */ 'هل تريد التصدير؟',
      ),
      confirmText: L.p('Export', 'تصدير'),
      constraints: true,
      useLClass: true,
    );

    if (confirmed != true) return;

    VoidCallback? stopSpinner;
    if (context.mounted) {
      stopSpinner = showSpinningDialog(
        context,
        L.p('Exporting...', 'جارٍ التصدير...'),
      );
    }

    final d = _ReaderInputPageData.booksDir!.path;
    const fileName = 'Arabic_Lexicons_books.zip';
    final zipFileOut = path.join(
      (await getTemporaryDirectory()).path,
      fileName,
    );

    final List<String> names = [_ReaderInputPageData.booksIndexName];
    final List<String> sourcefiles = [
      path.join(d, _ReaderInputPageData.booksIndexName),
    ];

    for (final b in _ReaderInputPageData.books) {
      final name = '${b.hash}.txt';
      names.add(name);
      sourcefiles.add(path.join(d, name));
    }

    List<int> zippedData;
    try {
      (_, zippedData) = await zipFiles(names, sourcefiles, zipFileOut);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$e');
      }

      stopSpinner?.call();
      if (context.mounted) {
        showSnackL(
          context,
          en: 'Could not zip',
          ar: 'تعذر إنشاء الملف المضغوط',
        );
      }
      return;
    }

    stopSpinner?.call();
    if (context.mounted) {
      showBackupOptionsButtomSheet(
        context,
        fileName: fileName,
        title: L.p('Export Ready', 'جاهز للتصدير'),
        saveDialogTitle: L.p('Save books', 'حفظ الكتب'),
        useLclass: true,
        filePaht: zipFileOut,
        fileData: zippedData,
        allowedExt: ['zip'],
      );
    }
  }

  Future<void> _importBooks(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      L.p('Import', 'استيراد'),
      message: L.p(
        'If the book in the backup already exists, then it is skipped.\n\n'
            'Do you want to import?',
        'إذا كان الكتاب الموجود في النسخة الاحتياطية موجودًا مسبقًا، فسيتم تخطيه.\n\n'
            'هل تريد الاستيراد؟',
      ),
      confirmText: L.p('Select File', 'اختيار ملف'),
      constraints: true,
      useLClass: true,
    );

    if (confirmed != true) return;

    VoidCallback? stopSpinner;
    if (context.mounted) {
      stopSpinner = showSpinningDialog(
        context,
        L.p('Importing...', 'جارٍ الاستيراد...'),
      );
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        return;
      }

      final archiveData = ZipDecoder().decodeBytes(result.files.single.bytes!);

      final idxFile = archiveData.files
          .where((a) => a.name == _ReaderInputPageData.booksIndexName)
          .firstOrNull;

      if (idxFile == null) {
        throw Exception('Corrupted file');
      }

      final bytes = idxFile.readBytes();
      if (bytes == null) {
        throw Exception('Corrupted file');
      }

      final books = _ReaderInputPageData.parseBooks(
        LineSplitter.split(utf8.decode(bytes, allowMalformed: true)),
      );

      int added = 0;
      int skipped = 0;
      final d = _ReaderInputPageData.booksDir!.path;

      for (final b in books) {
        final exists = _ReaderInputPageData.books.indexWhere(
          (bb) => b.hash == bb.hash,
        );
        if (exists > -1) {
          skipped++;
          continue;
        }

        final fileEntry = archiveData.files
            .where((a) => a.name == '${b.hash}.txt')
            .firstOrNull;

        if (fileEntry == null) {
          skipped++;
          continue;
        }

        final fileBytes = fileEntry.readBytes();
        if (fileBytes == null) {
          skipped++;
          continue;
        }

        final outFile = File(path.join(d, '${b.hash}.txt'));

        try {
          await outFile.writeAsString(
            utf8.decode(fileBytes, allowMalformed: true),
            flush: true,
          );
          _ReaderInputPageData.books.add(b);
          added++;
        } catch (_) {
          skipped++;
        }
      }

      await _saveBookEntriesFile();

      if (context.mounted) {
        showSnackL(
          context,
          en: 'Added: $added Skipped: $skipped',
          ar: 'تمت الإضافة: ${enToArNum(added)}، تم التخطي: ${enToArNum(skipped)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('while reading zip: $e');
      }
      if (context.mounted) {
        showSnackL(context, en: 'Import failed', ar: 'فشل الاستيراد');
      }
    } finally {
      stopSpinner?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final th = theme.textTheme;
    final cs = theme.colorScheme;

    return PopScope(
      canPop: !isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (isSelecting) {
          setState(() {
            _stopSelectionMode();
          });
          return;
        }

        Navigator.pop(context);
      },
      child: Scaffold(
        drawer: buildDrawer(context),
        body: GestureStack(
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(
                context,
              ).textTheme.apply(fontFamily: L.arFontIf),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Directionality(
                textDirection: L.dir,
                child: CustomScrollView(
                  slivers: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SliverAppBar(
                        floating: true,
                        snap: true,
                        pinned: false,
                        title: Text(
                          L.p('Reader Input', 'مدخل القارئ'),
                          style: L.arStyleIf,
                        ),
                        actions: [
                          if (isSelecting) ...[
                            IconButton(
                              tooltip: L.p('Select all', 'تحديد الكل'),
                              icon: const Icon(Icons.checklist),
                              onPressed: () => setState(() {
                                for (final b
                                    in _ReaderInputPageData.booksUnord) {
                                  b.selected = true;
                                }
                              }),
                            ),
                            IconButton(
                              tooltip: L.p('Clear Selection', 'إلغاء التحديد'),
                              icon: const Icon(Icons.clear_all),
                              onPressed: () => setState(() {
                                _stopSelectionMode();
                              }),
                            ),
                          ],
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {
                              switch (value) {
                                case 'delete_selected':
                                  await _deleteSelectedBooks(context);
                                  break;
                                case 'delete_all':
                                  await _deleteAllBooks(context);
                                  break;
                                case 'export':
                                  await _exportBooks(context);
                                  break;
                                case 'import':
                                  await _importBooks(context);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'export',
                                child: Row(
                                  children: [
                                    const Icon(Icons.upload_file),
                                    const SizedBox(width: 10),
                                    Text(L.p('Export', 'تصدير')),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'import',
                                child: Row(
                                  children: [
                                    const Icon(Icons.download),
                                    const SizedBox(width: 10),
                                    Text(L.p('Import', 'استيراد')),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete_all',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_sweep),
                                    const SizedBox(width: 10),
                                    Text(L.p('Delete All', 'حذف الكل')),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete_selected',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete),
                                    const SizedBox(width: 10),
                                    Text(L.p('Delete Selected', 'حذف المحدد')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: scrollPaddingW(top: 16, bottom: 16),
                      sliver: SliverToBoxAdapter(
                        child: Card(
                          elevation: 0,
                          color: cs.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: _controller,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.start,
                                  maxLines: 4,
                                  style: L.arStyle,
                                  decoration: InputDecoration(
                                    hintText: L.p(
                                      'Paste text here…',
                                      'الصق النص هنا…',
                                    ),
                                    hintTextDirection: L.dir,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
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
                                        avatar: const Icon(
                                          Icons.save,
                                          size: 18,
                                        ),
                                        label: Text(L.p('Save', 'حفظ')),
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
                                        label: Text(L.p('Qasidah', 'قصيدة')),
                                        selected: _isQasidahMode,
                                        onSelected: (v) =>
                                            setState(() => _isQasidahMode = v),
                                      ),
                                      FilterChip(
                                        showCheckmark: false,
                                        avatar: const Icon(
                                          Icons.push_pin,
                                          size: 18,
                                        ),
                                        label: Text(L.p('Pin', 'تثبيت')),
                                        selected: !_isTempMode & _isPinned,
                                        onSelected: _isTempMode
                                            ? null
                                            : (v) =>
                                                  setState(() => _isPinned = v),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final txt = await getClipboardText();
                                        if (txt != null) {
                                          _controller.text =
                                              _controller.text + txt;
                                        }
                                      },
                                      icon: const Icon(Icons.paste),
                                      label: Text(L.p('Paste', 'لصق')),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        if (_controller.text.isEmpty) return;

                                        final res = await showConfirmDialog(
                                          context,
                                          L.p(
                                            'Clear all text?',
                                            'مسح كل النص؟',
                                          ),
                                          confirmText: L.p('Clear', 'مسح'),
                                          useLClass: true,
                                        );
                                        if (res == true) _controller.clear();
                                      },
                                      icon: const Icon(Icons.clear),
                                      label: Text(L.p('Clear', 'مسح')),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: 160,
                                  height: 52,
                                  child: FilledButton.icon(
                                    label: Text(
                                      L.p('Go', 'ابدأ'),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    icon: const Icon(Icons.start),
                                    onPressed: () => _showText(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_ReaderInputPageData.books.isNotEmpty) ...[
                      SliverPadding(
                        padding: scrollPadding.copyWith(top: 10, bottom: 8),
                        sliver: SliverToBoxAdapter(
                          child: Directionality(
                            textDirection: L.dir,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  L.p(
                                    'Books [${_ReaderInputPageData.books.length}]',
                                    'الكتب [${enToArNum(_ReaderInputPageData.books.length)}]',
                                  ),
                                  style: th.titleLarge?.arIf?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                FilterChip(
                                  labelStyle: L.arStyleIf,
                                  avatar: const Icon(Icons.swap_vert, size: 18),
                                  label: Text(
                                    _isShowEntrieNewToOld
                                        ? L.p(
                                            'New to Old',
                                            'من الجديد إلى القديم',
                                          )
                                        : L.p(
                                            'Old to New',
                                            'من القديم إلى الجديد',
                                          ),
                                  ),
                                  selected: false,
                                  showCheckmark: false,
                                  onSelected: (_) {
                                    setState(() {
                                      _isShowEntrieNewToOld =
                                          !_isShowEntrieNewToOld;
                                    });
                                    _ReaderInputPageData.setBookUnord(
                                      match: _searchText,
                                      newToOld: _isShowEntrieNewToOld,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: SliverPadding(
                          padding: scrollPaddingW(top: 0, bottom: 12),
                          sliver: SliverToBoxAdapter(
                            child: TextField(
                              controller: _searchController,
                              style: L.arStyle,
                              onChanged: (input) {
                                setState(() {});
                                final s = ArabicNormalizer.cleanLineForSearch(
                                  input,
                                );
                                if (s == _searchText) return;

                                _searchText = s;
                                _ReaderInputPageData.setBookUnord(
                                  match: s,
                                  newToOld: _isShowEntrieNewToOld,
                                );
                              },
                              decoration: InputDecoration(
                                suffixIcon: _searchController.text.isEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.help),
                                        onPressed: () {
                                          showCleanLineForSearchInfo(context);
                                        },
                                      )
                                    : IconButton(
                                        tooltip: L.p(
                                          'Clear search',
                                          'مسح البحث',
                                        ),
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
                                hintText: L.p(
                                  'Search for a book…',
                                  'ابحث عن كتاب…',
                                ),
                                hintTextDirection: L.dir,
                              ),
                              textAlign: TextAlign.start,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: SliverPadding(
                          padding: scrollPaddingW(bottom: 30, top: 0),
                          sliver: _ReaderInputPageData.booksUnord.isEmpty
                              ? SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 24.0),
                                    child: Column(
                                      spacing: 4,
                                      children: [
                                        Text(
                                          L.p(
                                            'No matches for',
                                            /* ar */ 'لا توجد نتائج لـ',
                                          ),
                                          textDirection: L.dir,
                                          style: L.arStyleIf,
                                        ),
                                        Text(
                                          '"$_searchText"',
                                          textDirection: TextDirection.rtl,
                                          softWrap: true,
                                          style: L.arStyle,
                                        ),
                                      ],
                                      // textDirection: L.dir,
                                    ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final en = _ReaderInputPageData
                                          .booksUnord[index];
                                      final bg = cs.surfaceContainer;
                                      final style = th.titleMedium!.ar;

                                      Widget txt;
                                      if (_searchText.isEmpty) {
                                        txt = Text(
                                          en.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                          style: style,
                                        );
                                      } else {
                                        final (:pre, :suf) = en.nameCl
                                            .splitOnce(_searchText);

                                        txt = Text.rich(
                                          TextSpan(
                                            children: [
                                              if (pre != null)
                                                TextSpan(text: pre),
                                              TextSpan(
                                                text: _searchText,
                                                style: TextStyle(
                                                  color: cs.error,
                                                  // fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (suf != null)
                                                TextSpan(text: suf),
                                            ],
                                            style: style,
                                          ),
                                        );
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Material(
                                          color: bg,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            side: BorderSide(
                                              color: cs.outlineVariant,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                            title: txt,
                                            trailing: isSelecting
                                                ? Checkbox(
                                                    value: en.selected,
                                                    onChanged: (v) =>
                                                        setState(() {
                                                          en.selected =
                                                              v ?? false;
                                                        }),
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        tooltip: en.pinned
                                                            ? L.p(
                                                                'Unpin',
                                                                'إلغاء التثبيت',
                                                              )
                                                            : L.p(
                                                                'Pin',
                                                                'تثبيت',
                                                              ),
                                                        icon: Icon(
                                                          en.pinned
                                                              ? Icons.push_pin
                                                              : Icons
                                                                    .push_pin_outlined,
                                                        ),
                                                        style: IconButton.styleFrom(
                                                          backgroundColor:
                                                              en.pinned
                                                              ? cs.inversePrimary
                                                                    .withAlpha(
                                                                      80,
                                                                    )
                                                              : null,
                                                          foregroundColor:
                                                              en.pinned
                                                              ? cs.primary
                                                              : null,
                                                        ),
                                                        onPressed: () async {
                                                          if (en.pinned) {
                                                            final confirm = await showConfirmDialog(
                                                              context,
                                                              L.p(
                                                                'Unpin a book',
                                                                'إلغاء تثبيت كتاب',
                                                              ),
                                                              message: L.p(
                                                                'Unpin: ${en.name}',
                                                                'إلغاء التثبيت: ${en.name}',
                                                              ),
                                                              confirmText: L.p(
                                                                'Unpin',
                                                                'إلغاء التثبيت',
                                                              ),
                                                              destructive: true,
                                                              useLClass: true,
                                                              constraints:
                                                                  en
                                                                      .name
                                                                      .length >
                                                                  50,
                                                            );
                                                            if (confirm !=
                                                                true) {
                                                              return;
                                                            }
                                                          }

                                                          final pinned =
                                                              await _tglPinBookEntries(
                                                                en.hash,
                                                              );
                                                          if (context.mounted) {
                                                            final p = pinned
                                                                ? L.p(
                                                                    'Pinned',
                                                                    'تم التثبيت',
                                                                  )
                                                                : L.p(
                                                                    'Unpinned',
                                                                    'تم إلغاء التثبيت',
                                                                  );
                                                            showSnack(
                                                              context,
                                                              '$p: ${en.name}',
                                                              textStyle:
                                                                  L.arStyleIf,
                                                              textDir: L.dir,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        tooltip: L.p(
                                                          'Delete book',
                                                          'حذف الكتاب',
                                                        ),
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                        ),
                                                        onPressed: () async {
                                                          final confirm =
                                                              await showConfirmDialog(
                                                                context,
                                                                L.p(
                                                                  'Delete a book',
                                                                  'حذف كتاب',
                                                                ),
                                                                message: L.p(
                                                                  'Delete: ${en.name}',
                                                                  'حذف: ${en.name}',
                                                                ),
                                                                confirmText: L
                                                                    .p(
                                                                      'Delete',
                                                                      'حذف',
                                                                    ),
                                                                destructive:
                                                                    true,
                                                                constraints:
                                                                    en
                                                                        .name
                                                                        .length >
                                                                    50,
                                                                useLClass: true,
                                                              );
                                                          if (confirm != true) {
                                                            return;
                                                          }

                                                          await _deleteFile(en);
                                                          if (context.mounted) {
                                                            showSnackL(
                                                              context,
                                                              en: 'Deleted: ${en.name}',
                                                              ar: 'تم الحذف: ${en.name}',
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                            onTap: () {
                                              if (isSelecting) {
                                                setState(() {
                                                  en.selected = !en.selected;
                                                });
                                                return;
                                              }
                                              _openBook(context, en);
                                            },
                                            onLongPress: () {
                                              setState(() {
                                                if (isSelecting) {
                                                  _stopSelectionMode();
                                                  return;
                                                }

                                                _clearAllSelections();
                                                isSelecting = true;
                                                en.selected = true;
                                              });
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    childCount:
                                        _ReaderInputPageData.booksUnord.length,
                                  ),
                                ),
                        ),
                      ),
                      // const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
}
