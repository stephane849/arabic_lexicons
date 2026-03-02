import 'dart:convert';
import 'dart:isolate';

import 'package:ara_dict/utils.dart';
import 'package:flutter/services.dart';

class ArEnEntry {
  final String root;
  final String word;
  final String def;

  ArEnEntry({required this.root, required this.word, required this.def});
}

class _Entry {
  final String root;
  final String word;
  final String morph;
  final String def;
  final bool isVerb;
  final String fam;
  final String pos;

  _Entry({
    required this.root,
    required this.word,
    required this.morph,
    required this.def,
    required this.isVerb,
    required this.fam,
    required this.pos,
  });

  @override
  String toString() {
    return '_Entry(root: $root, word: $word, def: $def)';
  }
}

class _ArEnDictDatas {
  final Map<String, List<_Entry>> dictPref;
  final Map<String, List<_Entry>> dictStems;
  final Map<String, List<_Entry>> dictSuff;
  final Map<String, List<String>> tableAB;
  final Map<String, List<String>> tableAC;
  final Map<String, List<String>> tableBC;

  _ArEnDictDatas({
    required this.dictPref,
    required this.dictStems,
    required this.dictSuff,
    required this.tableAB,
    required this.tableAC,
    required this.tableBC,
  });
}

// Dictionary class
class ArEnDict {
  static late final _ArEnDictDatas _datas;
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;

    final datas = await Future.wait([
      _loadData('assets/data/ar_en/dictprefixes'),
      _loadData('assets/data/ar_en/dictstems'),
      _loadData('assets/data/ar_en/dictsuffixes'),
      _loadData('assets/data/ar_en/tableab'),
      _loadData('assets/data/ar_en/tableac'),
      _loadData('assets/data/ar_en/tablebc'),
    ]);

    final (dicts, tbls) = await Isolate.run(() async {
      final List<Map<String, List<_Entry>>> dict = [];
      for (int i = 0; i < 3; i++) {
        final data = _decodeData(datas[i]);
        dict.add(_loadDict(data, _indexToDictPos(i)));
        // print(dict.last.entries.map((v) => v.value.length).reduce((i,j) => i+j));
      }
      final List<Map<String, List<String>>> tbl = [];
      for (int i = 3; i < 6; i++) {
        final data = _decodeData(datas[i]);
        tbl.add(_loadTable(data));
        // print(tbl.last.entries.map((v) => v.value.length).reduce((i,j) => i+j));
      }
      // final List<Map<String, List<String>>> tbl = [];
      return (dict, tbl);
    });

    _datas = _ArEnDictDatas(
      dictPref: dicts[0],
      dictStems: dicts[1],
      dictSuff: dicts[2],
      tableAB: tbls[0],
      tableAC: tbls[1],
      tableBC: tbls[2],
    );

    print(_datas);
    _loaded = true;
  }

  // words htat has thier non arabic char removed
  // seperated by

  static final _cache = LruCache<String, List<ArEnEntry>>(200);

  // Method to find word
  static Future<List<ArEnEntry>> findWord(String? words) async {
    if (!_loaded) return [];

    if (words == null || words.isEmpty) return [];
    final c = _cache.get(words);
    if (c != null) return c;

    final datas = _datas;
    final res = await Isolate.run(() => __findWord(datas, words));
    _cache.put(words, res);

    return res;
  }

  // Load a dictionary file into a map
  static Map<String, List<_Entry>> _loadDict(String fileContent, _DictPos dp) {
    var lines = LineSplitter.split(fileContent);
    final Map<String, List<_Entry>> dict = {};

    String root = '';
    bool rootTranliterated = false;
    String family = '';
    for (var line in lines) {
      if (line.trim() == ';') {
        root = '';
        rootTranliterated = false;
        family = '';
      } else if (line.startsWith(';--- ')) {
        root = line.split(' ')[1];
        rootTranliterated = false;
      } else if (line.startsWith('; form')) {
        family = line.split(' ')[2];
      } else if (!line.startsWith(';') && line.isNotEmpty) {
        final parts = line.split('\t');
        final key = _bukToArabic(parts[0]);
        // if (key.isEmpty) continue; // don't

        if (root.isNotEmpty && !rootTranliterated) {
          root = _bukToArabic(root);
          rootTranliterated = true;
        }
        final word = _bukToArabic(parts[1]);
        final (def, isVerb) = _formatDictDef(dp, parts[3]);

        final e = _Entry(
          root: root,
          word: word,
          morph: parts[2],
          def: def,
          isVerb: isVerb,
          fam: family,
          pos: '',
        );
        dict.putIfAbsent(key, () => []).add(e);
      }
    }
    return dict;
  }

  // Load a table file into a map
  static Map<String, List<String>> _loadTable(String fileContent) {
    var lines = LineSplitter.split(fileContent);
    final Map<String, List<String>> table = {};

    for (var line in lines) {
      if (line.isEmpty || line.startsWith(';')) continue;
      var parts = line.split(' ');
      if (parts.length == 2) {
        table.putIfAbsent(parts[0], () => []).add(parts[1]);
      }
    }
    return table;
  }
}

String _bukToArabic(String s) {
  final sb = StringBuffer();

  for (int i = 0; i < s.length; i++) {
    final mapped = _buck2uni[s[i]];

    if (mapped != null) {
      sb.write(mapped);
    } else {
      // if (kDebugMode) debugPrint('${s[i]} is not in buf2uni');
      sb.write(s[i]);
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

const Map<String, String> _buck2uni = {
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
  'I': '\u0625',
  'O': '\u0623',
  'W': '\u0624',
};

// ('I':'u0625',
// ('O':'u0623',
// ('W':'u0624',

// harakas are removed
// const Map<String, String> uni2buck = {
//   '\u0621': '\'', // hamza-on-the-line
//   '\u0622': '|', // madda
//   '\u0623': '>', // hamza-on-'alif
//   '\u0624': '&', // hamza-on-waaw
//   '\u0625': '<', // hamza-under-'alif
//   '\u0626': '}', // hamza-on-yaa'
//   '\u0627': 'A', // bare 'alif
//   '\u0628': 'b', // baa'
//   '\u0629': 'p', // taa' marbuuTa
//   '\u062A': 't', // taa'
//   '\u062B': 'v', // thaa'
//   '\u062C': 'j', // jiim
//   '\u062D': 'H', // Haa'
//   '\u062E': 'x', // khaa'
//   '\u062F': 'd', // daal
//   '\u0630': '*', // dhaal
//   '\u0631': 'r', // raa'
//   '\u0632': 'z', // zaay
//   '\u0633': 's', // siin
//   '\u0634': '\$', // shiin
//   '\u0635': 'S', // Saad
//   '\u0636': 'D', // Daad
//   '\u0637': 'T', // Taa'
//   '\u0638': 'Z', // Zaa' (DHaa')
//   '\u0639': 'E', // cayn
//   '\u063A': 'g', // ghayn
//   '\u0641': 'f', // faa'
//   '\u0642': 'q', // qaaf
//   '\u0643': 'k', // kaaf
//   '\u0644': 'l', // laam
//   '\u0645': 'm', // miim
//   '\u0646': 'n', // nuun
//   '\u0647': 'h', // haa'
//   '\u0648': 'w', // waaw
//   '\u0649': 'Y', // 'alif maqSuura
//   '\u064A': 'y', // yaa'
//   // '\u064B': 'F', // fatHatayn
//   // '\u064C': 'N', // Dammatayn
//   // '\u064D': 'K', // kasratayn
//   // '\u064E': 'a', // fatHa
//   // '\u064F': 'u', // Damma
//   // '\u0650': 'i', // kasra
//   // '\u0651': '~', // shaddah
//   // '\u0652': 'o', // sukuun
//   '\u0670': '`', // dagger 'alif
//   '\u0671': '{', // waSla
// };

enum _DictPos {
  pre, // prefix
  def, // defenition
  sfuff, // suffix
}

_DictPos _indexToDictPos(int i) {
  switch (i) {
    case 0:
      return _DictPos.pre;
    case 1:
      return _DictPos.def;
    case 2:
      return _DictPos.sfuff;
  }
  throw 'No such indeex';
}

(String, bool) _formatDictDef(_DictPos dp, String def) {
  def = def.trim();
  if (def.isEmpty) return ('', false);
  switch (dp) {
    case _DictPos.pre:
      final res = "[${def.split('<pos>')[0].trim()}] ";
      return (res, false);

    case _DictPos.def:
      final res = def.split('<pos>')[0].trim().replaceAll(';', ', ');
      return (res, false);

    case _DictPos.sfuff:
      final res = StringBuffer();
      var subDef = def.split("<pos>")[0].trim();
      if (subDef.contains("<verb>")) {
        var parts = subDef.split("<verb>");
        res.write('[${parts[0].trim()}] ');
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          res.write('<verb> [${parts[1].trim()}]');
        }
        return (res.toString(), true);
      }
      res.write(' [$subDef]');
      return (res.toString(), false);
  }
}

Future<ByteData> _loadData(String path) async {
  return await rootBundle.load(path);
}

String _decodeData(ByteData data) {
  return latin1.decode(data.buffer.asUint8List());
}

List<ArEnEntry> __findWord(_ArEnDictDatas datas, String words) {
  final List<ArEnEntry> res = [];

  for (final w in words.split("_")) {
    if (w.isEmpty) continue;
    for (int i = 0; i < w.length; i++) {
      for (int j = i + 1; j <= w.length; j++) {
        final pref = w.substring(0, i);
        final prf = datas.dictPref[pref];
        if (prf == null || prf.isEmpty) continue;

        final stem = w.substring(i, j);
        final stm = datas.dictStems[stem];
        if (stm == null || stm.isEmpty) continue;

        final suff = w.substring(j, w.length);
        final suf = datas.dictSuff[suff];
        if (suf == null || suf.isEmpty) continue;

        for (final p in prf) {
          for (final s in stm) {
            for (final su in suf) {
              if (!_obeysGrammer(datas, p.morph, s.morph, su.morph)) {
                continue;
              }

              final r = ArEnEntry(
                root: s.root,
                word: p.word + s.word + su.word,
                def: _formatDef(p.def, s.def, su.def, su.isVerb),
              );
              res.add(r);
            }
          }
        }
      }
    }
  }
  return res;
}

bool _obeysGrammer(
  _ArEnDictDatas datas,
  String pref,
  String stem,
  String suff,
) {
  if (!(datas.tableAB[pref]?.contains(stem) ?? false)) return false;
  if (datas.tableBC[stem]?.contains(suff) == false) return false;
  if (datas.tableAC[pref]?.contains(suff) == false) return false;
  return true;
}

// Format the definition
String _formatDef(String pre, String stem, String suf, bool isVerb) {
  final res = StringBuffer(pre);
  if (isVerb) {
    res.write(suf.replaceFirst('<verb>', stem));
  } else {
    res.write(stem);
    res.write(suf);
  }
  return res.toString();
}
