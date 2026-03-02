import 'package:ara_dict/ar_en/isolate_v2.dart';
import 'package:ara_dict/ar_en/ar_en_utils.dart';
import 'package:ara_dict/utils.dart';

class ArEnEntry {
  final String root;
  final String word;
  final String def;

  ArEnEntry({required this.root, required this.word, required this.def});
}

// Dictionary class
class ArEnDict {
  static late final ArEnIsolate _eng;
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;

    final datas = await Future.wait([
      loadData('assets/data/ar_en/dictprefixes'),
      loadData('assets/data/ar_en/dictstems'),
      loadData('assets/data/ar_en/dictsuffixes'),
      loadData('assets/data/ar_en/tableab'),
      loadData('assets/data/ar_en/tableac'),
      loadData('assets/data/ar_en/tablebc'),
    ]);

    _eng = ArEnIsolate();
    await _eng.spawn();
    await _eng.init(datas);
    _loaded = true;
  }

  static final _cache = LruCache<String, List<ArEnEntry>>(200);

  // Method to find word
  static Future<List<ArEnEntry>> findWord(String? words) async {
    if (!_loaded) return [];

    if (words == null || words.isEmpty) return [];
    final c = _cache.get(words);
    if (c != null) return c;

    // final datas = _datas;
    final res = await _eng.search(words);
    _cache.put(words, res.results);

    return res.results;
  }
}
