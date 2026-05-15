import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

Future<double?> showSizePicker(
  BuildContext context, {
  required String title,
  String? subTitle,
  required double current,
  required double minV,
  required double maxV,
  required double def,
  required int step,
  required void Function(double w) setTempWidth,
}) {
  final notifier = ValueNotifier<double>(current);
  final divs = ((maxV - minV) / step).round();
  return showModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    barrierColor: Theme.of(context).brightness == Brightness.light
        ? Colors.black.withAlpha(20)
        : Colors.white.withAlpha(20),
    constraints: BoxConstraints(maxWidth: 600),
    builder: (context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final th = theme.textTheme;

      final subTitleStyle = th.bodySmall?.copyWith(color: cs.onSurfaceVariant);

      return SingleChildScrollView(
        padding: scrollPaddingBottmSheet(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: th.titleMedium),
            if (subTitle != null) ...[
              const SizedBox(height: 4),
              Text(subTitle, style: subTitleStyle),
            ],
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: notifier,
              builder: (context, val, _) => Column(
                children: [
                  Text(
                    '${val.round()}px',
                    style: th.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    spacing: 18,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: val <= minV
                            ? null
                            : () {
                                final v = val - step.toDouble();
                                notifier.value = v;
                                setTempWidth(v);
                              },
                      ),

                      IconButton.filledTonal(
                        icon: const Icon(Icons.restore),
                        onPressed: val == def
                            ? null
                            : () {
                                notifier.value = def;
                                setTempWidth(def);
                              },
                      ),

                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: val >= maxV
                            ? null
                            : () {
                                final v = val + step.toDouble();
                                notifier.value = v;
                                setTempWidth(v);
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
                    value: val,
                    min: minV,
                    max: maxV,
                    divisions: divs,
                    onChanged: (v) {
                      notifier.value = v;
                      setTempWidth(v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context), // discard
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, notifier.value),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
