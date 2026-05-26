import 'dart:math';

import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/pages/width_padd.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef SelectableTextScreenFunc = String Function(int? start, int? end);

class SelectableTextScreen extends StatefulWidget {
  final SelectableTextScreenFunc fullTextFunc;
  final int? currentIdx;
  final int? start;
  // exclusive aka upuntil
  final int? end;
  final int? length;
  final TextAlign textAlign;
  final TextDirection dir;
  final TextStyle textStyleBodyMedium;

  const SelectableTextScreen({
    super.key,
    required this.fullTextFunc,
    this.currentIdx,
    this.start,
    this.end,
    this.length,
    required this.textAlign,
    required this.dir,
    required this.textStyleBodyMedium,
  });

  static Future<void> show(
    BuildContext context,
    SelectableTextScreenFunc fullTextFunc,
    TextAlign textAlign,
    TextDirection dir,
    TextStyle textStyleBodyMedium, {
    int? currentIdx,
    int? length,
    int? start,
    int? end,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectableTextScreen(
          fullTextFunc: fullTextFunc,
          textAlign: textAlign,
          dir: dir,
          textStyleBodyMedium: textStyleBodyMedium,
          currentIdx: currentIdx,
          length: length,
          start: start,
          end: end,
        ),
      ),
    );
  }

  @override
  State<SelectableTextScreen> createState() => _SelectableTextScreenState();
}

class _SelectableTextScreenState extends State<SelectableTextScreen> {
  late String _txt;
  late final int? _currIdx;
  late final int? _length;
  int? _start;
  int? _end;

  @override
  void initState() {
    super.initState();
    _currIdx = widget.currentIdx;
    _length = widget.length;

    assert(_currIdx == null || _length != null);

    if (_currIdx != null) {
      _start = widget.start ?? _currIdx!;
      _end = widget.end ?? _currIdx! + 1;
      // print('$_start, $_end frr');
    }

    _setTxt();
  }

  void _setTxt() {
    _txt = widget.fullTextFunc.call(_start, _end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final readerPadd = readerPadding(
      context,
      maxWidth: appConf.maxWidth,
      sidePadd: appConf.padding,
    );

    final sidePadd = max(24.0, readerPadd.right);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L.p('Select Text', /* txt */ 'حدد النص'),
          style: TextStyle(fontFamily: L.arFontIf),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy All',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _txt));

              if (!context.mounted) return;
              showSnack(context, 'Text copied');
            },
          ),
          if (_currIdx != null)
            IconButton(
              tooltip: 'Select range',
              icon: Icon(Icons.tune),
              onPressed: () async {
                const range = 5;
                // normalizing
                final curr = _currIdx! + 1;
                final start = _start! + 1;
                final end = (_end ?? start) + 1;

                final result = await showBoundsPickerDialog(
                  context: context,
                  currIdx: curr,
                  minLow: max(1, curr - range),
                  maxUp: min(_length!, curr + range),
                  lower: start,
                  upper: end,
                );

                if (result != null) {
                  _start = result.lower - 1;
                  _end = result.upper - 1;

                  if (!context.mounted) return;
                  setState(() => _setTxt());
                  showSnack(
                    context,
                    'Showing paras from ${result.lower} up until ${result.upper} '
                    '(total: ${result.upper - result.lower})',
                    duration: const Duration(seconds: 3),
                  );
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: widget.dir,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: ListView(
              padding: EdgeInsetsGeometry.fromLTRB(
                sidePadd,
                12,
                sidePadd,
                readerPadd.bottom,
              ),
              children: [
                SelectionArea(
                  magnifierConfiguration: TextMagnifierConfiguration.disabled,
                  contextMenuBuilder: (context, selectableRegionState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: selectableRegionState.contextMenuAnchors,
                      buttonItems: selectableRegionState.contextMenuButtonItems,
                    );
                  },
                  child: Text(
                    _txt,
                    textAlign: widget.textAlign,
                    style: widget.textStyleBodyMedium.copyWith(
                      // height: 2.0,
                      leadingDistribution: TextLeadingDistribution.even,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParaRangeDialouge extends StatefulWidget {
  final int currIdx;
  final int minLow;
  final int maxUp;
  final int lower;
  final int upper;
  final String title;

  const _ParaRangeDialouge({
    required this.currIdx,
    required this.minLow,
    required this.maxUp,
    required this.lower,
    required this.upper,
    this.title = 'Show Paras',
  });

  @override
  State<_ParaRangeDialouge> createState() => _ParaRangeDialougeState();
}

class _ParaRangeDialougeState extends State<_ParaRangeDialouge> {
  late int _currIdx;
  late int _minLow;
  late int _maxUp;
  late int _lower;
  late int _upper;
  late final String _title;

  @override
  void initState() {
    super.initState();
    _currIdx = widget.currIdx;
    _minLow = widget.minLow;
    _maxUp = widget.maxUp;
    _lower = widget.lower;
    _upper = widget.upper;
    _title = widget.title;
  }

  void changeLower(int delta) {
    setState(() {
      _lower = (_lower + delta).clamp(_minLow, _currIdx);
    });
  }

  void changeUpper(int delta) {
    setState(() {
      _upper = (_upper + delta).clamp(_currIdx + 1, _maxUp);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // icon: const Icon(Icons.linear_scale),
      title: Text(_title, textAlign: TextAlign.center),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              _ValueEditor(
                label: 'Start',
                value: _lower,
                onDecrease: _lower <= _minLow ? null : () => changeLower(-1),
                onIncrease: _currIdx == _lower ? null : () => changeLower(1),
              ),
              const Icon(Icons.arrow_right_alt_outlined, size: 28),
              _ValueEditor(
                label: 'End',
                value: _upper,
                onDecrease: _currIdx + 1 == _upper
                    ? null
                    : () => changeUpper(-1),
                onIncrease: _upper >= _maxUp ? null : () => changeUpper(1),
              ),
            ],
          ),

          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            label: Text('Resset'),
            icon: Icon(Icons.restore),
            onPressed: _lower == _currIdx && _upper == _currIdx + 1
                ? null
                : () {
                    setState(() {
                      _lower = _currIdx;
                      _upper = _currIdx + 1;
                    });
                  },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, (lower: _lower, upper: _upper));
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

typedef Bounds = ({int lower, int upper});

Future<Bounds?> showBoundsPickerDialog({
  required BuildContext context,
  required int currIdx,
  required int minLow,
  required int maxUp,
  required int lower,
  required int upper,
  String title = 'Show Paras',
}) {
  assert(minLow <= maxUp);
  // print('min: $minLow \t max: $maxUp \t curr: $currIdx');
  return showDialog<Bounds>(
    context: context,
    builder: (context) {
      return _ParaRangeDialouge(
        currIdx: currIdx,
        minLow: minLow,
        maxUp: maxUp,
        lower: lower,
        upper: upper,
        title: title,
      );
    },
  );
}

class _ValueEditor extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _ValueEditor({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 18,
      children: [
        // Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: onDecrease,
          icon: const Icon(Icons.remove),
        ),

        Text(
          '$value',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: onIncrease,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
