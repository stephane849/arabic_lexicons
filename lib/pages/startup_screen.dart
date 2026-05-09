import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lex/isolate.dart';
import 'package:ara_dict/lex/rearrange_dicts.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/foundation.dart';
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
      // run it in the bg

      // run in the bg
      await Future.wait([
        appConf.load(),
        setDictOrdFromFile(),
        DbService.init(),
        BookMarks.load(),
        // SearchSuggestions.init(),
      ]);

      if (kDebugMode) {
        await Isolates.spawn();
        await Future.wait([Isolates.initArEn(), Isolates.initSugg()]);
      } else {
        Isolates.spawn().then((_) {
          Isolates.initArEn();
          Isolates.initSugg();
        });
      }

      // don't need to wait for these
      // SearchSuggestions.init();

      // await Future.delayed(Duration(seconds: 3)); // for testing, looking at the loader lol

      appConf.notify();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, appConf.lastRoute);
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
    return const Scaffold(
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
