import 'package:ara_dict/pages/width_padd.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/pages/help/help_utils.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const buildUnix = int.fromEnvironment('BUILD_UNIX_TIME');
  static const appVersion = String.fromEnvironment('APP_VERSION');
  static const gitCommit = String.fromEnvironment('GIT_COMMIT');
  static const gitCommitMsg = String.fromEnvironment('GIT_COMMIT_MSG');

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: SafeArea(
        child: ListView(
          padding: readerPadding(
            context,
            maxWidth: appConf.maxWidth,
            sidePadd: appConf.padding,
          ),
          children: [
            // _SectionCard(
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         'This page still needs work. For now, watch the app overview video:',
            //         style: textTheme.titleMedium,
            //       ),
            //       const SizedBox(height: 12),
            //       InkWell(
            //         onTap: () => _openUrl(overViewURL),
            //         child: Text(overViewURL, style: linkStyle),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 16),

            // _SectionCard(
            //   title: 'Info',
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         'This app contains ${Dict.values.length - 1} lexicons and 1 dictionary for quick access.',
            //         style: textTheme.bodyLarge,
            //       ),
            //       const SizedBox(height: 12),
            //       const _Bullet('Search multiple words at the same time'),
            //       const _Bullet('Paste a full sentence and work through it'),
            //       const _Bullet(
            //         'Switch lexicons to go deeper into the meaning',
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 16),
            _SectionCard(
              title: 'Contact',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  _LinkRow(
                    label: 'Mail',
                    value: 'sakibul706@gmail.com',
                    onTap: () => _openUrl('mailto:sakibul706@gmail.com'),
                  ),
                  _LinkRow(
                    label: 'Telegram',
                    value: '@sakib26',
                    onTap: () => _openUrl('https://t.me/sakib26'),
                  ),
                  _LinkRow(
                    label: 'Web',
                    value: 'wizsk.github.io',
                    onTap: () => _openUrl('https://wizsk.github.io/'),
                  ),
                  _LinkRow(
                    label: 'GitHub',
                    value: 'github.com/wizsk',
                    onTap: () => _openUrl('https://github.com/wizsk'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Lexicons Screen',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    subTitle: 'Changing lexicons or words',
                    bullets: [
                      _BulletSpans(
                        TextSpan(
                          style: textTheme.bodyMedium,
                          children: [
                            TextSpan(text: 'Tap the '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                dictWordSelectModalOpenIcon,
                                size: 20,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ' icon to open the lexicon and word selector.',
                            ),
                          ],
                        ),
                      ),
                      _Bullet(
                        'Click on words in the search input to quickly swith to that word',
                      ),
                      _Bullet(
                        'The last inserted word is automatically selected',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Lexicon details (tap a name for details)',
              child: const DictList(),
            ),

            const SizedBox(height: 16),
            _SectionCard(
              title: 'Useful Websites',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  _LinkRow(
                    label: 'Hindawi - Free Arabic Ebooks',
                    value: 'www.hindawi.org',
                    onTap: () => _openUrl('https://www.hindawi.org/'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Center(
                child: Text(
                  title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _BulletSpans extends _BulletBase {
  final InlineSpan child;

  const _BulletSpans(this.child);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: theme.textTheme.bodyMedium),
          Expanded(child: Text.rich(child, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

sealed class _BulletBase extends StatelessWidget {
  const _BulletBase();
}

class _Bullet extends _BulletBase {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: theme.textTheme.bodyMedium),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LinkRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: cs.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: cs.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTilte extends StatelessWidget {
  final String subTitle;
  const _SubTilte(this.subTitle);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Text(
      subTitle,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _Section extends StatelessWidget {
  final String subTitle;
  final List<_BulletBase> bullets;
  const _Section({required this.subTitle, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [_SubTilte(subTitle), const SizedBox(height: 3), ...bullets],
    );
  }
}
