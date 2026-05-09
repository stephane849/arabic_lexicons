import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DictList extends StatelessWidget {
  // final List<Dict> dicts;

  const DictList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: allDicts.indexed.map((i) {
        final (idx, d) = i;
        return GestureDetector(
          onTap: () async {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                final theme = Theme.of(context);
                final cs = theme.colorScheme;

                return AlertDialog(
                  backgroundColor: cs.surface,
                  title: Text(
                    '${d.en} (${d.ar})',
                    style: theme.textTheme.titleLarge,
                  ),
                  content: Text(
                    d.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  actions: [
                    if (d.link != null)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          launchUrl(Uri.parse(d.link!));
                        },
                        child: Text('More Details'),
                      ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Ok'),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            '  ${(idx + 1).toString().padLeft(2, " ")}. ${d.en} (${d.ar}) - ${d.enLong}',
            overflow: TextOverflow.clip,
          ),
        );
      }).toList(),
    );
  }
}
