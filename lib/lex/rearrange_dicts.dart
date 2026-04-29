import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

// void showDictReorderSheet(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => DictReorderSheet(initialDicts: allDictsOrd),
//     constraints: const BoxConstraints(maxWidth: 500),
//   ).then((result) {
//     if (result != null) {
//       allDictsOrd = result;
//       // setState(() => allDicts = result);
//     }
//   });
// }

// class DictReorderSheet extends StatefulWidget {
//   final List<Dict> initialDicts;
//   const DictReorderSheet({super.key, required this.initialDicts});

//   @override
//   State<DictReorderSheet> createState() => _DictReorderSheetState();
// }

// class _DictReorderSheetState extends State<DictReorderSheet> {
//   late List<Dict> _dicts;

//   @override
//   void initState() {
//     super.initState();
//     _dicts = List.from(widget.initialDicts);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final cs = scheme;
//     final th = Theme.of(context).textTheme;
//     final topPadding = MediaQuery.of(context).padding.top;
//     final isEng = appSettingsNotifier.dictNamesEn;
//     final titleStyle = TextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.w500,
//       color: scheme.onSurface,
//       fontFamily: isEng ? null : fontTajawal,
//     );
//     final subTitleStyle = TextStyle(
//       fontSize: 12,
//       color: scheme.onSurfaceVariant,
//       fontFamily: isEng ? fontTajawal : null,
//     );

//     return DraggableScrollableSheet(
//       initialChildSize: 0.9,
//       minChildSize: 0.4,
//       maxChildSize: 1.0,
//       snap: true,
//       snapSizes: const [0.6, 1.0],
//       builder: (context, scrollController) {
//         return Container(
//           decoration: BoxDecoration(
//             color: scheme.surface,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//           ),
//           // Top padding when sheet is fully expanded so content clears status bar
//           padding: EdgeInsets.only(top: topPadding),
//           child: Column(
//             children: [
//               // Pill
//               Center(
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(vertical: 10),
//                   width: 32,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: scheme.outlineVariant,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),

//               // Header
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
//                 child: Row(
//                   spacing: 6,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Lexicon order',
//                             style: th.titleMedium?.copyWith(
//                               color: scheme.onSurface,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             'Drag to rearrange',
//                             style: th.bodySmall?.copyWith(
//                               color: scheme.onSurfaceVariant,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton.filledTonal(
//                       icon: const Icon(Icons.translate),
//                       // label: Text('Reset'),
//                       onPressed: () async {
//                         await appSettingsNotifier.saveDictNamesEn(!isEng);
//                         if (context.mounted) setState(() {});
//                       },
//                     ),
//                     IconButton.filledTonal(
//                       icon: const Icon(Icons.restore),
//                       // label: Text('Reset'),
//                       onPressed: () {
//                         setState(() {
//                           _dicts = List.from(allDicts);
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),

//               Divider(height: 1, color: scheme.outlineVariant),

//               // List
//               Expanded(
//                 child: ReorderableListView.builder(
//                   padding: EdgeInsets.symmetric(horizontal: 8),
//                   scrollController: scrollController,
//                   itemCount: _dicts.length,
//                   onReorder: (oldIndex, newIndex) {
//                     setState(() {
//                       if (newIndex > oldIndex) newIndex--;
//                       final item = _dicts.removeAt(oldIndex);
//                       _dicts.insert(newIndex, item);
//                     });
//                   },
//                   proxyDecorator: (child, index, animation) {
//                     return Material(
//                       elevation: 4,
//                       color: scheme.primaryContainer,
//                       borderRadius: BorderRadius.circular(8),
//                       child: child,
//                     );
//                   },
//                   itemBuilder: (context, index) {
//                     final dict = _dicts[index];
//                     return Column(
//                       key: ValueKey(dict),
//                       children: [
//                         ListTile(
//                           leading: Container(
//                             width: 32,
//                             height: 32,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: scheme.primaryContainer,
//                             ),
//                             alignment: Alignment.center,
//                             child: Text(
//                               '${index + 1}',
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: scheme.onPrimaryContainer,
//                               ),
//                             ),
//                           ),
//                           title: Text(
//                             isEng ? dict.en : dict.ar,
//                             style: titleStyle,
//                           ),
//                           subtitle: Text(
//                             isEng ? dict.ar : dict.en,
//                             style: subTitleStyle,
//                           ),
//                         ),
//                         Divider(
//                           height: 1,
//                           indent: 16,
//                           endIndent: 16,
//                           color: scheme.outlineVariant.withAlpha(130),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),

//               // Buttons
//               Padding(
//                 padding: EdgeInsets.fromLTRB(
//                   16,
//                   8,
//                   16,
//                   MediaQuery.of(context).padding.bottom + 12,
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           side: BorderSide(color: scheme.outline),
//                           foregroundColor: scheme.onSurfaceVariant,
//                           // shape: RoundedRectangleBorder(
//                           //   borderRadius: BorderRadius.circular(10),
//                           // ),
//                         ),
//                         child: const Text('Cancel'),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       flex: 2,
//                       child: FilledButton(
//                         onPressed: () => Navigator.pop(context, _dicts),
//                         style: FilledButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           // shape: RoundedRectangleBorder(
//                           //   borderRadius: BorderRadius.circular(10),
//                           // ),
//                         ),
//                         child: const Text('Save order'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

Future<void> showDictReorderSheet(BuildContext context) async {
  final result = await showModalBottomSheet<List<Dict>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 500),
    // shape: BorderRadius.vertical(top: Radius.circular(28)),
    builder: (_) => DictReorderSheet(initialDicts: allDictsOrd),
  );

  if (result != null) {
    allDictsOrd = List<Dict>.from(result);
    // setState(() => allDicts = List<Dict>.from(result));
  }
}

class DictReorderSheet extends StatefulWidget {
  final List<Dict> initialDicts;

  const DictReorderSheet({super.key, required this.initialDicts});

  @override
  State<DictReorderSheet> createState() => _DictReorderSheetState();
}

class _DictReorderSheetState extends State<DictReorderSheet> {
  late List<Dict> _dicts;
  late bool _showEnglishNames;

  @override
  void initState() {
    super.initState();
    _dicts = List<Dict>.from(widget.initialDicts);
    _showEnglishNames = appSettingsNotifier.dictNamesEn;
  }

  Future<void> _setShowEnglishNames() async {
    final v = !_showEnglishNames;
    await appSettingsNotifier.saveDictNamesEn(v);
    setState(() {
      _showEnglishNames = v;
    });
  }

  void _resetOrder() {
    setState(() {
      _dicts = List<Dict>.from(widget.initialDicts);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _dicts.removeAt(oldIndex);
      _dicts.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final th = Theme.of(context).textTheme;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final titleStyle = th.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      fontFamily: _showEnglishNames ? null : fontTajawal,
    );

    final subtitleStyle = th.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFamily: _showEnglishNames ? fontTajawal : null,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.97,
      minChildSize: 0.45,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            // color: scheme.surfaceContainer,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: topInset > 0 ? 4 : 0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lexicon order',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: th.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Drag items to rearrange',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: th.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // OutlinedButton(
                      //   onPressed: _resetOrder,
                      //   child: Text('Reset'),
                      //   // icon: const Icon(Icons.restore_rounded),
                      // ),
                      IconButton.filledTonal(
                        tooltip: 'Reset order',
                        onPressed: _setShowEnglishNames,
                        icon: _showEnglishNames
                            ? Icon(Icons.g_translate_rounded)
                            : Icon(Icons.language_rounded),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Reset order',
                        onPressed: _resetOrder,
                        icon: const Icon(Icons.restore_rounded),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: scheme.outlineVariant),

                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: scrollController,
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    itemCount: _dicts.length,
                    onReorder: _reorder,
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 4,
                        // shadowColor: scheme.shadow,
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final dict = _dicts[index];
                      final primaryText = _showEnglishNames ? dict.en : dict.ar;
                      final secondaryText = _showEnglishNames
                          ? dict.ar
                          : dict.en;

                      return Padding(
                        key: ObjectKey(dict),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: scheme.primary.withAlpha(220),
                              foregroundColor: scheme.onPrimary,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            title: Text(
                              primaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            subtitle: Text(
                              secondaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleStyle,
                            ),
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context, List<Dict>.from(_dicts));
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Save order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
