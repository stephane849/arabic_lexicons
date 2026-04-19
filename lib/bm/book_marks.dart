import 'dart:io';
import 'dart:isolate';
import 'package:ara_dict/bm/book_makrs_utils.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/utils.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const bookMarkFileName = 'arabic_lexicons_bookMarks.txt';

class BookMarks {
  static const int _maxBookMarkWrodSize = 10;
  static late final File _bookMarkFile;
  static late final File _bookMarkFileTmp;
  static Set<String> _bookMarkedWords = {};

  static Set<String> get words => _bookMarkedWords;

  static bool _loaded = false;

  static Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _bookMarkFile = File(join(dir.path, bookMarkFileName));
      _bookMarkFileTmp = File(
        join(dir.path, 'arabic_lexicons_bookMarks_tmp.txt'),
      );

      if (!await _bookMarkFile.exists()) {
        _loaded = true;
        return;
      }
      final lines = await _bookMarkFile.readAsLines();

      final res = await Isolate.run(() {
        final Set<String> res = {};
        for (var w in lines) {
          w = w.trim();
          if (w.isNotEmpty) res.add(w);
        }
        return res;
      });
      _bookMarkedWords = res;
      _loaded = true;
    } catch (e) {
      debugPrint('Bookmark load failed: $e');
      _loaded = true;
    }
  }

  static bool isSet(String? w) {
    if (!_loaded) return false;
    return _bookMarkedWords.contains(w);
  }

  static bool get isEmpty {
    if (!_loaded) return true;
    return _bookMarkedWords.isEmpty;
  }

  static bool get isNotEmpty {
    if (!_loaded) return false;
    return _bookMarkedWords.isNotEmpty;
  }

  static int get length {
    if (!_loaded) return 0;
    return _bookMarkedWords.length;
  }

  static Set<String> get list {
    if (!_loaded) return {};
    return _bookMarkedWords;
  }

  /// word must be cleaned
  static Future<bool> add(String w) async {
    if (!_loaded) return false;
    if (w.isEmpty || w.length > _maxBookMarkWrodSize) return false;
    if (!_bookMarkedWords.add(w)) return true;

    if (!await _saveToFile()) {
      _bookMarkedWords.remove(w);
      return false;
    }
    return true;
  }

  /// word list must be cleaned
  static Future<int> addAll(List<String> wl) async {
    if (!_loaded) return 0;
    List<String> addedWords = [];
    for (final w in wl) {
      if (w.isEmpty || w.length > _maxBookMarkWrodSize) continue;
      if (_bookMarkedWords.add(w)) {
        addedWords.add(w);
      }
    }

    if (addedWords.isEmpty) return 0;

    if (!await _saveToFile()) {
      for (final w in addedWords) {
        _bookMarkedWords.remove(w);
      }
      return 0;
    }

    return addedWords.length;
  }

  static Future<bool> rm(String w) async {
    if (!_loaded) return false;
    if (w.isEmpty) return false;
    if (!_bookMarkedWords.remove(w)) return true;
    if (!await _saveToFile()) {
      _bookMarkedWords.add(w);
      return false;
    }

    return true;
  }

  static Future<int> rmList(List<String> wordsToDel) async {
    if (!_loaded) return 0;
    if (_bookMarkedWords.isEmpty) return 0;

    final removedWords = _bookMarkedWords.toList();

    int rmCount = 0;
    for (final w in wordsToDel) {
      if (_bookMarkedWords.remove(w)) rmCount++;
    }

    if (!await _saveToFile()) {
      _bookMarkedWords.addAll(removedWords);
      return 0;
    }

    return rmCount;
  }

  static Future<int> rmAll() async {
    if (!_loaded) return 0;
    if (_bookMarkedWords.isEmpty) return 0;

    final removedWords = _bookMarkedWords.toList();
    _bookMarkedWords.clear();

    if (!await _saveToFile()) {
      for (final w in removedWords) {
        _bookMarkedWords.add(w);
      }
      return 0;
    }

    return removedWords.length;
  }

  /// if could not save then remove form memory also
  static Future<bool> _saveToFile() async {
    if (!_loaded) return false;
    if (_bookMarkedWords.isEmpty) {
      try {
        if (await _bookMarkFile.exists()) await _bookMarkFile.delete();
      } catch (_) {
        return false;
      }
      return true;
    }

    final txt = _bookMarkedWords.join("\n");

    try {
      await _bookMarkFileTmp.writeAsString(txt);
    } catch (e) {
      return false;
    }

    try {
      await _bookMarkFileTmp.rename(_bookMarkFile.path);
    } catch (e) {
      return false;
    }
    return true;
  }
}

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

    showStatusBar();
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
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final oddDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withAlpha(30),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'BM${BookMarks.isEmpty ? "" : "s (${BookMarks.length.toString()})"}',
        ),

        actions: [
          if (_isSelecting) ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select all',
              onPressed: () => setState(() {
                _selectedWords.fillRange(0, _selectedWords.length, true);
              }),
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Deselect all',
              onPressed: () => setState(() {
                _isSelecting = false;
              }),
            ),
          ],
          buildBookmarkMenu(
            context,
            () => setState(() {
              _isSelecting = false;
              if (_selectedWords.length != BookMarks.length) {
                _selectedWords = List.filled(BookMarks.length, false);
              } else {
                _selectedWords.fillRange(0, BookMarks.length, false);
              }
            }),
            _selectedWordsList,
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: SafeArea(
        child: BookMarks.isEmpty
            ? Center(child: Text('Bookmark some words'))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16).copyWith(bottom: 120),
                itemCount: BookMarks.length,
                itemBuilder: (context, index) {
                  if (_isShowNewToOld) {
                    index = BookMarks.length - 1 - index;
                  }
                  final word = BookMarks.list.elementAt(index);
                  return Ink(
                    decoration: index.isOdd ? null : oddDecoration,
                    child: InkWell(
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
                            return;
                          }
                          if (_selectedWords.length == BookMarks.length) {
                            _selectedWords.fillRange(
                              0,
                              _selectedWords.length,
                              false,
                            );
                          } else {
                            _selectedWords = List.filled(
                              BookMarks.length,
                              false,
                            );
                          }
                          _isSelecting = true;
                          _selectedWords[index] = true;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            if (_isSelecting)
                              Checkbox(
                                value: _selectedWords[index],
                                onChanged: (v) {
                                  setState(() {
                                    _selectedWords[index] = v ?? false;
                                  });
                                },
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final res = await showConfirmDialog(
                                    context,
                                    'Delete Word',
                                    message:
                                        'Are you sure you want to delete "$word"?',
                                  );
                                  if (res ?? false) {
                                    BookMarks.rm(word);
                                  }
                                },
                              ),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                word,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: arabicFontStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),

      floatingActionButton: AnimatedSlide(
        duration: Duration(milliseconds: 300),
        offset: _isFabVisable ? Offset.zero : Offset(0, 2),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: _isFabVisable ? 1.0 : 0.0,
          child: FloatingActionButton.small(
            child: const Icon(Icons.swap_vert),
            onPressed: () {
              _isShowNewToOld = !_isShowNewToOld;
              setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
