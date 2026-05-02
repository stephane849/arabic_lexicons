import 'package:ara_dict/data.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

/// if [fontSize] is provided
/// then size wont be saved in [appConf]
/// but rather it will be returned
Future<double?> showFontSizeBottomSheet(
  BuildContext context, {
  double? fontSize,
  String? fontFam,
}) async {
  final ogSize = fontSize ?? appConf.fontSize;
  double tempSize = ogSize;

  const double minSize = 14;
  const double maxSize = 30;

  return await showModalBottomSheet<double?>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) {
      // final cs = Theme.of(context).colorScheme;
      final arabicFontStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontFamily: fontFam ?? appConf.readerTS(context).fontFamily,
        fontSize: fontSize ?? appConf.fontSize,
      );

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 8,
            ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Font Size: ${tempSize.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.30,
                    ),
                    child: SizedBox(
                      // height: double.infinity,
                      child: Center(
                        child: Text(
                          /* TXT */ "هذا مثال لتجربة حجم الخط\nهذا هو السطر التالي",
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: arabicFontStyle.copyWith(fontSize: tempSize),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    spacing: 12,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.text_decrease),
                        onPressed: tempSize <= minSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize--;
                                });
                              },
                      ),

                      IconButton.filledTonal(
                        icon: const Icon(Icons.restore),
                        onPressed: tempSize == defaultArabicFontSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize = defaultArabicFontSize;
                                });
                              },
                      ),

                      IconButton.filledTonal(
                        icon: const Icon(Icons.text_increase),
                        onPressed: tempSize >= maxSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize++;
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: tempSize,
                    min: minSize,
                    max: maxSize,
                    divisions: (maxSize - minSize).toInt(),
                    label: tempSize.toInt().toString(),
                    onChanged: (double value) {
                      setState(() {
                        tempSize = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     TextButton(
                  //       onPressed: () => Navigator.pop(context),
                  //       child: const Text("Cancel"),
                  //     ),
                  //     const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (fontSize != null) {
                            Navigator.pop(context, tempSize);
                            return;
                          }

                          await appConf.setFontSize(tempSize);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        label: ogSize == tempSize
                            ? const Text('Cancel')
                            : const Text('Save'),
                        icon: ogSize == tempSize
                            ? const Icon(Icons.cancel_outlined)
                            : const Icon(Icons.save_outlined),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ),
                  // ],
                  // ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
