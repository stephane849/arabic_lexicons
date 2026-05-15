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
}) => EdgeInsets.symmetric(
  horizontal: ((MediaQuery.of(context).size.width - maxWidth) / 2).clamp(
    sidePadd,
    double.infinity,
  ),
  vertical: scrollPadding.top,
).copyWith(bottom: scrollPadding.bottom);

class SetMaxWidthOrPadd extends StatefulWidget {
  const SetMaxWidthOrPadd({super.key});

  static Future<void> open(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SetMaxWidthOrPadd()),
    );
  }

  @override
  State<SetMaxWidthOrPadd> createState() => _SetMaxWidthOrPaddState();
}

const double minReaderFontSize = 14;
const double maxReaderFontSize = 30;

class _SetMaxWidthOrPaddState extends State<SetMaxWidthOrPadd> {
  double _padding = appConf.padding;
  double _maxWidth = appConf.maxWidth;
  double _fontSize = appConf.readerFontSize;
  String _fontFam = appConf.readerFont;

  int _curent = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final th = theme.textTheme;
    final style = appConf
        .readerTS(context)
        .copyWith(fontFamily: _fontFam, fontSize: _fontSize);

    final titleStyle = th.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    // final subTitleStyle = th.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: Text('Adjust')),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cs.primaryContainer,
        selectedItemColor: cs.onPrimaryContainer,
        unselectedItemColor: cs.onPrimaryContainer.withValues(alpha: 0.7),

        currentIndex: _curent,
        onTap: (i) => setState(() {
          _curent = i;
        }),

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_bar),
            label: 'Padding',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.width_full),
            label: 'Max Width',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'Font'),
          BottomNavigationBarItem(
            icon: Icon(Icons.font_download),
            label: 'Font Fam',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  padding: readerPadding(
                    context,
                    maxWidth: _maxWidth,
                    sidePadd: _padding,
                  ),
                  child: Text(
                    story,
                    style: style,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
            ),
            Divider(height: 0),
            switch (_curent) {
              0 => _Changer(
                title: 'Padding',
                subTitle: 'change padding',
                minV: 0,
                maxV: 50,
                current: _padding,
                step: 5,
                def: ReaderPageSettings.paddingDef,
                setVal: (v) => setState(() {
                  _padding = v;
                }),
              ),
              1 => _Changer(
                title: 'Width',
                subTitle: 'change width',
                minV: 400,
                maxV: 1200,
                current: _maxWidth,
                step: 20,
                def: ReaderPageSettings.maxWidthDef,
                setVal: (v) => setState(() {
                  _maxWidth = v;
                }),
              ),
              2 => _Changer(
                title: 'Font size',
                subTitle: 'change fontsize',
                minV: minReaderFontSize,
                maxV: maxReaderFontSize,
                current: _fontSize,
                step: 1,
                def: defaultReaderArabicFontSize,
                setVal: (v) => setState(() {
                  _fontSize = v;
                }),
              ),
              3 => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Title
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Select Font',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...separatedList(
                    items: arabicFonts,
                    separatorBuilder: (_) => SizedBox(height: 8),
                    itemBuilder: (font, _) {
                      // final font = arabicFonts[index];
                      final isSelected = font == _fontFam;

                      return Material(
                        color: isSelected
                            ? cs.primaryContainer
                            : cs.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: cs.outlineVariant, width: 1),
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
                                ? titleStyle?.copyWith(
                                    color: cs.onPrimaryContainer,
                                  )
                                : titleStyle,
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_outlined,
                                  color: cs.onPrimaryContainer,
                                )
                              : null,
                          onTap: () => setState(() {
                            _fontFam = font;
                          }),
                        ),
                      );
                    },
                  ),
                ],
              ),
              _ => Placeholder(),
            },
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

  const _Changer({
    // super.key,
    required this.title,
    required this.subTitle,
    required this.current,
    required this.minV,
    required this.maxV,
    required this.def,
    required this.step,
    required this.setVal,
  });

  @override
  Widget build(BuildContext context) {
    final divs = ((maxV - minV) / step).round();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final th = theme.textTheme;

    final subTitleStyle = th.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title, style: th.titleMedium),
          if (subTitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subTitle, style: subTitleStyle),
          ],
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                '${current.round()}px',
                style: th.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              Row(
                spacing: 18,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: current <= minV
                        ? null
                        : () {
                            final v = current - step.toDouble();
                            setVal(v);
                          },
                  ),

                  IconButton.filledTonal(
                    icon: const Icon(Icons.restore),
                    onPressed: current == def
                        ? null
                        : () {
                            setVal(def);
                          },
                  ),

                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: current >= maxV
                        ? null
                        : () {
                            final v = current + step.toDouble();
                            setVal(v);
                          },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${minV.toInt()}px', style: subTitleStyle),
                    Text('${maxV.toInt()}px', style: subTitleStyle),
                  ],
                ),
              ),
              Slider(
                value: current,
                min: minV,
                max: maxV,
                divisions: divs,
                onChanged: (v) {
                  setVal(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row(
          //   children: [
          //     Expanded(
          //       child: OutlinedButton(
          //         onPressed: () => Navigator.pop(context), // discard
          //         child: const Text('Cancel'),
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     Expanded(
          //       child: FilledButton(
          //         onPressed: () => Navigator.pop(context),
          //         child: const Text('Apply'),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
