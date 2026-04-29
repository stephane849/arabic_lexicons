import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/pages/settings.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

const int _maxAppbarTitleLen = 40;

String readerAppbarTitle(PeraEntries paras, bool tashkil) {
  String t;
  if (tashkil) {
    t = paras.first.map((w) => w.nTk).join(" ");
  } else {
    t = paras.first.map((w) => w.ar).join(" ");
  }
  return t.length > _maxAppbarTitleLen ? t.substring(0, _maxAppbarTitleLen) : t;
}

class ReaderSelectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final IconData trailing;
  final FilledIconVariant variant;

  const ReaderSelectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.trailing = Icons.chevron_right,
    this.variant = FilledIconVariant.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FilledIcon(icon, variant: variant),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(trailing),
      onTap: () => Navigator.pop(context, value),
    );
  }
}

PeraEntries cleanReaderInputAndPrepare(String text) {
  text = text.trim();
  if (text.isEmpty) return [];

  PeraEntries res = [];
  for (var l in LineSplitter.split(text)) {
    l = l.trim();
    if (l.isEmpty) continue;
    List<WordEntry> curr = [];
    for (var w in l.split(RegExp(r'\s'))) {
      curr.add(
        WordEntry(
          ar: w,
          cl: ArabicNormalizer.keepOnlyAr(w),
          nTk: ArabicNormalizer.rmTashkil(w),
        ),
      );
    }
    if (curr.isNotEmpty) res.add(curr);
  }
  return res;
}

Future<void> showWordReadeActionsDialog(
  BuildContext context,
  String word,
  bool isBookmarked,
  VoidCallback onBookmark,
  VoidCallback onShowDefinition,
  TextStyle ts,
) {
  return showDialog(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: ts.fontFamily,
                  ),
                ),

                const SizedBox(height: 24),

                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        label: Text(
                          isBookmarked ? "Remove Bookmark" : "Add to Bookmark",
                        ),
                        style: isBookmarked
                            ? FilledButton.styleFrom(
                                backgroundColor: cs.error,
                                foregroundColor: cs.onError,
                              )
                            : null,
                        onPressed: () {
                          Navigator.pop(context);
                          onBookmark();
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.menu_book),
                        label: const Text("Show Definition"),
                        onPressed: () {
                          Navigator.pop(context);
                          onShowDefinition();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showSelectableParagraph(
  BuildContext mainContext,
  String Function() fullTextFunc,
  TextAlign textAlign,
  TextDirection dir,
  TextStyle textStyleBodyMedium, {
  String Function()? fullTextFuncSecondary,
}) async {
  final cs = Theme.of(mainContext).colorScheme;
  final fullText = fullTextFunc();
  final String? fullText2 = fullTextFuncSecondary == null
      ? null
      : fullTextFuncSecondary();
  bool showing2 = false;

  await showModalBottomSheet(
    context: mainContext,
    backgroundColor: cs.surface,
    isScrollControlled: true,
    enableDrag: false,
    // isDismissible: false, // prevents tap outside close
    useSafeArea: true,
    builder: (context) {
      final sh = MediaQuery.sizeOf(context).height;
      bool copyBtnClicked = false;
      bool copiedJust = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: sh * 0.4,
              maxHeight: sh * 0.9,
            ),
            child: Directionality(
              textDirection: dir,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 24,
                      ),
                      child: Row(
                        spacing: 1,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            /* txt */ 'حدد النص',
                            style: textStyleBodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(flex: 2),
                          if (fullText2 != null)
                            IconButton(
                              tooltip: 'Show secondary text',
                              icon: Icon(
                                Icons.insert_page_break_sharp,
                                color: showing2 ? cs.error : null,
                              ),
                              onPressed: () {
                                showing2 = !showing2;
                                setState(() {});
                              },
                            ),
                          IconButton(
                            tooltip: 'Copy All',
                            icon: copiedJust
                                ? const Icon(Icons.check)
                                : const Icon(Icons.copy_all),
                            onPressed: () async {
                              if (copyBtnClicked) return;
                              copyBtnClicked = true;

                              await Clipboard.setData(
                                ClipboardData(text: fullText),
                              );

                              copiedJust = true;
                              setState(() {});

                              await Future.delayed(
                                Duration(milliseconds: 800),
                                () {
                                  copyBtnClicked = false;
                                  copiedJust = false;
                                  setState(() {});
                                },
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ).copyWith(bottom: 128),
                        child: SelectionArea(
                          magnifierConfiguration:
                              TextMagnifierConfiguration.disabled,
                          contextMenuBuilder: (context, selectableRegionState) {
                            return AdaptiveTextSelectionToolbar.buttonItems(
                              anchors: selectableRegionState.contextMenuAnchors,
                              buttonItems:
                                  selectableRegionState.contextMenuButtonItems,
                            );
                          },
                          child: Text(
                            showing2
                                ? fullText2 ?? '---- NO secondary text ----'
                                : fullText,
                            textAlign: textAlign,
                            style: textStyleBodyMedium.copyWith(
                              height: 2.0,
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<String?> showFontPicker(BuildContext context, {String? currentFont}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      String? selected = currentFont;
      final cs = Theme.of(context).colorScheme;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400, // ✅ limit width
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text(
                      'Select Font',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Font list
                    Flexible(
                      child: Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: arabicFonts.length,
                          separatorBuilder: (_, _) => const Divider(height: 0),
                          itemBuilder: (context, index) {
                            final font = arabicFonts[index];
                            final isSelected = font == selected;
                            final radiousC = Radius.circular(10);
                            final rd = index == 0
                                ? BorderRadius.only(
                                    topLeft: radiousC,
                                    topRight: radiousC,
                                  )
                                : index == arabicFonts.length - 1
                                ? BorderRadius.only(
                                    bottomLeft: radiousC,
                                    bottomRight: radiousC,
                                  )
                                : null;
                            return InkWell(
                              borderRadius: rd,
                              onTap: () {
                                setState(() => selected = font);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: rd,
                                  color: isSelected
                                      ? cs.inversePrimary.withAlpha(30)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        spacing: 4,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            font,
                                            style: TextStyle(
                                              // fontFamily: font,
                                              // fontSize: 16,
                                              // fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            /* txt */ 'السلام عليكم ورحمة الله',
                                            textDirection: TextDirection.rtl,
                                            // textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: font,
                                              fontSize: 18,
                                              color: cs.secondary,
                                              // color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: selected == null
                              ? null
                              : () => Navigator.pop(context, selected),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

VoidCallback showSpinningDialog(BuildContext context, String msg) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(msg),
            ],
          ),
        ),
      ),
    ),
  );
  return () => Navigator.pop(context);
}

void showBackupOptions(
  BuildContext context, {
  required String title,
  required String saveDialogTitle,
  required String fileName,
  required String filePaht,
  required List<int> fileData,
  required List<String> allowedExt,
  Future<void> Function()? afterSave,
  String shareTxt = "Share",
  String saveToDeviceTxt = "Save to device",
}) {
  afterSave =
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
    useSafeArea: true,
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      final cs = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withAlpha(70),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.save_alt),
              title: Text(saveToDeviceTxt),
              onTap: () async {
                String? outputFile = await FilePicker.saveFile(
                  dialogTitle: saveDialogTitle,
                  fileName: fileName,
                  type: FileType.custom,
                  bytes: Uint8List.fromList(fileData),
                  allowedExtensions: allowedExt,
                );
                if (context.mounted) Navigator.pop(context);
                if (context.mounted && outputFile != null) {
                  await afterSave?.call();
                  if (context.mounted) {
                    showSnack(context, 'Saved to: $outputFile');
                  }
                }
              },
            ),

            if (!Platform.isLinux) ...[
              Divider(),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(shareTxt),
                onTap: () async {
                  Navigator.pop(context);
                  await SharePlus.instance.share(
                    ShareParams(files: [XFile(filePaht)], text: 'Export Books'),
                  );
                },
              ),
            ],

            Divider(),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("Cancel"),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

void showSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..clearSnackBars() // removes any currently showing snackbar
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

Future<(File, List<int>)> zipFiles(
  List<String> names,
  List<String> sourceFiles,
  String outputZipPath,
) async {
  final archive = Archive();

  for (int i = 0; i < sourceFiles.length; i++) {
    final file = File(sourceFiles[i]);

    final bytes = await file.readAsBytes();

    final archiveFile = ArchiveFile(
      names[i], // name inside zip
      bytes.length,
      bytes,
    );

    archive.addFile(archiveFile);
  }

  final zipData = ZipEncoder().encode(archive);

  final zipFile = File(outputZipPath);
  await zipFile.writeAsBytes(zipData);

  return (zipFile, zipData);
}

Future<int?> showPerasOnePerLine_(
  BuildContext context,
  final ReaderPageSettings rs,
  final PeraEntries peras,
) {
  final chapters = peras.indexed
      .where(
        (entry) =>
            entry.$2.length == 1 &&
            ArabicNormalizer.arabicDigits.hasMatch(entry.$2.first.ar),
      )
      .toList();

  return showModalBottomSheet<int?>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      final arFont = appSettingsNotifier
          .getArabicTextStyle(context)
          .copyWith(fontFamily: rs.fontFam);

      return StatefulBuilder(
        builder: (context, setState) {
          return Material(
            color: cs.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // horizontal: 8,
                vertical: 12,
              ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // drag handle
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withAlpha(70),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text('Chapters'),
                    Flexible(
                      child: ListView.separated(
                        // itemCount: peras.length,
                        itemCount: chapters.length,
                        separatorBuilder: (_, _) => Divider(height: 0),
                        padding: scrollPadding,
                        itemBuilder: (context, index) {
                          // String line = peras[index].map((e) => e.ar).join(" ");

                          // if (line.length > ) line = line.substring(0, 50);
                          return Ink(
                            child: InkWell(
                              onTap: () {
                                // Navigator.of(context).pop(index);
                                Navigator.of(context).pop(chapters[index].$1);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 6.0,
                                ),
                                child: Text(
                                  'الباب ${chapters[index].$2.first.ar}',
                                  overflow: TextOverflow.ellipsis,
                                  style: arFont,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class ReaderModeSettingsSheet extends StatefulWidget {
  final ReaderPageSettings original;
  final PeraEntries peras;

  const ReaderModeSettingsSheet({
    super.key,
    required this.original,
    required this.peras,
  });

  static Future<ReaderPageSettings?> show(
    BuildContext context, {
    required ReaderPageSettings settings,
    required PeraEntries peras,
  }) {
    return showModalBottomSheet<ReaderPageSettings?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: 600),
      builder: (_) {
        return ReaderModeSettingsSheet(original: settings, peras: peras);
      },
    );
  }

  @override
  State<ReaderModeSettingsSheet> createState() =>
      _ReaderModeSettingsSheetState();
}

class _ReaderModeSettingsSheetState extends State<ReaderModeSettingsSheet> {
  late ReaderPageSettings rs;

  @override
  void initState() {
    super.initState();
    rs = widget.original.copyWith();
  }

  bool get hasChanged => !widget.original.isEqual(rs);

  @override
  Widget build(BuildContext context) {
    // final cs = Theme.of(context).colorScheme;
    // final bottomInset = MediaQuery.of(context).padding.bottom;

    // color: cs.surfaceContainerLow,
    // surfaceTintColor: cs.surfaceTint,
    // shape: const RoundedRectangleBorder(
    //   borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    // ),
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsSectionTitle(title: 'Behavior'),
                SettingsSectionSurface(
                  children: [
                    SwitchListTile(
                      title: const Text('Qasidah mode'),
                      subtitle: const Text('Poem layout'),
                      secondary: const FilledIcon(Icons.notes),
                      value: rs.isQasidah,
                      onChanged: (v) => setState(() => rs.isQasidah = v),
                    ),
                    if (rs.isQasidah) ...[
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Line numbers'),
                        subtitle: const Text('Show poem line numbers'),
                        secondary: const FilledIcon(Icons.list),
                        value: rs.qasidahLineNum,
                        onChanged: (v) => setState(() => rs.qasidahLineNum = v),
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Center bayt'),
                        subtitle: const Text('Align poem to the center'),
                        secondary: const FilledIcon(Icons.format_align_center),
                        value: rs.isQasidahCentered,
                        onChanged: (v) =>
                            setState(() => rs.isQasidahCentered = v),
                      ),
                    ] else ...[
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Right-aligned text'),
                        subtitle: const Text('Align text towards right'),
                        secondary: const FilledIcon(Icons.format_align_right),
                        value: rs.textAlign == TextAlign.right,
                        onChanged: (v) {
                          setState(() {
                            rs.textAlign = v
                                ? TextAlign.right
                                : TextAlign.justify;
                          });
                        },
                      ),
                    ],
                    const Divider(height: 0),
                    SwitchListTile(
                      title: const Text('Skip bookmark popup'),
                      subtitle: const Text(
                        'Use lexicon page bookmark option instead',
                      ),
                      secondary: const FilledIcon(Icons.directions),
                      value: appSettingsNotifier.readerIsOpenLexiconDirecly,
                      onChanged: (v) async {
                        await appSettingsNotifier
                            .saveReaderIsOpenLexiconDirecly(v);
                        if (mounted) setState(() {});
                      },
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      title: const Text('Resume reading'),
                      subtitle: const Text(
                        'Open from your last read paragraph',
                      ),
                      secondary: const FilledIcon(Icons.history),
                      value: rs.saveLastPeraIdx && rs.bookHash.isNotEmpty,
                      onChanged: rs.bookHash.isNotEmpty
                          ? (v) => setState(() => rs.saveLastPeraIdx = v)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsSectionTitle(title: 'Appearance'),
                SettingsSectionSurface(
                  children: [
                    ListTile(
                      title: Text('Font family: ${rs.fontFam}'),
                      subtitle: const Text('For the current page'),
                      leading: const FilledIcon(Icons.font_download),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final nf = await showFontPicker(
                          context,
                          currentFont: rs.fontFam,
                        );
                        if (nf != null) {
                          setState(() => rs.fontFam = nf);
                        }
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      title: Text(
                        'Font size ${appSettingsNotifier.fontSize.toInt()}',
                      ),
                      subtitle: const Text('Adjust the Arabic text size'),
                      leading: const FilledIcon(Icons.text_fields),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showFontSizeBottomSheet(context, fontFam: rs.fontFam);
                        });
                      },
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      title: const Text('Remove tashkil'),
                      subtitle: const Text('Remove all Arabic harakat'),
                      secondary: const FilledIcon(Icons.do_not_disturb),
                      value: rs.isRmTashkil,
                      onChanged: (v) => setState(() => rs.isRmTashkil = v),
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      title: const Text('Colored bookmarks'),
                      subtitle: const Text('Color the bookmarked words'),
                      secondary: const FilledIcon(Icons.bookmark),
                      value: rs.isBmColored,
                      onChanged: (v) => setState(() => rs.isBmColored = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(rs),
              icon: const Icon(Icons.check),
              label: Text(hasChanged ? 'Apply' : 'Done'),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget settingsSectionTitle(BuildContext context, String title) {
//   final textTheme = Theme.of(context).textTheme;
//   final cs = Theme.of(context).colorScheme;

//   return Padding(
//     padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
//     child: Text(
//       title.toUpperCase(),
//       style: textTheme.labelLarge?.copyWith(
//         color: cs.onSurfaceVariant,
//         letterSpacing: 1.1,
//         fontWeight: FontWeight.w700,
//       ),
//     ),
//   );
// }

// /// tile
// Widget settingsSectionSurface(
//   BuildContext context, {
//   required List<Widget> children,
// }) {
//   final cs = Theme.of(context).colorScheme;

//   return Material(
//     color: cs.surfaceContainer,
//     surfaceTintColor: cs.surfaceTint,
//     elevation: 0,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(20),
//       side: BorderSide(color: cs.outlineVariant, width: 1),
//     ),
//     clipBehavior: Clip.antiAlias,
//     child: Column(mainAxisSize: MainAxisSize.min, children: children),
//   );
// }
