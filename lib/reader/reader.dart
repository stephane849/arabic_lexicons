import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader/reader_settings.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/reader/reader_widgets.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ReaderPage extends StatefulWidget {
  final List<List<WordEntry>> paras;
  final ReaderPageSettings rs;

  const ReaderPage({super.key, required this.paras, required this.rs});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final List<List<WordEntry>> _paras;
  late String _title;
  late ReaderPageSettings _rs;

  @override
  void initState() {
    super.initState();
    _paras = widget.paras;
    _rs = widget.rs;
    _title = readerAppbarTitle(_paras, _rs.isRmTashkil);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _settingsDrawer() async {
    final res = await showReaderModeSettings(context, _rs, _paras);
    if (!mounted) return;
    if (res == null || _rs.isEqual(res)) {
      return;
    }

    if (_rs.isRmTashkil != res.isRmTashkil) {
      _title = readerAppbarTitle(_paras, res.isRmTashkil);
    }

    _rs = res;
    setState(() {});
    _rs.saveToFile();
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SliverAppBar(
        floating: true,
        snap: true,
        pinned: false,
        title: Text(
          _title,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
        ),
        actions: [
          IconButton(
            tooltip: 'Reader Mode settings',
            onPressed: _settingsDrawer,
            icon: const Icon(Icons.tune),
          ),
          // IconButton(
          //   icon: const Icon(Icons.exit_to_app_outlined),
          //   tooltip: 'Exit Reader',
          //   onPressed: () => exitReaderPage(context),
          // ),
        ],
      ),
    );
  }

  Widget _buildQasidahSliver(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final highWordStyle = arabicFontStyle.copyWith(color: cs.error);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClickableBayt(
            peraIndex: index,
            rs: _rs,
            pera: _paras[index],
            textStyleBodyMedium: arabicFontStyle,
            highTextStyleBodyMedium: highWordStyle,
            cs: cs,
            textAlign: TextAlign.right,
            onChange: () => setState(() {}),
            fullTextFunc: () {
              List<List<WordEntry>> currPeras;
              if (index % 2 == 0) {
                if (_paras.length > index + 1) {
                  currPeras = [_paras[index], _paras[index + 1]];
                } else {
                  currPeras = [_paras[index]];
                }
              } else {
                currPeras = [_paras[index - 1], _paras[index]];
              }

              return currPeras
                  .map(
                    (p) =>
                        p.map((w) => _rs.isRmTashkil ? w.nTk : w.ar).join(' '),
                  )
                  .join('\n');
            },
          ),
        );
      }, childCount: _paras.length),
    );
  }

  Widget _buildParagraphSliver(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final highWordStyle = arabicFontStyle.copyWith(color: cs.error);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final currPera = _paras[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClickableParagraph(
            rs: _rs,
            pera: currPera,
            textStyleBodyMedium: arabicFontStyle,
            highTextStyleBodyMedium: highWordStyle,
            cs: cs,
            textAlign: _rs.textAlign,
            fullTextFunc: () {
              return currPera
                  .map((w) => _rs.isRmTashkil ? w.nTk : w.ar)
                  .join(' ');
            },
            onChange: () => setState(() {}),
          ),
        );
      }, childCount: _paras.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        exitReaderPage(context);
      },
      child: Scaffold(
        drawer: buildDrawer(context),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ).copyWith(bottom: 128),
                sliver: _rs.isQasidah
                    ? _buildQasidahSliver(context)
                    : _buildParagraphSliver(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void openReaderPage(
  BuildContext context,
  List<List<WordEntry>> paras,
  ReaderPageSettings rs,
) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: Routes.readerPage),
      builder: (_) => ReaderPage(paras: paras, rs: rs),
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
