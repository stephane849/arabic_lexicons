import 'package:ara_dict/lex/lexicons.dart';
import 'package:flutter/material.dart';

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
