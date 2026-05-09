import 'package:ara_dict/lex/lexicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;

Future<void> openDict(BuildContext context, String word) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SearchLexicons(isPopup: true, initialText: word),
    ),
  );
}

String enToArNum(dynamic n) {
  return n.toString().replaceAllMapped(
    RegExp(r'[0-9]'),
    (m) => String.fromCharCode(0x0660 + int.parse(m.group(0)!)),
  );
}

String formatDateTime(BuildContext context, {DateTime? dt}) {
  dt ??= DateTime.now();
  final local = dt.toLocal();
  final use24h = MediaQuery.of(context).alwaysUse24HourFormat;

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;

  if (use24h) {
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute $day/$month/$year';
  } else {
    int hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');

    final isPm = hour >= 12;
    final period = isPm ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final hourStr = hour.toString().padLeft(2, '0');

    return '$hourStr:$minute $period $day/$month/$year';
  }
}

/// Capitalize the 1st char only 'fo' -> 'Fo'; '_fo' -> '_fo'
String capitalize(String? s) {
  if (s == null || s.isEmpty) return "";

  if (s.length == 1) s.characters.first.toUpperCase();

  return s.substring(0, 1).toUpperCase() + s.substring(1, s.length);
}

class LruCache<K, V> {
  final int capacity;
  final _map = <K, V>{};

  LruCache(this.capacity);

  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value; // move to end
    }
    return value;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key); // take it to first
    } else if (_map.length >= capacity) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }
}

String htmlToPlainText(String html) {
  final document = html_parser.parse(html);
  return document.body?.text ?? '';
}

String htmlToPlainTextWithLineBr(String html) {
  // handle block-level tags BEFORE parsing
  html = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<center>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</center>', caseSensitive: false), '\n');

  final document = html_parser.parse(html);

  if (document.body != null) {
    return document.body!.text
        .split("\n")
        .map((l) => l.trim())
        .where((l) => l != "")
        .join("\n");
  }

  return '';
}

void hideStatusBar() {
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.bottom, // keep navigation bar
    ],
  );
}

void showStatusBar() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
}

List<Widget> separatedList<T>({
  required List<T> items,
  required Widget Function(T item, int index) itemBuilder,
  required Widget Function(int index) separatorBuilder,
}) {
  final result = <Widget>[];

  for (int i = 0; i < items.length; i++) {
    result.add(itemBuilder(items[i], i));

    if (i != items.length - 1) {
      result.add(separatorBuilder(i));
    }
  }

  return result;
}

bool readerAppBarColorBg(double offset) {
  return offset <= kToolbarHeight;
}

Future<String?> getClipboardText() async {
  final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
  return clipboardData?.text;
}
