import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/theme.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Color Picker
const double _outer = 40;
const double _inner = 30;
const double _ringWidth = 3;
const double _gap =
    (_outer - _inner) / 2 - _ringWidth; // padding between ring and fill

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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                  // SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        SegmentedButton<ThemeMode>(
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: uiSeedColors.map((c) {
                            final selected = c == appSettingsNotifier.seedColor;
                            return GestureDetector(
                              onTap: () => appSettingsNotifier.setSeedColor(c),
                              child: Container(
                                width: _outer,
                                height: _outer,
                                padding: const EdgeInsets.all(_gap),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? c : Colors.transparent,
                                    width: _ringWidth,
                                  ),
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        : (value) async {
                            appSettingsNotifier
                                .saveShowSearchSugg(value)
                                .then((_) => setState(() {}));
                            setState(() {});
                          },
                  ),

                  const Divider(height: 0),

                  /// Direct Results
                  SwitchListTile(
                    secondary: const Icon(Icons.directions),
                    title: const Text('Direct Results'),
                    subtitle: const Text(
                      'Open results immediately if an exact match is found'
                      ' (but always direct in مباشر)',
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
            _SettingsFooter(),
            const SizedBox(height: 12),
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

class _BuildInfo {
  // Environment variables
  static const _buildUnix = int.fromEnvironment(
    'BUILD_UNIX_TIME',
    defaultValue: 0,
  );
  static const _appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '',
  );
  static const _gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: '',
  );
  static const _gitCommitMsg = String.fromEnvironment(
    'GIT_COMMIT_MSG',
    defaultValue: '',
  );

  static const String downloadUpdates =
      'https://github.com/wizsk/arabic_lexicons/releases/latest';

  static late final String appVersionStr;
  static late final String gitCommitStr;
  static late final String buildTimeFormatted;
  static late final String gitCommitMsgStr;

  static bool _inited = false;
  static void init(BuildContext context) {
    if (_inited) return;

    if (_buildUnix != 0) {
      DateTime buildTimeUtc = DateTime.fromMillisecondsSinceEpoch(
        _buildUnix * 1000,
        isUtc: true,
      );
      DateTime buildTimeLocal = buildTimeUtc.toLocal();
      buildTimeFormatted = formatDateTime(context, buildTimeLocal);
    } else {
      buildTimeFormatted = 'N/A';
    }

    appVersionStr = _appVersion.isNotEmpty ? _appVersion : 'N/A';
    gitCommitStr = _gitCommit.isNotEmpty ? _gitCommit : 'N/A';
    gitCommitMsgStr = _gitCommitMsg.isNotEmpty ? _gitCommitMsg : 'N/A';

    _inited = true;
  }
}

class _SettingsFooter extends StatelessWidget {
  // const _SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure data exists
    _BuildInfo.init(context);

    // Safe text style
    final textStyle =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12))
            .copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Divider(),
          Text('App Version: ${_BuildInfo.appVersionStr}', style: textStyle),
          Text('Build at: ${_BuildInfo.buildTimeFormatted}', style: textStyle),
          Text('Git Commit: ${_BuildInfo.gitCommitStr}', style: textStyle),
          Text(
            'Commit Message: ${_BuildInfo.gitCommitMsgStr}',
            style: textStyle,
          ),

          GestureDetector(
            onTap: () {
              launchUrl(Uri.parse(_BuildInfo.downloadUpdates));

              // Optionally, open link with url_launcher
            },
            child: Text(
              'Download Updates',
              style: textStyle.copyWith(
                color: Colors.blue.withAlpha(200),
                // decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
