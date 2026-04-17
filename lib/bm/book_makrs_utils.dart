import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Widget buildBookmarkMenu(
  BuildContext context,
  void Function() stateChanged,
  List<String> Function() getSelectedWords,
) {
  Iterable<String>? getWords(bool all) {
    if (all) {
      if (BookMarks.isEmpty) {
        showSnack(context, 'No bookmarked words');
        return null;
      }
      return BookMarks.words;
    } else {
      final words = getSelectedWords();
      if (words.isEmpty) {
        showSnack(context, 'No words Selected. Long press to select.');
        return null;
      }
      return words;
    }
  }

  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    onSelected: (value) async {
      switch (value) {
        case 'share_all_anki':
        case 'share_selected_anki':
          final words = getWords(value == 'share_all_anki');
          if (words == null || words.isEmpty) return;

          final stopSpinner = showSpinningDialog(context, 'Sharing...');
          final (filePath, fileBytes) = await makeAnki(BookMarks.words);
          stopSpinner();

          if (!context.mounted) return;
          showBackupOptions(
            context,
            title: 'Import into Anki',
            saveDialogTitle: 'Save anki notes',
            filePaht: filePath,
            fileName: ankiExportFileName,
            fileData: fileBytes,
            allowedExt: ['txt'],
            shareTxt: 'Share with anki',
          );

          stateChanged();
          break;

        case 'delete_selected':
          final words = getSelectedWords();
          if (words.isEmpty) {
            if (context.mounted) {
              showSnack(context, 'No words Selected. Long press to select.');
            }
            return;
          }

          final count = words.length;

          final confrim = await showConfirmDialog(
            context,
            'Delete $count bookmared word${count > 1 ? "s" : ""}',
            message:
                'Are you sure you want to delete selected bookmarked words?'
                '\nThis action cannot be undone.',
            confirmText: 'Delete Selected',
          );

          if (confrim != true) return;

          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Deleting...');
          }
          final rmCount = await BookMarks.rmList(words);

          stopSpinner?.call();

          if (context.mounted) {
            showSnack(
              context,
              'Deleted $rmCount word${rmCount > 1 ? "s" : ""}',
            );
          }
          stateChanged();

          break;

        case 'delete_all':
          if (BookMarks.isEmpty) return;
          final confrim = await showConfirmDialog(
            context,
            'Delete All Bookmarks',
            message:
                'Are you sure you want to delete all bookmarked words?'
                '\nThis action cannot be undone.',
            confirmText: 'Delete All',
          );

          if (confrim != true) return;
          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Deleting...');
          }

          final rmCount = await BookMarks.rmAll();

          stopSpinner?.call();
          if (context.mounted) {
            showSnack(
              context,
              'Deleted $rmCount word${rmCount > 1 ? "s" : ""}',
            );
          }
          stateChanged();
          break;

        case 'export':
        case 'export_selected':
          Iterable<String> words;
          if (value == 'export') {
            if (BookMarks.isEmpty) {
              showSnack(context, 'No bookmarked words');
              return;
            }
            words = BookMarks.words;
          } else {
            words = getSelectedWords();
            if (words.isEmpty) {
              showSnack(context, 'No words Selected. Long press to select.');
              return;
            }
          }

          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Exporting...');
          }
          try {
            Uint8List fileBytes = utf8.encode(words.join("\n"));
            final tmp = await getTemporaryDirectory();
            final filePath = join(tmp.path, bookMarkFileName);
            File(filePath).writeAsBytes(fileBytes);

            stopSpinner?.call();

            if (!context.mounted) return;
            showBackupOptions(
              context,
              title: 'Export Ready',
              saveDialogTitle: 'Export Bookmarks',
              filePaht: filePath,
              fileName: bookMarkFileName,
              fileData: fileBytes,
              allowedExt: ['txt'],
            );
          } catch (e) {
            stopSpinner?.call();
            if (kDebugMode) debugPrint('Export err: $e');

            if (context.mounted) {
              showSnack(context, 'Export failed');
            }
          }
          break;

        case 'import':
          final confirmed = await showConfirmDialog(
            context,
            'Import',
            message:
                'If a word in the backup already exists in your bookmarks, '
                'it will be skipped. '
                'Do you want to import?',
            confirmText: 'Select File',
          );
          if (confirmed != true) return;

          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Importing...');
          }

          try {
            FilePickerResult? result = await FilePicker.pickFiles(
              type: FileType.any,
              withData: true,
            );

            if (result == null) {
              stopSpinner?.call();
              return;
            }

            final data = result.files.single.bytes;
            if (data == null) {
              stopSpinner?.call();
              if (context.mounted) {
                showSnack(context, 'Selected file was empty');
              }
              return;
            }

            final content = utf8.decode(data);
            final res = <String>[];

            for (var w in LineSplitter.split(content)) {
              w = ArabicNormalizer.keepOnlyAr(w);
              if (w.isEmpty) continue;
              res.add(w);
            }

            final addedCount = await BookMarks.addAll(res);

            stopSpinner?.call();
            stateChanged();

            if (context.mounted) {
              showSnack(
                context,
                'Added $addedCount word${addedCount > 1 ? "s" : ""} to bookmark',
              );
            }
          } catch (e) {
            stopSpinner?.call();
            if (context.mounted) {
              showSnack(context, 'Import failed');
            }
            if (kDebugMode) debugPrint('Import failed: $e');
          }
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

      // const PopupMenuItem(
      //   value: 'share_all',
      //   child: Row(
      //     children: [Icon(Icons.share), SizedBox(width: 10), Text('Share All')],
      //   ),
      // ),
      const PopupMenuItem(
        value: 'export_selected',
        child: Row(
          children: [
            Icon(Icons.outbox),
            SizedBox(width: 10),
            Text('Export Selected'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'import',
        child: Row(
          children: [
            Icon(Icons.file_download),
            SizedBox(width: 10),
            Text('Import'),
          ],
        ),
      ),

      const PopupMenuDivider(),

      const PopupMenuItem(
        value: 'share_all_anki',
        child: Row(
          children: [
            Icon(Icons.school), // 📚 better for Anki
            SizedBox(width: 10),
            Text('Anki (All)'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'share_selected_anki',
        child: Row(
          children: [
            Icon(Icons.auto_stories), // 📖 distinct from above
            SizedBox(width: 10),
            Text('Anki (Selected)'),
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
  );
}

Future<void> shareBookmarks(Iterable<String> words) async {
  if (words.isEmpty) return;
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/arabic_lexicons_bookmarks.txt');

  final content = words.join('\n'); // one word per line
  await file.writeAsString(content, encoding: utf8);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: 'Bookmakrs txt file'),
  );
}

const ankiExportFileName = 'Arabic_Lexicons_anki_import.txt';

Future<(String, Uint8List)> makeAnki(Iterable<String> words) async {
  const header = '#separator:Tab\n#html:false\n#notetype:Basic\n';
  final content = words.join('\n');

  final dir = await getTemporaryDirectory();
  final file = File(join(dir.path, ankiExportFileName));

  final data = utf8.encode('$header$content');
  await file.writeAsBytes(data);

  return (file.path, data);
}
