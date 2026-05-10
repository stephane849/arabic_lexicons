import 'package:ara_dict/bm/page.dart';
import 'package:ara_dict/conf.dart';
import 'package:ara_dict/reader/input.dart';
import 'package:ara_dict/pages/startup_screen.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/lexicons.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // await appSettingsNotifier.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appConf,
      builder: (context, _) {
        return Listener(
          // makes sure it's triggered every click
          behavior: HitTestBehavior.translucent,
          onPointerDown: WakelockController.isEnabled
              ? WakelockController.onUserActivity
              : null,
          // onPointerMove: WakelockController.onUserActivity,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: kDebugMode ? '(D) Arabic Lexicons' : 'Arabic Lexicons',

            theme: buildTheme(context, Brightness.light, appConf),
            darkTheme: buildTheme(context, Brightness.dark, appConf),
            themeMode: appConf.theme,
            initialRoute: Routes.startupscreen,
            routes: {
              Routes.startupscreen: (_) => const StartupScreen(),
              Routes.dictionary: (_) => const SearchLexicons(),
              Routes.readerInput: (_) => const ReaderInputPage(),
              Routes.bookMarks: (_) => const BookMarkPage(),
              // Routes.fams: (_) => const ArabicFamilyList(),
              // Routes.help: (_) => const HelpPage(),
            },
          ),
        );
      },
    );
  }
}
