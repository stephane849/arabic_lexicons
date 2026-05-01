import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/pages/settings.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        constraints: BoxConstraints(maxWidth: 300),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

VoidCallback showSpinningDialog(
  BuildContext context,
  String msg, {
  TextDirection? textDir,
}) {
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
              Text(msg, textDirection: textDir),
            ],
          ),
        ),
      ),
    ),
  );
  return () => Navigator.pop(context);
}

void showSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
  TextDirection? textDir,
}) {
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..clearSnackBars() // removes any currently showing snackbar
    ..showSnackBar(
      SnackBar(
        content: Text(message, textDirection: textDir),
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
