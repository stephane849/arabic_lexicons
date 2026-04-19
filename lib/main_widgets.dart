import 'package:ara_dict/data.dart';
import 'package:ara_dict/fams.dart';
import 'package:ara_dict/pages/help.dart';
import 'package:ara_dict/pages/settings.dart';
import 'package:ara_dict/utils.dart';

import 'package:flutter/material.dart';

Widget buildDrawer(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final currRoute = ModalRoute.of(context)?.settings.name;

  int selectedIndex = switch (currRoute) {
    Routes.dictionary => 0,
    Routes.readerInput || Routes.readerPage => 1,
    Routes.bookMarks => 2,
    _ => -1,
  };

  return NavigationDrawer(
    selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
    onDestinationSelected: (index) {
      Navigator.pop(context);

      switch (index) {
        case 0:
          if (currRoute != Routes.dictionary) {
            Navigator.pushReplacementNamed(context, Routes.dictionary);
            appSettingsNotifier.saveRoute(Routes.dictionary);
          }
          break;

        case 1:
          if (currRoute != Routes.readerInput &&
              currRoute != Routes.readerPage) {
            Navigator.pushReplacementNamed(context, Routes.readerInput);
            appSettingsNotifier.saveRoute(Routes.readerInput);
          }
          break;

        case 2:
          if (currRoute != Routes.bookMarks) {
            Navigator.pushReplacementNamed(context, Routes.bookMarks);
          }
          break;

        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArabicFamilyList()),
          );
          break;

        case 4:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HelpPage()),
          );

        case 5:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsPage()),
          );
      }
    },
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
        child: Text(
          appName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
      ),

      NavigationDrawerDestination(
        icon: Icon(Icons.book),
        label: Text("Lexicons"),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.notes),
        label: Text("Reader"),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.bookmark),
        label: Text("BookMarks"),
      ),

      const Divider(),
      NavigationDrawerDestination(
        label: const Text("Verb Families"),
        icon: const Icon(Icons.info),
      ),
      NavigationDrawerDestination(
        label: const Text("Help"),
        icon: const Icon(Icons.help),
      ),
      NavigationDrawerDestination(
        label: const Text("Settings"),
        icon: const Icon(Icons.settings),
      ),
    ],
  );
}

Future<bool?> showInfoDialog(
  BuildContext context,
  String title, {
  String? message,
  String confirmText = 'Okay',
  TextDirection dir = TextDirection.ltr,
  bool constraints = false,
  bool distructive = false,
}) async {
  return showConfirmDialog(
    context,
    title,
    message: message,
    dir: dir,
    confirmText: confirmText,
    cancelText: null,
    constraints: constraints,
    distructive: distructive,
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context,
  String title, {
  String? message,
  String confirmText = 'Confirm',
  String? cancelText = 'Cancel',
  bool distructive = false,
  TextDirection dir = TextDirection.ltr,
  bool constraints = false,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      return AlertDialog(
        constraints: constraints ? const BoxConstraints(maxWidth: 450) : null,
        backgroundColor: cs.surface,
        title: Text(
          title,
          style: theme.textTheme.titleLarge,
          textDirection: dir,
        ),
        content: message == null
            ? null
            : Text(
                message,
                style: theme.textTheme.bodyMedium,
                textDirection: dir,
              ),
        actions: [
          if (cancelText != null)
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: distructive
                ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    textStyle: TextStyle(color: cs.onError),
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}

class CompactCheckboxTile extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final Widget title;
  final EdgeInsets padding;
  final double gap;

  const CompactCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.padding = const EdgeInsets.all(8),
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(value == null ? null : !value!),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: title),
            SizedBox(width: gap),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showThemeSelector(BuildContext mainContext) {
  return showDialog(
    context: mainContext,
    useSafeArea: true,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text('Select Theme'),
                Text(
                  'Select Theme: ${capitalize(appSettingsNotifier.theme.name)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 24),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest),
                          tooltip: 'Sytem',
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode),
                          tooltip: 'Light',
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode),
                          tooltip: 'Dark',
                        ),
                      ],
                      selected: {appSettingsNotifier.theme},
                      onSelectionChanged: (selection) {
                        Navigator.pop(context);
                        final selectedMode = selection.first;
                        appSettingsNotifier.saveTheme(selectedMode);
                      },
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
