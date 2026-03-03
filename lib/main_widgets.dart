import 'package:ara_dict/data.dart';
import 'package:ara_dict/fams.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/help.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
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

      const Divider(),

      Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          children: [
            ListTile(
              title: const Text('Font Size'),
              leading: const Icon(Icons.text_fields),
              onTap: () {
                Navigator.pop(context);
                showFontSizeBottomSheet(context);
              },
            ),

            ListTile(
              title: Text(
                'Theme: ${capitalize(appSettingsNotifier.theme.name)}',
              ),
              leading: Icon(switch (appSettingsNotifier.theme) {
                ThemeMode.system => Icons.settings_suggest,
                ThemeMode.light => Icons.light_mode,
                ThemeMode.dark => Icons.dark_mode,
              }),
              onTap: () {
                Navigator.pop(context);
                showThemeSelector(context);
              },
            ),

            SwitchListTile(
              title: const Text('Screen on'),
              secondary: const Icon(Icons.screen_lock_portrait),
              value: appSettingsNotifier.wake.isEnabled(),
              onChanged: (value) {
                Navigator.pop(context);
                appSettingsNotifier.wake.tougle(enable: value);
              },
            ),

            SwitchListTile(
              title: const Text('Suggestions'),
              secondary: const Icon(Icons.auto_awesome),
              value: appSettingsNotifier.showSearchSugg,
              onChanged:
                  appSettingsNotifier.showSearchSugg &&
                      !SearchSuggestions.isInitalized
                  ? null
                  : (value) {
                      Navigator.pop(context);
                      appSettingsNotifier.saveShowSearchSugg(value);
                    },
            ),
            SwitchListTile(
              title: const Text('Direct Results'),
              secondary: const Icon(Icons.directions),
              value: appSettingsNotifier.showResutlsDirecly,
              onChanged:
                  appSettingsNotifier.showSearchSugg &&
                      SearchSuggestions.isInitalized
                  ? (value) {
                      Navigator.pop(context);
                      appSettingsNotifier.saveShowResutlsDirecly(value);
                    }
                  : null,
            ),
          ],
        ),
      ),

      // const SizedBox(height: 50),
    ],
  );
}

Widget _buildDrawer(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final currRoute = ModalRoute.of(context)?.settings.name;
  return Drawer(
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: cs.primary),
                child: Text(
                  appName,
                  style: TextStyle(
                    color: cs.onInverseSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                selected: currRoute == Routes.dictionary,
                title: Text("Lexicons"),
                leading: Icon(Icons.book),
                onTap: () {
                  Navigator.pop(context);
                  if (currRoute != Routes.dictionary) {
                    Navigator.pushReplacementNamed(context, Routes.dictionary);
                    appSettingsNotifier.saveRoute(Routes.dictionary);
                  }
                },
              ),
              ListTile(
                selected:
                    currRoute == Routes.readerInput ||
                    currRoute == Routes.readerPage,
                title: Text("Reader"),
                leading: Icon(Icons.notes),
                onTap: () {
                  Navigator.pop(context);
                  if (currRoute != Routes.readerInput &&
                      currRoute != Routes.readerPage) {
                    Navigator.pushReplacementNamed(context, Routes.readerInput);
                    appSettingsNotifier.saveRoute(Routes.readerInput);
                  }
                },
              ),
              ListTile(
                selected: currRoute == Routes.bookMarks,
                title: Text("BookMarks"),
                leading: Icon(Icons.bookmark),
                onTap: () {
                  Navigator.pop(context);
                  if (currRoute != Routes.bookMarks) {
                    Navigator.pushReplacementNamed(context, Routes.bookMarks);
                  }
                },
              ),
              ListTile(
                // selected: currRoute == Routes.fams,
                title: Text("Verb Famalies"),
                leading: Icon(Icons.info),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ArabicFamilyList()),
                  );
                },
              ),
              ListTile(
                // selected: currRoute == Routes.help,
                title: Text("Help"),
                leading: Icon(Icons.help),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HelpPage()),
                  );
                },
              ),
            ],
          ),
        ),

        Divider(),
        ListTile(
          title: const Text('Change Font Size'),
          leading: const Icon(Icons.text_fields),
          onTap: () {
            Navigator.pop(context);
            // showFontSizeDialog(context, appSettingsNotifier);
            showFontSizeBottomSheet(context);
          },
        ),
        ListTile(
          title: Text('Theme: ${capitalize(appSettingsNotifier.theme.name)}'),
          leading: Icon(switch (appSettingsNotifier.theme) {
            ThemeMode.system => Icons.settings_suggest,
            ThemeMode.light => Icons.light_mode,
            ThemeMode.dark => Icons.dark_mode,
          }),
          // trailing: Chip(
          //   label: Text(capitalize(appSettingsNotifier.theme.name)),
          // ),
          onTap: () {
            Navigator.pop(context);
            showThemeSelector(context);
          },
        ),
        SwitchListTile(
          title: const Text('Keep Screen on'),
          secondary: Icon(Icons.screen_lock_portrait),
          value: appSettingsNotifier.wake.isEnabled(),
          onChanged: (value) {
            Navigator.pop(context);
            appSettingsNotifier.wake.tougle(enable: value);
          },
        ),
        SwitchListTile(
          title: const Text('Suggestions'),
          secondary: Icon(Icons.auto_awesome),
          value: appSettingsNotifier.showSearchSugg,
          onChanged:
              appSettingsNotifier.showSearchSugg &&
                  !SearchSuggestions.isInitalized
              ? null
              : (value) {
                  Navigator.pop(context);
                  appSettingsNotifier.saveShowSearchSugg(value);
                },
        ),
        SizedBox(height: 50),
      ],
    ),
  );
}

Future<bool?> showInfoDialog(
  BuildContext context,
  String title, {
  String? message,
  String confirmText = 'Ok',
  TextDirection dir = TextDirection.ltr,
}) async {
  return showConfirmDialog(
    context,
    title,
    message: message,
    dir: dir,
    confirmText: confirmText,
    cancelText: null,
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context,
  String title, {
  String? message,
  String confirmText = 'Confirm',
  String? cancelText = 'Cancel',
  TextDirection dir = TextDirection.ltr,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      return AlertDialog(
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
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
