import 'dart:async';
import 'dart:math';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/pages/settings.dart';
import 'package:ara_dict/reader/font_pikcer.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:flutter/material.dart';

class ReaderModeSettingsSheet extends StatefulWidget {
  final ReaderPageSettings original;

  const ReaderModeSettingsSheet({super.key, required this.original});

  static Future<ReaderPageSettings?> show(
    BuildContext context, {
    required ReaderPageSettings settings,
  }) {
    return showModalBottomSheet<ReaderPageSettings?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: 600),
      builder: (_) {
        return ReaderModeSettingsSheet(original: settings);
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
    final botPadd = MediaQuery.of(context).padding.bottom;
    // final cs = Theme.of(context).colorScheme;
    // final bottomInset = MediaQuery.of(context).padding.bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: scrollPadding.copyWith(bottom: 8),
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
                      SwitchListTile(
                        title: const Text('Line numbers'),
                        subtitle: const Text('Show poem line numbers'),
                        secondary: const FilledIcon(Icons.list),
                        value: rs.qasidahLineNum,
                        onChanged: (v) => setState(() => rs.qasidahLineNum = v),
                      ),
                      SwitchListTile(
                        title: const Text('Center bayt'),
                        subtitle: const Text('Align poem to the center'),
                        secondary: const FilledIcon(Icons.format_align_center),
                        value: rs.isQasidahCentered,
                        onChanged: (v) =>
                            setState(() => rs.isQasidahCentered = v),
                      ),
                    ] else ...[
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
                      title: Text('Font: ${rs.fontFam}'),
                      subtitle: const Text('For the current page'),
                      leading: const FilledIcon(Icons.font_download),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final nf = await showFontPickerSheet(
                          context,
                          currentFont: rs.fontFam,
                        );
                        if (nf != null) {
                          setState(() => rs.fontFam = nf);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Font Size: ${rs.fontSize.toInt()}'),
                      subtitle: const Text('Text size for current page'),
                      leading: const FilledIcon(Icons.text_fields),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final newFontSize = await showFontSizeBottomSheet(
                          context,
                          fontSize: rs.fontSize,
                          fontFam: rs.fontFam,
                        );
                        if (newFontSize != null) {
                          setState(() {
                            rs.fontSize = newFontSize;
                          });
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Remove tashkil'),
                      subtitle: const Text('Remove all Arabic harakat'),
                      secondary: const FilledIcon(Icons.do_not_disturb),
                      value: rs.isRmTashkil,
                      onChanged: (v) => setState(() => rs.isRmTashkil = v),
                    ),
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
          padding: EdgeInsets.fromLTRB(16, 8, 16, max(4 + botPadd, 8)),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasChanged
                  ? () => Navigator.of(context).pop(rs)
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Apply to current book'),
            ),
          ),
        ),
      ],
    );
  }
}
