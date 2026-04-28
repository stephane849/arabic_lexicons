import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/main_widgets.dart';
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
  bool _isReseting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _BuildInfo.init(context);
    final notifier = appSettingsNotifier;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const SettingsSectionHeader(title: 'Appearance & System'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 24,
                      ),
                      child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 20,
                        children: [
                          SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.settings_suggest),
                                label: Text('System'),
                                tooltip: 'System',
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode),
                                label: Text('Light'),
                                tooltip: 'Light',
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode),
                                label: Text('Dark'),
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
                              final selected =
                                  c == appSettingsNotifier.seedColor;
                              return GestureDetector(
                                onTap: () =>
                                    appSettingsNotifier.setSeedColor(c),
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
                  ),
                  // const SizedBox(height: 12),
                  const Divider(height: 0),
                  ListTile(
                    // leading: const Icon(Icons.text_fields),
                    leading: const FilledIcon(Icons.text_fields),
                    title: Text('Font Size ${notifier.fontSize.toInt()}'),
                    subtitle: const Text('Adjust the Arabic text size'),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: () => showFontSizeBottomSheet(context),
                  ),

                  const Divider(height: 0),

                  /// Keep Screen On
                  SwitchListTile(
                    secondary: FilledIcon(Icons.screen_lock_portrait),
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
                ],
              ),
            ),

            const SettingsSectionHeader(title: 'Lexicon'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  /// Suggestions
                  SwitchListTile(
                    secondary: FilledIcon(Icons.auto_awesome),
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
                    secondary: FilledIcon(Icons.directions),
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

                  const Divider(height: 0),

                  /// Direct Results
                  SwitchListTile(
                    secondary: FilledIcon(Icons.translate),
                    title: Text('Use English names'),
                    subtitle: Text(
                      'Display lexicon names in English in the selection menu',
                    ),
                    value: appSettingsNotifier.dictNamesEn,
                    onChanged: (value) {
                      notifier.saveDictNamesEn(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SettingsSectionHeader(title: 'Reader'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Open Lexicon Direcly'),
                    subtitle: const Text(
                      // 'Do not show popup of bookmakrs, bookmark it in the lexicon page',
                      'Skip bookmark popup. Use lexicon page bookmark option instead',
                    ),
                    secondary: const FilledIcon(Icons.directions),
                    value: appSettingsNotifier.readerIsOpenLexiconDirecly,
                    onChanged: (v) async {
                      await appSettingsNotifier.saveReaderIsOpenLexiconDirecly(
                        v,
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const SettingsSectionHeader(title: 'Reset settings'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: const Text('Reset Settings'),
                subtitle: const Text('Revert all settings to default'),
                leading: FilledIcon(
                  Icons.restore,
                  // iconColor: cs.onErrorContainer,
                  // bg: cs.errorContainer,
                ),
                trailing: const Icon(Icons.arrow_right),
                onTap: _isReseting
                    ? null
                    : () async {
                        if (_isReseting) return;

                        final ok = await showConfirmDialog(
                          context,
                          'Reset Settings',
                          message:
                              'All settings will be reset to default. Your data (eg. books and bookmarks) will remain unchanged.',
                          distructive: true,
                          confirmText: 'Reset',
                          constraints: true,
                        );
                        if (ok != null && ok) {
                          _isReseting = true;
                          setState(() {});
                          await notifier.reset();
                          _isReseting = false;
                          setState(() {});
                        }
                      },
              ),
            ),
            const SizedBox(height: 12),

            const SettingsSectionHeader(title: 'App info'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const FilledIcon(Icons.info_outline),
                    title: Text('App Version'),
                    subtitle: Text(
                      _BuildInfo.appVersion.isNotEmpty
                          ? 'v${_BuildInfo.appVersion}'
                          : 'N/A',
                    ),
                    trailing: Icon(Icons.arrow_right),
                    onTap: () {
                      launchUrl(Uri.parse(_BuildInfo.repoLink));
                    },
                  ),
                  if (!_BuildInfo.fdroidBuild) ...[
                    const Divider(height: 0),
                    ListTile(
                      leading: const FilledIcon(Icons.date_range),
                      title: const Text('Build At'),
                      subtitle: Text(_BuildInfo.buildTimeFormatted),
                      trailing: _BuildInfo._gitCommitMsg.isEmpty
                          ? null
                          : Icon(Icons.arrow_right),
                      onTap: _BuildInfo._gitCommitMsg.isEmpty
                          ? null
                          : () async {
                              await showInfoDialog(
                                context,
                                'Git commit Message',
                                message: _BuildInfo.gitCommitMsgStr,
                              );
                            },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const FilledIcon(Icons.question_answer),
                      title: Text('Git Commit'),
                      subtitle: Text(_BuildInfo.gitCommitStr),
                      trailing: _BuildInfo._gitCommit.isEmpty
                          ? null
                          : Icon(Icons.arrow_right),
                      onTap: _BuildInfo._gitCommit.isEmpty
                          ? null
                          : () {
                              launchUrl(
                                Uri.parse(
                                  '${_BuildInfo.commitsLink}${_BuildInfo._gitCommit}',
                                ),
                              );
                            },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const FilledIcon(Icons.update_outlined),
                      title: Text('Updates'),
                      subtitle: Text('Go to update page'),
                      trailing: Icon(Icons.arrow_right),
                      onTap: () {
                        launchUrl(Uri.parse(_BuildInfo.downloadUpdates));
                      },
                    ),
                  ],
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

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

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
  static const String appVersion = String.fromEnvironment('APP_VERSION');

  static const fdroidBuild = String.fromEnvironment('APP_STORE') == "F-Droid";
  // Environment variables
  static const _buildUnix = int.fromEnvironment(
    'BUILD_UNIX_TIME',
    defaultValue: 0,
  );
  static const _gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: '',
  );
  static const _gitCommitMsg = String.fromEnvironment(
    'GIT_COMMIT_MSG',
    defaultValue: '',
  );

  static const String commitsLink =
      'https://github.com/wizsk/arabic_lexicons/commit/';

  static const String repoLink = 'https://github.com/wizsk/arabic_lexicons/';

  static const String downloadUpdates =
      'https://github.com/wizsk/arabic_lexicons/releases/latest';

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
      buildTimeFormatted = formatDateTime(context, dt: buildTimeLocal);
    } else {
      buildTimeFormatted = 'N/A';
    }

    gitCommitStr = _gitCommit.isNotEmpty ? _gitCommit : 'N/A';
    gitCommitMsgStr = _gitCommitMsg.isNotEmpty ? _gitCommitMsg : 'N/A';

    _inited = true;
  }
}

class FilledIcon extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? bg;
  final double? iconSize;

  const FilledIcon(
    this.icon, {
    super.key,
    this.iconColor,
    this.iconSize,
    this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg ?? cs.primaryContainer,
        shape: BoxShape.circle,
        // borderRadius: BorderRadius.circular(),
      ),
      child: Icon(
        icon,
        color: iconColor ?? cs.onPrimaryContainer,
        size: iconSize ?? 20,
      ),
    );
  }
}
