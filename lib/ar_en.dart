import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';

Future<ByteData> _loadData(String path) async {
  return await rootBundle.load(path);
}

String _decodeData(ByteData data) {
  return latin1.decode(data.buffer.asUint8List());
}

// Define Entry class (similar to the Go struct Entry)
class Entry {
  final String root;
  final String word;
  final String morph;
  final String def;
  final String fam;
  final String pos;

  Entry({
    required this.root,
    required this.word,
    required this.morph,
    required this.def,
    required this.fam,
    required this.pos,
  });

  @override
  String toString() {
    return 'Entry(root: $root, word: $word, def: $def)';
  }
}

class WordAndEntries {
  final String word;
  final bool isPunctuation;
  final List<Entry> entries;

  WordAndEntries({
    required this.word,
    required this.isPunctuation,
    required this.entries,
  });

  @override
  String toString() {
    return 'WordandEntries($word [${entries.map((e) => e.toString()).join(',')}])';
  }
}

// Dictionary class
class ArEnDict {
  static late Map<String, List<Entry>> _dictPref;
  static late Map<String, List<Entry>> _dictStems;
  static late Map<String, List<Entry>> _dictSuff;
  static late Map<String, List<String>> _tableAB;
  static late Map<String, List<String>> _tableAC;
  static late Map<String, List<String>> _tableBC;
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;

    final datas = await Future.wait([
      _loadData('assets/data/dictprefixes'),
      _loadData('assets/data/dictstems'),
      _loadData('assets/data/dictsuffixes'),
      _loadData('assets/data/tableab'),
      _loadData('assets/data/tableac'),
      _loadData('assets/data/tablebc'),
    ]);

    final (dicts, tbls) = await Isolate.run(() async {
      final List<Map<String, List<Entry>>> dict = [];
      for (int i = 0; i < 3; i++) {
        final data = _decodeData(datas[i]);
        dict.add(_loadDict(data));
      }
      final List<Map<String, List<String>>> tbl = [];
      for (int i = 3; i < 6; i++) {
        final data = _decodeData(datas[i]);
        tbl.add(_loadTable(data));
      }
      // final List<Map<String, List<String>>> tbl = [];
      return (dict, tbl);
    });

    _dictPref = dicts[0];
    _dictStems = dicts[1];
    _dictSuff = dicts[2];

    _tableAB = tbls[0];
    _tableAC = tbls[1];
    _tableBC = tbls[2];
    _loaded = true;
  }

  // removes all the char other than arabic!
  // static String cleanWord(String w) {
  //   if (w.isEmpty) return '';

  //   var cw = '';
  //   for (int i = 0; i < w.length; i++) {
  //     if (uni2buck.containsKey(w[i])) {
  //       cw = '$cw${w[i]}';
  //     }
  //   }
  //   return cw;
  // }

  // words htat has thier non arabic char removed
  static List<Entry> __findWord(String w) {
    List<Entry> res = [];
    w = _transliterateAndClean(w);
    for (int i = 0; i < w.length; i++) {
      for (int j = i + 1; j <= w.length; j++) {
        // var c = dict(rSlice(w, 0, i), rSlice(w, i, j), rSlice(w, j, w.length));
        var c = _dict(
          w.substring(0, i),
          w.substring(i, j),
          w.substring(j, w.length),
        );
        res.addAll(c);
      }
    }
    return res;
  }

  // Method to find word
  static List<Entry> findWord(String? word) {
    if (!_loaded) return [];

    if (word == null || word.isEmpty) return [];
    return __findWord(word);
  }

  // Main dictionary search function
  static List<Entry> _dict(String pref, String stem, String suff) {
    // print('$pref, $stem, $suff');
    var prf = _dictPref[pref] ?? [];
    var stm = _dictStems[stem] ?? [];
    var suf = _dictSuff[suff] ?? [];
    List<Entry> res = [];

    for (var p in prf) {
      for (var s in stm) {
        for (var su in suf) {
          if (!_obeysGrammer(p.morph, s.morph, su.morph)) {
            continue;
          }

          var entry = Entry(
            root: _deTransliterate(s.root),
            word: _deTransliterate(p.word + s.word + su.word),
            def: _formatDef(p, s, su),
            fam: s.fam,
            pos: s.pos,
            morph: '',
          );

          res.add(entry);
        }
      }
    }
    return res;
  }

  // Grammar check
  static bool _obeysGrammer(String pref, String stem, String suff) {
    // return tableAB[pref]?.contains(stem) ??
    //     false && tableBC[stem]!.contains(suff) ??
    //     false && tableAC[pref]?.contains(suff) ??
    //     false;
    if (!(_tableAB[pref]?.contains(stem) ?? false)) {
      return false;
    }
    if (!(_tableBC[stem]?.contains(suff) ?? true)) {
      return false;
    }
    if (!(_tableAC[pref]?.contains(suff) ?? true)) {
      return false;
    }
    return true;
  }

  // Format the definition
  static String _formatDef(Entry pre, Entry stem, Entry suf) {
    String res = '';
    if (pre.def.isNotEmpty) {
      var seg = pre.def.split('<pos>');
      res += "[${seg[0].trim()}] ";
    }

    var def = '';
    if (stem.def.isNotEmpty) {
      var parts = stem.def.split('<pos>');
      def = parts[0].trim().replaceAll(';', ', ');
    }

    if (suf.def.isNotEmpty) {
      var subDef = suf.def.split("<pos>")[0].trim();

      if (subDef.contains("<verb>")) {
        var parts = subDef.split("<verb>");
        res += '[${parts[0].trim()}] $def';
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          res += ' [${parts[1].trim()}]';
        }
      } else {
        res += '$def [$subDef]';
      }
    } else {
      res += def;
    }
    return res;
  }

  // Load a dictionary file into a map
  static Map<String, List<Entry>> _loadDict(String fileContent) {
    var lines = LineSplitter.split(fileContent);
    final Map<String, List<Entry>> dict = {};

    String root = '';
    String family = '';
    for (var line in lines) {
      if (line.trim() == ';') {
        root = '';
        family = '';
      } else if (line.startsWith(';--- ')) {
        root = line.split(' ')[1];
      } else if (line.startsWith('; form')) {
        family = line.split(' ')[2];
      } else if (!line.startsWith(';') && line.isNotEmpty) {
        var parts = line.split('\t');
        var entry = Entry(
          root: root,
          word: parts[1],
          morph: parts[2],
          def: parts[3],
          fam: family,
          pos: '',
        );
        dict[parts[0]] ??= [];
        dict[parts[0]]?.add(entry);
      }
    }
    return dict;
  }

  // Load a table file into a map
  static Map<String, List<String>> _loadTable(String fileContent) {
    var lines = LineSplitter.split(fileContent);
    final Map<String, List<String>> table = {};

    for (var line in lines) {
      var parts = line.split(' ');
      if (parts.length == 2) {
        table.putIfAbsent(parts[0], () => []).add(parts[1]);
      }
    }
    return table;
  }
}

// Transliterate function
// String _transliterate(String s) {
//   return s.split('').map((c) => buck2Uni[c] ?? c).join();
// }

// Remove nonAR and transliterate
// String _transliterateAndClean(String s) {
//   return s.split('').map((c) => uni2buck[c] ?? '').join();
// }
String _transliterateAndClean(String s) {
  final sb = StringBuffer();

  for (int i = 0; i < s.length; i++) {
    final mapped = uni2buck[s[i]];
    if (mapped != null) {
      sb.write(mapped);
    }
  }

  return sb.toString();
}

// Function to convert from Buckwheat to Unicode
// String _deTransliterate(String s) {
//   return s.split('').map((c) => buck2uni[c] ?? c).join();
// }
String _deTransliterate(String s) {
  final sb = StringBuffer();

  for (int i = 0; i < s.length; i++) {
    final mapped = buck2uni[s[i]];
    if (mapped != null) {
      sb.write(mapped);
    }
  }

  return sb.toString();
}

// Harakats (vowel markers in Arabic)
// const Set<String> _harakaats = {'a', 'u', 'i', 'F', 'N', 'K', '~', 'o'};

// const _harakatLookup = {
//   'a': true,
//   'u': true,
//   'i': true,
//   'F': true,
//   'N': true,
//   'K': true,
//   '~': true,
//   'o': true,
// };

const Map<String, String> buck2uni = {
  '\'': '\u0621', // hamza-on-the-line
  '|': '\u0622', // madda
  '>': '\u0623', // hamza-on-'alif
  '&': '\u0624', // hamza-on-waaw
  '<': '\u0625', // hamza-under-'alif
  '}': '\u0626', // hamza-on-yaa'
  'A': '\u0627', // bare 'alif
  'b': '\u0628', // baa'
  'p': '\u0629', // taa' marbuuTa
  't': '\u062A', // taa'
  'v': '\u062B', // thaa'
  'j': '\u062C', // jiim
  'H': '\u062D', // Haa'
  'x': '\u062E', // khaa'
  'd': '\u062F', // daal
  '*': '\u0630', // dhaal
  'r': '\u0631', // raa'
  'z': '\u0632', // zaay
  's': '\u0633', // siin
  '\$': '\u0634', // shiin
  'S': '\u0635', // Saad
  'D': '\u0636', // Daad
  'T': '\u0637', // Taa'
  'Z': '\u0638', // Zaa' (DHaa')
  'E': '\u0639', // cayn
  'g': '\u063A', // ghayn
  // '_': '\u0640', // taTwiil 'ـ' we don't need this!
  'f': '\u0641', // faa'
  'q': '\u0642', // qaaf
  'k': '\u0643', // kaaf
  'l': '\u0644', // laam
  'm': '\u0645', // miim
  'n': '\u0646', // nuun
  'h': '\u0647', // haa'
  'w': '\u0648', // waaw
  'Y': '\u0649', // 'alif maqSuura
  'y': '\u064A', // yaa'
  'F': '\u064B', // fatHatayn
  'N': '\u064C', // Dammatayn
  'K': '\u064D', // kasratayn
  'a': '\u064E', // fatHa
  'u': '\u064F', // Damma
  'i': '\u0650', // kasra
  '~': '\u0651', // shaddah
  'o': '\u0652', // sukuun
  '`': '\u0670', // dagger 'alif
  '{': '\u0671', // waSla
};

// harakas are removed
const Map<String, String> uni2buck = {
  '\u0621': '\'', // hamza-on-the-line
  '\u0622': '|', // madda
  '\u0623': '>', // hamza-on-'alif
  '\u0624': '&', // hamza-on-waaw
  '\u0625': '<', // hamza-under-'alif
  '\u0626': '}', // hamza-on-yaa'
  '\u0627': 'A', // bare 'alif
  '\u0628': 'b', // baa'
  '\u0629': 'p', // taa' marbuuTa
  '\u062A': 't', // taa'
  '\u062B': 'v', // thaa'
  '\u062C': 'j', // jiim
  '\u062D': 'H', // Haa'
  '\u062E': 'x', // khaa'
  '\u062F': 'd', // daal
  '\u0630': '*', // dhaal
  '\u0631': 'r', // raa'
  '\u0632': 'z', // zaay
  '\u0633': 's', // siin
  '\u0634': '\$', // shiin
  '\u0635': 'S', // Saad
  '\u0636': 'D', // Daad
  '\u0637': 'T', // Taa'
  '\u0638': 'Z', // Zaa' (DHaa')
  '\u0639': 'E', // cayn
  '\u063A': 'g', // ghayn
  '\u0641': 'f', // faa'
  '\u0642': 'q', // qaaf
  '\u0643': 'k', // kaaf
  '\u0644': 'l', // laam
  '\u0645': 'm', // miim
  '\u0646': 'n', // nuun
  '\u0647': 'h', // haa'
  '\u0648': 'w', // waaw
  '\u0649': 'Y', // 'alif maqSuura
  '\u064A': 'y', // yaa'
  // '\u064B': 'F', // fatHatayn
  // '\u064C': 'N', // Dammatayn
  // '\u064D': 'K', // kasratayn
  // '\u064E': 'a', // fatHa
  // '\u064F': 'u', // Damma
  // '\u0650': 'i', // kasra
  // '\u0651': '~', // shaddah
  // '\u0652': 'o', // sukuun
  '\u0670': '`', // dagger 'alif
  '\u0671': '{', // waSla
};
