import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Widget buildBookmarkMenu(
  BuildContext context,
  void Function() stateChanged,
  List<String> Function() getSelectedWords,
) {
  void msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    onSelected: (value) async {
      switch (value) {
        case 'close':
          break;

        case 'share_all':
          if (BookMarks.words.isEmpty) {
            msg('No bookmarked words');
            return;
          }
          await shareBookmarks(BookMarks.words);
          stateChanged();
          break;

        case 'share_selected':
          final words = getSelectedWords();
          if (words.isEmpty) {
            msg('No words Selected');
            return;
          }
          await shareBookmarks(words);
          stateChanged();
          break;

        case 'share_all_anki':
          if (BookMarks.words.isEmpty) {
            msg('No bookmarked words');
            return;
          }
          await shareBookmarksToAnki(BookMarks.words);
          stateChanged();
          break;

        case 'share_selected_anki':
          final words = getSelectedWords();
          if (words.isEmpty) {
            msg('No words Selected');
            return;
          }
          await shareBookmarksToAnki(words);
          stateChanged();
          break;

        case 'delete_selected':
          final words = getSelectedWords();
          if (words.isEmpty) {
            msg('No words Selected');
            return;
          }

          final count = words.length;
          final res = await showConfirmDialog(
            context,
            'Delete Selected ($count) Bookmark${count > 1 ? "s" : ""}',
            message:
                'Are you sure you want to delete selected bookmarked words?\nThis action cannot be undone.',
          );

          if (res ?? false) {
            final rmCount = await BookMarks.rmList(words);
            msg('Deleted $rmCount word${rmCount > 1 ? "s" : ""}');
            stateChanged();
          }
          break;

        case 'delete_all':
          final res = await showConfirmDialog(
            context,
            'Delete All Bookmarks',
            message:
                'Are you sure you want to delete all bookmarked words?\nThis action cannot be undone.',
          );

          if (res ?? false) {
            final rmCount = await BookMarks.rmAll();
            msg('Deleted $rmCount word${rmCount > 1 ? "s" : ""}');
            stateChanged();
          }
          break;

        case 'export':
          try {
            Uint8List fileBytes = Uint8List.fromList(
              utf8.encode(BookMarks.list.join("\n")),
            );

            String? outputFile = await FilePicker.platform.saveFile(
              dialogTitle: 'Export Bookmarks',
              fileName: bookMarkFileName,
              type: FileType.custom,
              bytes: fileBytes,
              allowedExtensions: ['txt'],
            );

            if (outputFile != null) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Saved')));

              showInfoDialog(
                context,
                "Warning!",
                message:
                    "Make sure the file was written properly. After saving, check the file size to confirm it is not empty.",
                confirmText: 'Okay',
              );
            } else {
              throw "Filepicker canceled";
            }
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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
          );
          if (confirmed != true) return;
          try {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.any,
              withData: true,
            );
            if (result == null || result.files.single.bytes == null) {
              return;
            }

            final content = utf8.decode(result.files.single.bytes!);
            final res = <String>[];

            for (var w in LineSplitter.split(content)) {
              w = ArabicNormalizer.keepOnlyAr(w);
              if (w.isEmpty) continue;
              res.add(w);
            }

            final addedCount = await BookMarks.addAll(res);
            stateChanged();

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Added $addedCount word${addedCount > 1 ? "s" : ""} to bookmark',
                ),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
            if (kDebugMode) debugPrint('Import failed: $e');
          }
          break;
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'share_all',
        child: Row(
          children: [Icon(Icons.share), SizedBox(width: 10), Text('Share All')],
        ),
      ),
      const PopupMenuItem(
        value: 'share_selected',
        child: Row(
          children: [
            Icon(Icons.outbox),
            SizedBox(width: 10),
            Text('Share Selected'),
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
        value: 'export',
        child: Row(
          children: [
            Icon(Icons.upload_file),
            SizedBox(width: 10),
            Text('Export File'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'import',
        child: Row(
          children: [
            Icon(Icons.download),
            SizedBox(width: 10),
            Text('Import File'),
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
            Icon(Icons.delete_outline),
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

Future<void> shareBookmarksToAnki(Iterable<String> words) async {
  if (words.isEmpty) return;

  const header = '#separator:Tab\n#html:false\n#notetype:Basic\n';
  final content = words.join('\n');

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/arabic_lexicons_anki_import.txt');
  await file.writeAsBytes(utf8.encode('$header$content'));

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: 'Import into Anki'),
  );
}
