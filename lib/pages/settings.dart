import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = appSettingsNotifier;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const _SectionHeader(title: 'Appearance'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.text_fields),
                    title: const Text('Font Size'),
                    subtitle: const Text('Adjust the Arabic text size'),
                    onTap: () => showFontSizeBottomSheet(context),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme'),
                    subtitle: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest),
                          tooltip: 'System',
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
                      selected: {notifier.theme},
                      onSelectionChanged: (selection) {
                        final selectedMode = selection.first;
                        notifier.saveTheme(selectedMode);
                        // setState(() {}); // if using StatefulWidget
                      },
                    ),
                  ),
                ],
              ),
            ),

            const _SectionHeader(title: 'Behavior'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  /// Keep Screen On
                  SwitchListTile(
                    secondary: const Icon(Icons.screen_lock_portrait),
                    title: const Text('Keep Screen On'),
                    subtitle: const Text(
                      // 'Prevents the screen from sleeping while using the app for $durationToScreenWake minutes',
                      'Keeps the screen on for $durationToScreenWake minutes',
                    ),
                    value: notifier.wake.isEnabled,
                    onChanged: (value) {
                      notifier.wake.tougle(enable: value);
                      setState(() {});
                    },
                  ),

                  const Divider(height: 0),

                  /// Suggestions
                  SwitchListTile(
                    secondary: const Icon(Icons.auto_awesome),
                    title: const Text('Search Suggestions'),
                    subtitle: const Text('Show suggestions while typing'),
                    value: appSettingsNotifier.showSearchSugg,
                    onChanged:
                        appSettingsNotifier.showSearchSugg &&
                            !SearchSuggestions.isInitalized
                        ? null
                        : (value) {
                            appSettingsNotifier.saveShowSearchSugg(value);
                            setState(() {});
                          },
                  ),

                  const Divider(height: 0),

                  /// Direct Results
                  SwitchListTile(
                    secondary: const Icon(Icons.directions),
                    title: const Text('Direct Results'),
                    subtitle: const Text(
                      'If an exact match is found, open results immediately instead of showing suggestions',
                    ),
                    value: appSettingsNotifier.showResutlsDirecly,
                    onChanged:
                        appSettingsNotifier.showSearchSugg &&
                            SearchSuggestions.isInitalized
                        ? (value) {
                            notifier.saveShowResutlsDirecly(value);
                            setState(() {});
                          }
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
