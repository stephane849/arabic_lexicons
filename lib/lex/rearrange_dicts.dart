import 'dart:io';

import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<void> showDictReorderSheet(
  BuildContext context, {
  VoidCallback? after,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 500),
    builder: (_) => DictReorderSheet(),
  );
  after?.call();
}

class DictReorderSheet extends StatefulWidget {
  const DictReorderSheet({super.key});

  @override
  State<DictReorderSheet> createState() => _DictReorderSheetState();
}

class _DictReorderSheetState extends State<DictReorderSheet> {
  late List<Dict> _dicts;
  late bool _showEnglishNames;

  @override
  void initState() {
    super.initState();
    _dicts = List<Dict>.from(allDictsOrd);
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
      _dicts = List<Dict>.from(allDicts);
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
                            allDictsOrd = _dicts;
                            saveDictOrd();
                            Navigator.pop(context);
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

Future<String> dictOrdFilePath() async {
  final d = await getApplicationDocumentsDirectory();
  final p = join(d.path, 'dict_ord.txt');
  return p;
}

Future<void> saveDictOrd() async {
  final str = allDictsOrd.map((d) => '${d.en}:${d.ar}').join('\n');
  // assert(allDicts.length == allDictsOrd.length);
  bool sameOrder = true;
  for (int i = 0; i < allDictsOrd.length; i++) {
    if (allDicts[i] != allDictsOrd[i]) {
      sameOrder = false;
      break;
    }
  }

  try {
    final file = File(await dictOrdFilePath());
    if (sameOrder) {
      await file.delete();
    } else {
      await file.writeAsString(str);
    }
  } catch (_) {}
}

Future<void> setDictOrdFromFile() async {
  List<String> lines;
  try {
    final file = await dictOrdFilePath();
    lines = await File(file).readAsLines();
  } catch (_) {
    allDictsOrd = allDicts;
    return;
  }

  final set = <Dict>{};

  for (var l in lines) {
    l = l.trim();
    final parts = l.split(':');
    if (parts.length != 2) continue;
    final en = parts[0];
    final ar = parts[1];

    final idx = allDicts.indexWhere((d) => d.en == en && d.ar == ar);
    if (parts.length != 2) continue;
    set.add(allDicts[idx]);
  }

  for (final d in allDicts) {
    set.add(d);
  }

  allDictsOrd = List.from(set);
}
