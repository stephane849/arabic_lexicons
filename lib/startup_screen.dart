import 'package:ara_dict/ar_en/ar_en.dart';
import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Future.wait([
        appSettingsNotifier.load(),
        DbService.init(),
        ArEnDict.init(),
      ]);

      if (allDicts.length != Dict.values.length) {
        throw 'Dict enum size changed';
      }

      // don't need to wait for these
      SearchSuggestions.init();
      BookMarks.load();

      // await Future.delayed(
      //   Duration(seconds: 3),
      // ); // for testing, looking at the loader lol

      appSettingsNotifier.notify();
      if (!mounted) return;
      await Navigator.pushReplacementNamed(
        context,
        appSettingsNotifier.lastRoute,
      );
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context,
          'Fetal error',
          message: 'Could not read resources: $e',
          confirmText: 'Exit',
        );
      }
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Loading...")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading resources...'),
          ],
        ),
      ),
    );
  }
}
