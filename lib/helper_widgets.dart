import 'dart:io';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

void showBackupOptionsButtomSheet(
  BuildContext context, {
  required String title,
  required String saveDialogTitle,
  required String fileName,
  IconData fileIcon = Icons.insert_drive_file_rounded,
  required String filePaht,
  required List<int> fileData,
  required List<String> allowedExt,
  Future<void> Function()? afterSave,
  String shareTxt = "Share",
  String saveToDeviceTxt = "Save to device",
}) {
  final afterSaveCallback =
      afterSave ??
      () async => await showInfoDialog(
        context,
        "Warning!",
        message:
            "Make sure the file was written properly. "
            "Check the file size to confirm it is not empty.",
        confirmText: 'Okay',
      );

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(maxWidth: 600),
    builder: (_) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      Widget tile({
        required IconData icon,
        required String text,
        required VoidCallback onTap,
      }) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: Row(
                children: [
                  Icon(icon, color: cs.primary),
                  const SizedBox(width: 16),
                  Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
                  Icon(Icons.chevron_right, color: cs.outline),
                ],
              ),
            ),
          ),
        );
      }

      return SingleChildScrollView(
        padding: scrollPaddingBottmSheet(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              // width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                // border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(fileIcon, color: cs.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      fileName,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions group
            tile(
              icon: Icons.save_alt,
              text: saveToDeviceTxt,
              onTap: () async {
                final outputFile = await FilePicker.saveFile(
                  dialogTitle: saveDialogTitle,
                  fileName: fileName,
                  type: FileType.custom,
                  bytes: Uint8List.fromList(fileData),
                  allowedExtensions: allowedExt,
                );

                if (context.mounted) Navigator.pop(context);

                if (context.mounted && outputFile != null) {
                  await afterSaveCallback();
                  if (context.mounted) {
                    showSnack(context, 'Saved to: $outputFile');
                  }
                }
              },
            ),

            if (!Platform.isLinux) ...[
              const SizedBox(height: 12),
              tile(
                icon: Icons.share,
                text: shareTxt,
                onTap: () async {
                  Navigator.pop(context);
                  await SharePlus.instance.share(
                    ShareParams(files: [XFile(filePaht)], text: 'Export Books'),
                  );
                },
              ),
            ],

            const SizedBox(height: 12),

            tile(
              icon: Icons.close,
              text: "Cancel",
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );
}
