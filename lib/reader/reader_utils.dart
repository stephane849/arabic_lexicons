import 'dart:async';
import 'dart:convert';
import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
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
  ReaderPageSettings rs,
  List<List<WordEntry>> peras,
) {
  final cs = Theme.of(context).colorScheme;

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

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 🔥 THIS is the magic
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
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Qasidah mode'),
                          secondary: Icon(Icons.notes),
                          value: rs.isQasidah,
                          onChanged: (v) {
                            setState(() {
                              rs.isQasidah = v;
                            });
                          },
                        ),

                        // const Divider(),
                        SwitchListTile(
                          title: const Text('Right-aligned text'),
                          secondary: Icon(Icons.format_align_right),
                          value:
                              rs.textAlign == TextAlign.right || rs.isQasidah,
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
                        SwitchListTile(
                          title: const Text('Remove Tashkil'),
                          secondary: Icon(Icons.do_not_disturb),
                          value: rs.isRmTashkil,
                          onChanged: (v) {
                            setState(() {
                              rs.isRmTashkil = v;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Open Lexicon Direcly'),
                          secondary: Icon(Icons.directions),
                          value: rs.isOpenLexiconDirecly,
                          onChanged: (v) {
                            setState(() {
                              rs.isOpenLexiconDirecly = v;
                            });
                          },
                        ),
                        ListTile(
                          title: const Text('Change Font Size'),
                          leading: Icon(Icons.text_fields),
                          onTap: () {
                            showFontSizeBottomSheet(context);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          title: isCopiedMsgShowing
                              ? const Text('Text Copied')
                              : const Text('Copy Text'),
                          leading: const Icon(Icons.copy),
                          onTap: () async {
                            if (isCoping) return;
                            isCoping = true;
                            await Clipboard.setData(
                              ClipboardData(
                                text: peras
                                    .map((p) => p.map((w) => w.ar).join(" "))
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
                      ],
                    ),
                  ),
                ),
                // const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop((rs));
                      },
                      label: const Text('Save'),
                      icon: Icon(Icons.save_outlined),
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

void showSelectableParagraph(
  BuildContext mainContext,
  List<WordEntry> pera,
  ReaderPageSettings rs,
  TextStyle textStyleBodyMedium,
) {
  final fullText = pera.map((w) => rs.isRmTashkil ? w.nTk : w.ar).join(' ');
  final cs = Theme.of(mainContext).colorScheme;
  final fn = FocusNode();

  showModalBottomSheet(
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
                textDirection: TextDirection.rtl,
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
                      await Clipboard.setData(ClipboardData(text: fullText));
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
                  focusNode: fn,
                  magnifierConfiguration: TextMagnifierConfiguration.disabled,
                  contextMenuBuilder: (context, selectableRegionState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: selectableRegionState.contextMenuAnchors,
                      buttonItems: selectableRegionState.contextMenuButtonItems,
                    );
                  },
                  child: Text(
                    fullText,
                    textDirection: TextDirection.rtl,
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
      );
    },
  );
}
