import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/reader/reader_widgets.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ReaderPage extends StatefulWidget {
  final List<List<WordEntry>> paras;

  const ReaderPage({super.key, required this.paras});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _scrollController = ScrollController();
  bool _isFabVisable = true;

  late final List<List<WordEntry>> _paras;
  late String _title;

  ReaderPageSettings _rs = ReaderPageSettings(
    isQasidah: false,
    qasidahLineNum: true,
    isRmTashkil: false,
    isOpenLexiconDirecly: appSettingsNotifier.readerIsOpenLexiconDirecly,
    textAlign: appSettingsNotifier.readerRightAligned
        ? TextAlign.right
        : TextAlign.justify,
  );

  @override
  void initState() {
    super.initState();
    _paras = widget.paras;
    _title = readerAppbarTitle(_paras, false);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _settingsDrawer() async {
    final res = await showReaderModeSettings(context, _rs, _paras);
    if (res == null || _rs.isEqual(res)) {
      return;
    }

    if (_rs.isOpenLexiconDirecly != res.isOpenLexiconDirecly) {
      await appSettingsNotifier.saveReaderIsOpenLexiconDirecly(
        res.isOpenLexiconDirecly,
      );
    }

    if (_rs.textAlign != res.textAlign) {
      await appSettingsNotifier.saveReaderRightAligned(
        res.textAlign == TextAlign.right,
      );
    }

    if (_rs.isRmTashkil != res.isRmTashkil) {
      _title = readerAppbarTitle(_paras, res.isRmTashkil);
    }

    _rs = res;
    setState(() {});
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isFabVisable) {
      setState(() {
        _isFabVisable = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isFabVisable) {
      setState(() {
        _isFabVisable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final highWordStyle = arabicFontStyle.copyWith(color: cs.error);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        exitReaderPage(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _title,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.settings),
            //   onPressed: _settingsDrawer,
            //   tooltip: 'Reader Mode settings',
            // ),
            IconButton(
              icon: const Icon(Icons.exit_to_app_outlined),
              tooltip: 'Exit Reader',
              onPressed: () => exitReaderPage(context),
            ),
          ],
        ),
        drawer: buildDrawer(context),
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ).copyWith(bottom: 128),
              itemCount: _paras.length,
              itemBuilder: (context, index) {
                final textAlign = _rs.isQasidah
                    ? TextAlign.right
                    : _rs.textAlign;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ClickableParagraph(
                    peraIndex: index,
                    rs: _rs,
                    pera: _paras[index],
                    textStyleBodyMedium: arabicFontStyle,
                    highTextStyleBodyMedium: highWordStyle,
                    cs: cs,
                    textAlign: textAlign,
                    onChange: () => setState(() {}),
                  ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: AnimatedSlide(
          duration: Duration(milliseconds: 300),
          offset: _isFabVisable ? Offset.zero : Offset(0, 2),
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _isFabVisable ? 1.0 : 0.0,
            child: FloatingActionButton(
              tooltip: 'Reader Mode settings',
              onPressed: _settingsDrawer,
              child: const Icon(Icons.settings),
            ),
          ),
        ),
      ),
    );
  }
}

void openReaderPage(BuildContext context, List<List<WordEntry>> paras) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: Routes.readerPage),
      builder: (_) => ReaderPage(paras: paras),
    ),
  );
}

Future<void> exitReaderPage(BuildContext context) async {
  if (!context.mounted) return;
  if (await showConfirmDialog(
        context,
        'Exit Reader',
        message: 'Go to reader input page?',
      ) ??
      false) {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, Routes.readerInput);
  }
}
