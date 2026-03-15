import 'dart:async';
import 'dart:convert';
import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/pages/settings.dart';
import 'package:ara_dict/reader/reader.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final cs = Theme.of(context).colorScheme;
  final rs = ogRs.copyWith();

  return showModalBottomSheet<ReaderPageSettings?>(
    context: context,
    backgroundColor: cs.surface,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      bool isCopiedMsgShowing = false;
      bool isCoping = false;

      return StatefulBuilder(
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
                        const SettingsSectionHeader(title: 'Reader'),
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
                                  setState(() {
                                    rs.isQasidah = v;
                                  });
                                },
                              ),
                              const Divider(height: 0),
                              SwitchListTile(
                                title: const Text('Qasidah Line Number'),
                                subtitle: const Text('Show poem line numbers'),
                                secondary: const FilledIcon(Icons.list),
                                value: rs.qasidahLineNum,
                                onChanged: rs.isQasidah
                                    ? (v) {
                                        setState(() {
                                          rs.qasidahLineNum = v;
                                        });
                                      }
                                    : null,
                              ),

                              const Divider(height: 0),
                              SwitchListTile(
                                title: const Text('Right-aligned text'),
                                subtitle: const Text(
                                  'Align text towards right',
                                ),
                                secondary: const FilledIcon(
                                  Icons.format_align_right,
                                ),
                                value:
                                    rs.textAlign == TextAlign.right ||
                                    rs.isQasidah,
                                onChanged: rs.isQasidah
                                    ? null
                                    : (v) {
                                        setState(() {
                                          rs.textAlign = v
                                              ? TextAlign.right
                                              : TextAlign.justify;
                                        });
                                      },
                              ),
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
                                onTap: () {
                                  showFontSizeBottomSheet(context);
                                },
                              ),
                              const Divider(height: 0),
                              SwitchListTile(
                                title: const Text('Open Lexicon Direcly'),
                                subtitle: const Text(
                                  // 'Do not show popup of bookmakrs, bookmark it in the lexicon page',
                                  'Skip bookmark popup. Use lexicon page bookmark option instead',
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
                                    : const Text('Copy Text'),
                                subtitle: const Text('Copy the original text'),
                                leading: const FilledIcon(Icons.copy_all),
                                trailing: const Icon(Icons.arrow_right),
                                onTap: () async {
                                  if (isCoping) return;
                                  isCoping = true;
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: peras
                                          .map(
                                            (p) => p.map((w) => w.ar).join(" "),
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
                              const Divider(height: 0),
                              ListTile(
                                title: const Text('Exit reader'),
                                subtitle: const Text('Go to reader input page'),
                                leading: const FilledIcon(
                                  Icons.exit_to_app_outlined,
                                ),
                                trailing: const Icon(Icons.arrow_right),
                                onTap: () async =>
                                    await exitReaderPage(context),
                              ),
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
                        Navigator.of(sheetContext).pop((rs));
                      },
                      label: rsChanged
                          ? const Text('Close')
                          : const Text('Save'),
                      icon: rsChanged
                          ? const Icon(Icons.cancel_outlined)
                          : const Icon(Icons.save_outlined),
                      iconAlignment: IconAlignment.end,
                    ),
                  ),
                ),
                // const SizedBox(height: 30),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showSelectableParagraph(
  BuildContext mainContext,
  String Function() fullTextFunc,
  ReaderPageSettings rs,
  TextStyle textStyleBodyMedium,
) async {
  final cs = Theme.of(mainContext).colorScheme;
  final fullText = fullTextFunc();

  await showModalBottomSheet(
    context: mainContext,
    backgroundColor: cs.surface,
    isScrollControlled: true,
    enableDrag: false,
    // isDismissible: false, // prevents tap outside close
    useSafeArea: true,
    builder: (context) {
      final sh = MediaQuery.sizeOf(context).height;
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: sh * 0.4, maxHeight: sh * 0.9),
        child: Directionality(
          textDirection: TextDirection.rtl,
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
                    horizontal: 32,
                  ).copyWith(left: 16),
                  child: Row(
                    spacing: 6,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        /* txt */ 'حدد النص',
                        style: textStyleBodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(flex: 2),
                      IconButton(
                        tooltip: 'Copy All',
                        icon: const Icon(Icons.copy_all),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: fullText),
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
                        fullText,
                        textAlign: rs.textAlign,
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
}
