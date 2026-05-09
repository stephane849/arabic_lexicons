import 'package:ara_dict/first_run.dart';
import 'package:ara_dict/pages/help/help_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ara_dict/data.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  static const buildUnix = int.fromEnvironment('BUILD_UNIX_TIME');
  static const appVersion = String.fromEnvironment('APP_VERSION');
  static const gitCommit = String.fromEnvironment('GIT_COMMIT');
  static const gitCommitMsg = String.fromEnvironment('GIT_COMMIT_MSG');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final linkTxtStyle = TextStyle(
      color: cs.primary,
      decoration: TextDecoration.underline,
      decorationColor: cs.primary,
    );

    const double listPadding = 8;

    return Scaffold(
      appBar: AppBar(title: Text('Help')),
      // drawer: buildDrawer(context),
      body: SafeArea(
        child: ListView(
          // mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.start,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
          children: [
            GestureDetector(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          'This Page Needs word, visit and warch the app overview video:\n',
                    ),
                    TextSpan(text: overViewURL, style: linkTxtStyle),
                  ],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              onTap: () {
                launchUrl(Uri.parse(overViewURL));
              },
            ),
            SizedBox(height: 24),
            Text('Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'This app is a collection of ${Dict.values.length - 1} lexicons and 1 dictionary for ease of access.',
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(left: listPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Search multiple word at the same time'),
                  Text('• Pase a full sentece and go through it'),
                  Text('• Change lexcion for going into depth of the meaning'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text.rich(
              TextSpan(
                children: [
                  // about dicts
                  TextSpan(
                    text: "\nChanging Lexcion or Word:\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: 'Click on the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(dictWordSelectModalOpenIcon),
                  ),
                  TextSpan(
                    text:
                        ' icon to open lexicon and word selector. By default the lexicons are presented, and if thre are more than 1 word then they are shown on top.\n\n',
                  ),

                  // about text editing
                  TextSpan(
                    text: "Auto select edited word:\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'When typing the edited word will automatically selected. For example you have typed "Foo bar bazz", by default "bazz" will be selected as it\'s the last word, then if you edit "bar" to "baar", then "baar" will be selected.\n\n',
                  ),

                  const TextSpan(
                    text: 'Contact: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // const TextSpan(text: '\nGo to: '),
                  // TextSpan(
                  //   text: 'github.com/wizsk/arabic_lexicons/',
                  //   style: linkTxtStyle,
                  //   recognizer: TapGestureRecognizer()
                  //     ..onTap = () {
                  //       launchUrl(
                  //         Uri.parse(
                  //           'https://github.com/wizsk/arabic_lexicons/',
                  //         ),
                  //       );
                  //     },
                  // ),
                  const TextSpan(
                    text: '\n\nMail: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'sakibul706@gmail.com',
                    style: linkTxtStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(Uri.parse('mailto:sakibul706@gmail.com'));
                      },
                  ),
                  const TextSpan(
                    text: '\n\nTelegram: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '@sakib26',
                    style: linkTxtStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(Uri.parse('https://t.me/sakib26'));
                      },
                  ),

                  const TextSpan(
                    text: '\n\nGitHub: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  TextSpan(
                    text: 'github.com/wizsk',
                    style: linkTxtStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(Uri.parse('https://github.com/wizsk'));
                      },
                  ),

                  TextSpan(text: "\n\n"),
                ],
              ),
            ),
            const Text(
              'Lexicon details: (click on the names for details)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const DictList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
