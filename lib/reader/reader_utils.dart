import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/pages/settings.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

const int _maxAppbarTitleLen = 40;

String readerAppbarTitle(List<List<WordEntry>> paras, bool tashkil) {
  String t;
  if (tashkil) {
    t = paras.first.map((w) => w.nTk).join(" ");
  } else {
    t = paras.first.map((w) => w.ar).join(" ");
  }
  return t.length > _maxAppbarTitleLen ? t.substring(0, _maxAppbarTitleLen) : t;
}

List<List<WordEntry>> cleanReaderInputAndPrepare(String text) {
  text = text.trim();
  if (text.isEmpty) return [];

  List<List<WordEntry>> res = [];
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

Future<ReaderPageSettings?> showReaderModeSettings(
  BuildContext context,
  final ReaderPageSettings ogRs,
  final List<List<WordEntry>> peras,
) {
  final rs = ogRs.copyWith();

  return showModalBottomSheet<ReaderPageSettings?>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      bool isCopiedMsgShowing = false;
      bool isCoping = false;

      return Material(
        color: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            // final sh = MediaQuery.of(context).size.height;
            final rsChanged = ogRs.isEqual(rs);

            return Padding(
              padding: EdgeInsets.symmetric(
                // horizontal: 8,
                vertical: 12,
              ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SettingsSectionHeader(title: 'Behavior'),
                          Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SwitchListTile(
                                  title: const Text('Qasidah mode'),
                                  subtitle: const Text('Poem mode'),
                                  secondary: const FilledIcon(Icons.notes),
                                  value: rs.isQasidah,
                                  onChanged: (v) {
                                    rs.isQasidah = v;
                                    setState(() {});
                                  },
                                ),
                                if (rs.isQasidah) ...[
                                  const Divider(height: 0),
                                  SwitchListTile(
                                    title: const Text('Qasidah Line Number'),
                                    subtitle: const Text(
                                      'Show poem line numbers',
                                    ),
                                    secondary: const FilledIcon(Icons.list),
                                    value: rs.qasidahLineNum,
                                    onChanged: (v) {
                                      rs.qasidahLineNum = v;
                                      setState(() {});
                                    },
                                  ),
                                  const Divider(height: 0),
                                  SwitchListTile(
                                    title: const Text('Center Bayt'),
                                    subtitle: const Text(
                                      'Align poem to the center',
                                    ),
                                    secondary: const FilledIcon(
                                      Icons.format_align_center,
                                    ),
                                    value: rs.isQasidahCentered,
                                    onChanged: (v) {
                                      setState(() {
                                        rs.isQasidahCentered = v;
                                      });
                                    },
                                  ),
                                ] else ...[
                                  const Divider(height: 0),
                                  SwitchListTile(
                                    title: const Text('Right-aligned text'),
                                    subtitle: const Text(
                                      'Align text towards right',
                                    ),
                                    secondary: const FilledIcon(
                                      Icons.format_align_right,
                                    ),
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
                                  title: const Text('Remove Tashkil'),
                                  subtitle: const Text(
                                    'Remove all arabic harakat',
                                  ),
                                  secondary: const FilledIcon(
                                    Icons.do_not_disturb,
                                  ),
                                  value: rs.isRmTashkil,
                                  onChanged: (v) {
                                    setState(() {
                                      rs.isRmTashkil = v;
                                    });
                                  },
                                ),
                                const Divider(height: 0),
                                SwitchListTile(
                                  title: const Text('Skip Bookmark popup'),
                                  subtitle: const Text(
                                    'Use lexicon page bookmark option instead',
                                  ),
                                  secondary: const FilledIcon(Icons.directions),
                                  value: appSettingsNotifier
                                      .readerIsOpenLexiconDirecly,
                                  onChanged: (v) async {
                                    await appSettingsNotifier
                                        .saveReaderIsOpenLexiconDirecly(v);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SettingsSectionHeader(title: 'APPEARANCE'),
                          Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text('Font Family: ${rs.fontFam}'),
                                  subtitle: const Text('For the current page'),
                                  leading: const FilledIcon(
                                    Icons.font_download,
                                  ),
                                  trailing: const Icon(Icons.arrow_right),
                                  onTap: () async {
                                    final nf = await showFontPicker(
                                      context,
                                      currentFont: rs.fontFam,
                                    );
                                    if (nf != null) {
                                      rs.fontFam = nf;
                                      setState(() {});
                                    }
                                  },
                                ),
                                const Divider(height: 0),
                                ListTile(
                                  title: Text(
                                    'Font Size'
                                    ' ${appSettingsNotifier.fontSize.toInt()}',
                                  ),
                                  subtitle: const Text(
                                    'Adjust the Arabic text size',
                                  ),
                                  leading: const FilledIcon(Icons.text_fields),
                                  trailing: const Icon(Icons.arrow_right),
                                  onTap: () async {
                                    await showFontSizeBottomSheet(
                                      context,
                                      fontFam: rs.fontFam,
                                    );
                                  },
                                ),
                                const Divider(height: 0),
                                SwitchListTile(
                                  title: const Text('Colored Bookmarks'),
                                  subtitle: const Text(
                                    'Color the bookmarked words',
                                  ),
                                  secondary: const FilledIcon(Icons.bookmark),
                                  value: rs.isBmColored,
                                  onChanged: (v) async {
                                    rs.isBmColored = v;
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SettingsSectionHeader(title: 'Extra'),
                          Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  title: isCopiedMsgShowing
                                      ? const Text('Text Copied')
                                      : isCoping
                                      ? const Text('Text Copying')
                                      : const Text('Copy Text'),
                                  subtitle: const Text(
                                    'Copy the original text',
                                  ),
                                  leading: const FilledIcon(Icons.copy_all),
                                  trailing: const Icon(Icons.arrow_right),
                                  onTap: () async {
                                    if (isCoping) return;
                                    setState(() => isCoping = true);
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text: peras
                                            .map(
                                              (p) =>
                                                  p.map((w) => w.ar).join(" "),
                                            )
                                            .join("\n"),
                                      ),
                                    );

                                    isCopiedMsgShowing = true;
                                    setState(() {});
                                    Timer(Duration(seconds: 1), () {
                                      isCopiedMsgShowing = false;
                                      isCoping = false;
                                      setState(() {});
                                    });
                                  },
                                ),
                                // const Divider(height: 0),
                                // ListTile(
                                //   title: const Text('Exit reader'),
                                //   subtitle: const Text('Go to reader input page'),
                                //   leading: const FilledIcon(
                                //     Icons.exit_to_app_outlined,
                                //   ),
                                //   trailing: const Icon(Icons.arrow_right),
                                //   onTap: () async =>
                                //       await exitReaderPage(context),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop((rs));
                        },
                        label: rsChanged
                            ? const Text('Done')
                            : const Text('Apply'),
                        icon: const Icon(Icons.check),
                      ),
                    ),
                  ),
                  // const SizedBox(height: 30),
                ],
              ),
            );
          },
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

VoidCallback showSpinningDialog(
  BuildContext context,
  String msg,
)  {
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

void showBackupOptions(BuildContext context, String name, File zipFile) {
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
            const Text(
              "Backup ZipFile Ready",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text("Save to device"),
              onTap: () async {
                String? outputFile = await FilePicker.saveFile(
                  dialogTitle: 'Export Books',
                  fileName: name,
                  type: FileType.custom,
                  bytes: await zipFile.readAsBytes(),
                  allowedExtensions: ['zip'],
                );
                if (context.mounted) Navigator.pop(context);
                if (context.mounted && outputFile != null) {
                  showSnack(context, 'Saved to: $outputFile');
                }
              },
            ),

            Divider(),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text("Share"),
              onTap: () async {
                Navigator.pop(context);
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(zipFile.path)],
                    text: 'Export Books',
                  ),
                );
              },
            ),

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

Future<File> zipFiles(
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

  return zipFile;
}
