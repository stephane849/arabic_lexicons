import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/pages/data.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:ara_dict/theme.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';

EdgeInsets readerPadding(
  BuildContext context, {
  required double maxWidth,
  required double sidePadd,
}) {
  final padd = maxWidth < 0
      ? sidePadd
      : ((MediaQuery.of(context).size.width - maxWidth) / 2).clamp(
          sidePadd,
          double.infinity,
        );

  return EdgeInsets.fromLTRB(
    padd,
    scrollPadding.top,
    padd,
    scrollPadding.bottom,
  );
}

class ReaderAdjustData {
  double padding;
  double maxWidth;
  double fontSize;
  String fontFam;

  ReaderAdjustData({
    required this.fontFam,
    required this.fontSize,
    required this.padding,
    required this.maxWidth,
  });

  static ReaderAdjustData fromConf(AppSettingsController c) {
    return ReaderAdjustData(
      padding: c.padding,
      maxWidth: c.maxWidth,
      fontFam: c.readerFont,
      fontSize: c.readerFontSize,
    );
  }

  static ReaderAdjustData fromReaderPageSettings(ReaderPageSettings s) {
    return ReaderAdjustData(
      padding: s.padding,
      maxWidth: s.maxWidth,
      fontFam: s.fontFam,
      fontSize: s.fontSize,
    );
  }

  bool isEq(ReaderAdjustData b) {
    return padding == b.padding &&
        maxWidth == b.maxWidth &&
        fontFam == b.fontFam &&
        fontSize == b.fontSize;
  }

  ReaderAdjustData copyWith({
    double? padding,
    double? maxWidth,
    double? fontSize,
    String? fontFam,
  }) {
    return ReaderAdjustData(
      padding: padding ?? this.padding,
      maxWidth: maxWidth ?? this.maxWidth,
      fontFam: fontFam ?? this.fontFam,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

const double minReaderFontSize = 14;
const double maxReaderFontSize = 30;

class ReaderAdjustPage extends StatefulWidget {
  final ReaderAdjustData data;

  const ReaderAdjustPage({super.key, required this.data});

  static Future<ReaderAdjustData?> open(
    BuildContext context, {
    required ReaderAdjustData data,
  }) async {
    return Navigator.push<ReaderAdjustData?>(
      context,
      MaterialPageRoute(builder: (_) => ReaderAdjustPage(data: data)),
    );
  }

  @override
  State<ReaderAdjustPage> createState() => _ReaderAdjustPageState();
}

class _ReaderAdjustPageState extends State<ReaderAdjustPage> {
  late ReaderAdjustData _data;

  int _currentTab = 0;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data.copyWith();
  }

  bool get _hasChanges => !widget.data.isEq(_data);

  void _save() {
    Navigator.of(context).pop(_data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final th = theme.textTheme;

    final previewStyle = appConf
        .readerTS(context)
        .copyWith(fontFamily: _data.fontFam, fontSize: _data.fontSize);

    final titleStyle = th.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust reader'),
        centerTitle: false,
        actions: [
          FilledButton.icon(
            onPressed: _hasChanges ? _save : null,
            label: const Text('Save'),
            icon: Icon(Icons.save),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() {
          if (_currentTab == i && !_hidden) {
            _hidden = true;
            return;
          }
          _hidden = false;
          _currentTab = i;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.text_fields),
            label: 'Font size',
          ),
          NavigationDestination(icon: Icon(Icons.font_download), label: 'Font'),
          NavigationDestination(icon: Icon(Icons.space_bar), label: 'Padding'),
          NavigationDestination(icon: Icon(Icons.width_full), label: 'Width'),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsetsGeometry.only(bottom: 12),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          'Preview',
                          style: th.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: readerPadding(
                      context,
                      maxWidth: _data.maxWidth,
                      sidePadd: _data.padding,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        story,
                        style: previewStyle,
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_hidden)
              Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: switch (_currentTab) {
                      0 => _Changer(
                        key: const ValueKey('fontSize'),
                        title: 'Font size',
                        subTitle: 'Make the text smaller or larger.',
                        current: _data.fontSize,
                        minV: minReaderFontSize,
                        maxV: maxReaderFontSize,
                        def: defaultReaderArabicFontSize,
                        step: 1,
                        setVal: (v) => setState(() => _data.fontSize = v),
                      ),
                      1 => _FontPicker(
                        key: const ValueKey('font'),
                        fonts: arabicFonts,
                        selectedFont: _data.fontFam,
                        titleStyle: titleStyle,
                        onSelect: (font) =>
                            setState(() => _data.fontFam = font),
                      ),
                      2 => _Changer(
                        key: const ValueKey('padding'),
                        title: 'Padding',
                        subTitle: 'Change the side padding around the text.',
                        current: _data.padding,
                        minV: 0,
                        maxV: 50,
                        def: ReaderPageSettings.paddingDef,
                        step: 5,
                        setVal: (v) => setState(() => _data.padding = v),
                      ),
                      3 => _Changer(
                        key: const ValueKey('width'),
                        title: 'Width',
                        subTitle:
                            'Limit the readable line width on large screens.',
                        current: _data.maxWidth,
                        minV: 400,
                        maxV: 1200,
                        def: ReaderPageSettings.maxWidthDef,
                        step: 20,
                        setVal: (v) => setState(() => _data.maxWidth = v),
                        touggleDisable: () {
                          setState(() {
                            if (_data.maxWidth > 0) {
                              _data.maxWidth = -1;
                            } else {
                              _data.maxWidth = ReaderPageSettings.maxWidthDef;
                            }
                          });
                        },
                        disabled: _data.maxWidth < 0,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FontPicker extends StatelessWidget {
  final List<String> fonts;
  final String selectedFont;
  final TextStyle? titleStyle;
  final ValueChanged<String> onSelect;

  const _FontPicker({
    super.key,
    required this.fonts,
    required this.selectedFont,
    required this.titleStyle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Font family', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Pick a font for the reader.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...separatedList(
              items: fonts,
              separatorBuilder: (_) => const SizedBox(height: 10),
              itemBuilder: (font, _) {
                final isSelected = font == selectedFont;

                return Material(
                  color: isSelected ? cs.primaryContainer : cs.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSelected ? cs.primary : cs.outlineVariant,
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    title: Text(
                      font,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isSelected
                          ? titleStyle?.copyWith(color: cs.onPrimaryContainer)
                          : titleStyle,
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : null,
                    onTap: () => onSelect(font),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Changer extends StatelessWidget {
  final String title;
  final String subTitle;
  final double current;
  final double minV;
  final double maxV;
  final double def;
  final int step;
  final void Function(double w) setVal;
  final VoidCallback? touggleDisable;
  final bool disabled;

  const _Changer({
    super.key,
    required this.title,
    required this.subTitle,
    required this.current,
    required this.minV,
    required this.maxV,
    required this.def,
    required this.step,
    required this.setVal,
    this.touggleDisable,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final divs = ((maxV - minV) / step).round();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final th = theme.textTheme;

    final subTitleStyle = th.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: th.titleMedium),
            if (subTitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subTitle, style: subTitleStyle),
            ],
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    disabled ? "--" : '${current.round()}px',
                    style: th.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: disabled || current <= minV
                            ? null
                            : () => setVal(current - step.toDouble()),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.restore),
                        onPressed: disabled || current == def
                            ? null
                            : () => setVal(def),
                      ),
                      if (touggleDisable != null)
                        IconButton.filledTonal(
                          icon: Icon(Icons.cancel),
                          onPressed: touggleDisable,
                        ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: disabled || current >= maxV
                            ? null
                            : () => setVal(current + step.toDouble()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${minV.toInt()}px', style: subTitleStyle),
                  Text('${maxV.toInt()}px', style: subTitleStyle),
                ],
              ),
            ),
            Slider(
              value: disabled ? def : current,
              min: minV,
              max: maxV,
              divisions: divs,
              onChanged: disabled ? null : setVal,
            ),
          ],
        ),
      ),
    );
  }
}
