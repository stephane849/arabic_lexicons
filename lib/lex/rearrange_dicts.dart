import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

void showDictReorderSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DictReorderSheet(initialDicts: allDicts),
    constraints: const BoxConstraints(maxWidth: 500),
  ).then((result) {
    if (result != null) {
      // setState(() => allDicts = result);
    }
  });
}

class DictReorderSheet extends StatefulWidget {
  final List<Dict> initialDicts;
  const DictReorderSheet({super.key, required this.initialDicts});

  @override
  State<DictReorderSheet> createState() => _DictReorderSheetState();
}

class _DictReorderSheetState extends State<DictReorderSheet> {
  late List<Dict> _dicts;

  @override
  void initState() {
    super.initState();
    _dicts = List.from(widget.initialDicts);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cs = scheme;
    final th = Theme.of(context).textTheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.6, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          // Top padding when sheet is fully expanded so content clears status bar
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            children: [
              // Pill
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lexicon order',
                            style: th.titleMedium?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Drag to rearrange',
                            style: th.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.restore),
                      // label: Text('Reset'),
                      onPressed: () {
                        setState(() {
                          _dicts = List.from(allDicts);
                        });
                      },
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: scheme.outlineVariant),

              // List
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  scrollController: scrollController,
                  itemCount: _dicts.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _dicts.removeAt(oldIndex);
                      _dicts.insert(newIndex, item);
                    });
                  },
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 4,
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final dict = _dicts[index];
                    return Column(
                      key: ValueKey(dict),
                      children: [
                        ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primaryContainer,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            dict.en,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            dict.ar,
                            // textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: scheme.outlineVariant.withAlpha(130),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: scheme.outline),
                          foregroundColor: scheme.onSurfaceVariant,
                          // shape: RoundedRectangleBorder(
                          //   borderRadius: BorderRadius.circular(10),
                          // ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, _dicts),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          // shape: RoundedRectangleBorder(
                          //   borderRadius: BorderRadius.circular(10),
                          // ),
                        ),
                        child: const Text('Save order'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
