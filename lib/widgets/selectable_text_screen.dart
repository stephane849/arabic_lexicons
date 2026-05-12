import 'package:ara_dict/conf.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectableTextScreen extends StatefulWidget {
  final String Function() fullTextFunc;
  final TextAlign textAlign;
  final TextDirection dir;
  final TextStyle textStyleBodyMedium;
  final String Function()? fullTextFuncSecondary;

  const SelectableTextScreen({
    super.key,
    required this.fullTextFunc,
    required this.textAlign,
    required this.dir,
    required this.textStyleBodyMedium,
    this.fullTextFuncSecondary,
  });

  static Future<void> show(
    BuildContext context,
    String Function() fullTextFunc,
    TextAlign textAlign,
    TextDirection dir,
    TextStyle textStyleBodyMedium, {
    String Function()? fullTextFuncSecondary,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectableTextScreen(
          fullTextFunc: fullTextFunc,
          textAlign: textAlign,
          dir: dir,
          textStyleBodyMedium: textStyleBodyMedium,
          fullTextFuncSecondary: fullTextFuncSecondary,
        ),
      ),
    );
  }

  @override
  State<SelectableTextScreen> createState() => _SelectableTextScreenState();
}

class _SelectableTextScreenState extends State<SelectableTextScreen> {
  late final String txt;
  late final String? txt2;

  @override
  void initState() {
    super.initState();

    txt = widget.fullTextFunc();
    txt2 = widget.fullTextFuncSecondary?.call();
  }

  bool _showTxt2 = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L.p('Select Text', /* txt */ 'حدد النص'),
          style: TextStyle(fontFamily: L.arFontIf),
        ),
        actions: [
          if (txt2 != null)
            IconButton(
              tooltip: 'Show secondary text',
              icon: Icon(
                Icons.insert_page_break_sharp,
                color: _showTxt2 ? cs.error : null,
              ),
              onPressed: () {
                setState(() {
                  _showTxt2 = !_showTxt2;
                });
              },
            ),
          IconButton(
            tooltip: 'Copy All',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: _showTxt2 && txt2 != null ? txt2! : txt),
              );

              if (!context.mounted) return;
              showSnack(context, 'Text copied');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: widget.dir,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ).copyWith(bottom: 128),
              children: [
                SelectionArea(
                  magnifierConfiguration: TextMagnifierConfiguration.disabled,
                  contextMenuBuilder: (context, selectableRegionState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: selectableRegionState.contextMenuAnchors,
                      buttonItems: selectableRegionState.contextMenuButtonItems,
                    );
                  },
                  child: Text(
                    _showTxt2 ? txt2 ?? '---- NO secondary text ----' : txt,
                    textAlign: widget.textAlign,
                    style: widget.textStyleBodyMedium.copyWith(
                      height: 2.0,
                      leadingDistribution: TextLeadingDistribution.even,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
