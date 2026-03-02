// import 'dart:convert';
// import 'dart:isolate';

// import 'package:ara_dict/ar_en/ar_en.dart';


// class _Entry {
//   final String root;
//   final String word;
//   final String morph;
//   final String def;
//   final bool isVerb;
//   final String fam;
//   final String pos;

//   _Entry({
//     required this.root,
//     required this.word,
//     required this.morph,
//     required this.def,
//     required this.isVerb,
//     required this.fam,
//     required this.pos,
//   });

//   @override
//   String toString() {
//     return '_Entry(root: $root, word: $word, def: $def)';
//   }
// }

// class ArEnEngine {
//   // late Isolate _isolate;
//   late SendPort _sendPort;

//   Future<bool> init(List<ByteData> data) async {
//     final receivePort = ReceivePort();
//     // _isolate =
//     await Isolate.spawn(_entryPoint, receivePort.sendPort);
//     _sendPort = await receivePort.first as SendPort;

//     final replyPort = ReceivePort();
//     _sendPort.send((data, replyPort.sendPort));
//     final result = await replyPort.first as bool;
//     replyPort.close();

//     return result;

//     // return await receivePort.first as bool;
//   }

//   Future<List<ArEnEntry>> search(String words) async {
//     final response = ReceivePort();

//     _sendPort.send((words, response.sendPort));

//     final result = await response.first as List<ArEnEntry>;
//     response.close();
//     return result;
//   }
// }

// void _entryPoint(SendPort mainSendPort) async {
//   final port = ReceivePort();
//   mainSendPort.send(port.sendPort);

//   // Load everything here
//   final datas = await port.first as List<ByteData>;

//   mainSendPort.send(true);

//   await for (final message in port) {
//     final (String word, SendPort reply) = message;
//     final result = __findWord(
//       word,
//       dictPref,
//       dictStems,
//       dictSuff,
//       tableAB,
//       tableAC,
//       tableBC,
//     );
//     reply.send(result);
//   }
// }

// String _decodeData(ByteData data) {
//   return latin1.decode(data.buffer.asUint8List());
// }

// // Load a dictionary file into a map
// Map<String, List<_Entry>> _loadDict(String fileContent, _DictPos dp) {
//   var lines = LineSplitter.split(fileContent);
//   final Map<String, List<_Entry>> dict = {};

//   String root = '';
//   bool rootTranliterated = false;
//   String family = '';
//   for (var line in lines) {
//     if (line.trim() == ';') {
//       root = '';
//       rootTranliterated = false;
//       family = '';
//     } else if (line.startsWith(';--- ')) {
//       root = line.split(' ')[1];
//       rootTranliterated = false;
//     } else if (line.startsWith('; form')) {
//       family = line.split(' ')[2];
//     } else if (!line.startsWith(';') && line.isNotEmpty) {
//       final parts = line.split('\t');
//       final key = _bukToArabic(parts[0]);
//       // if (key.isEmpty) continue; // don't

//       if (root.isNotEmpty && !rootTranliterated) {
//         root = _bukToArabic(root);
//         rootTranliterated = true;
//       }
//       final word = _bukToArabic(parts[1]);
//       final (def, isVerb) = _formatDictDef(dp, parts[3]);

//       final e = _Entry(
//         root: root,
//         word: word,
//         morph: parts[2],
//         def: def,
//         isVerb: isVerb,
//         fam: family,
//         pos: '',
//       );
//       dict.putIfAbsent(key, () => []).add(e);
//     }
//   }
//   return dict;
// }

// // Load a table file into a map
// Map<String, List<String>> _loadTable(String fileContent) {
//   var lines = LineSplitter.split(fileContent);
//   final Map<String, List<String>> table = {};

//   for (var line in lines) {
//     if (line.isEmpty || line.startsWith(';')) continue;
//     var parts = line.split(' ');
//     if (parts.length == 2) {
//       table.putIfAbsent(parts[0], () => []).add(parts[1]);
//     }
//   }
//   return table;
// }

// String _bukToArabic(String s) {
//   final sb = StringBuffer();

//   for (int i = 0; i < s.length; i++) {
//     final mapped = _buck2uni[s[i]];

//     if (mapped != null) {
//       sb.write(mapped);
//     } else {
//       // if (kDebugMode) debugPrint('${s[i]} is not in buf2uni');
//       sb.write(s[i]);
//     }
//   }

//   return sb.toString();
// }

// const Map<String, String> _buck2uni = {
//   '\'': '\u0621', // hamza-on-the-line
//   '|': '\u0622', // madda
//   '>': '\u0623', // hamza-on-'alif
//   '&': '\u0624', // hamza-on-waaw
//   '<': '\u0625', // hamza-under-'alif
//   '}': '\u0626', // hamza-on-yaa'
//   'A': '\u0627', // bare 'alif
//   'b': '\u0628', // baa'
//   'p': '\u0629', // taa' marbuuTa
//   't': '\u062A', // taa'
//   'v': '\u062B', // thaa'
//   'j': '\u062C', // jiim
//   'H': '\u062D', // Haa'
//   'x': '\u062E', // khaa'
//   'd': '\u062F', // daal
//   '*': '\u0630', // dhaal
//   'r': '\u0631', // raa'
//   'z': '\u0632', // zaay
//   's': '\u0633', // siin
//   '\$': '\u0634', // shiin
//   'S': '\u0635', // Saad
//   'D': '\u0636', // Daad
//   'T': '\u0637', // Taa'
//   'Z': '\u0638', // Zaa' (DHaa')
//   'E': '\u0639', // cayn
//   'g': '\u063A', // ghayn
//   // '_': '\u0640', // taTwiil 'ـ' we don't need this!
//   'f': '\u0641', // faa'
//   'q': '\u0642', // qaaf
//   'k': '\u0643', // kaaf
//   'l': '\u0644', // laam
//   'm': '\u0645', // miim
//   'n': '\u0646', // nuun
//   'h': '\u0647', // haa'
//   'w': '\u0648', // waaw
//   'Y': '\u0649', // 'alif maqSuura
//   'y': '\u064A', // yaa'
//   'F': '\u064B', // fatHatayn
//   'N': '\u064C', // Dammatayn
//   'K': '\u064D', // kasratayn
//   'a': '\u064E', // fatHa
//   'u': '\u064F', // Damma
//   'i': '\u0650', // kasra
//   '~': '\u0651', // shaddah
//   'o': '\u0652', // sukuun
//   '`': '\u0670', // dagger 'alif
//   '{': '\u0671', // waSla
//   'I': '\u0625',
//   'O': '\u0623',
//   'W': '\u0624',
// };

// (String, bool) _formatDictDef(_DictPos dp, String def) {
//   def = def.trim();
//   if (def.isEmpty) return ('', false);
//   switch (dp) {
//     case _DictPos.pre:
//       final res = "[${def.split('<pos>')[0].trim()}] ";
//       return (res, false);

//     case _DictPos.def:
//       final res = def.split('<pos>')[0].trim().replaceAll(';', ', ');
//       return (res, false);

//     case _DictPos.sfuff:
//       final res = StringBuffer();
//       var subDef = def.split("<pos>")[0].trim();
//       if (subDef.contains("<verb>")) {
//         var parts = subDef.split("<verb>");
//         res.write('[${parts[0].trim()}] ');
//         if (parts.length > 1 && parts[1].trim().isNotEmpty) {
//           res.write('<verb> [${parts[1].trim()}]');
//         }
//         return (res.toString(), true);
//       }
//       res.write(' [$subDef]');
//       return (res.toString(), false);
//   }
// }

// enum _DictPos {
//   pre, // prefix
//   def, // defenition
//   sfuff, // suffix
// }

// // _DictPos _indexToDictPos(int i) {
// //   switch (i) {
// //     case 0:
// //       return _DictPos.pre;
// //     case 1:
// //       return _DictPos.def;
// //     case 2:
// //       return _DictPos.sfuff;
// //   }
// //   throw 'No such indeex';
// // }

// List<ArEnEntry> __findWord(
//   String words,
//   Map<String, List<_Entry>> dictPref,
//   Map<String, List<_Entry>> dictStems,
//   Map<String, List<_Entry>> dictSuff,
//   Map<String, List<String>> tableAB,
//   Map<String, List<String>> tableAC,
//   Map<String, List<String>> tableBC,
// ) {
//   final List<ArEnEntry> res = [];

//   for (final w in words.split("_")) {
//     if (w.isEmpty) continue;
//     for (int i = 0; i < w.length; i++) {
//       for (int j = i + 1; j <= w.length; j++) {
//         final pref = w.substring(0, i);
//         final prf = dictPref[pref];
//         if (prf == null || prf.isEmpty) continue;

//         final stem = w.substring(i, j);
//         final stm = dictStems[stem];
//         if (stm == null || stm.isEmpty) continue;

//         final suff = w.substring(j, w.length);
//         final suf = dictSuff[suff];
//         if (suf == null || suf.isEmpty) continue;

//         for (final p in prf) {
//           for (final s in stm) {
//             for (final su in suf) {
//               if (!(tableAB[pref]?.contains(stem) ?? false)) continue;
//               if (tableBC[stem]?.contains(suff) == false) continue;
//               if (tableAC[pref]?.contains(suff) == false) continue;

//               final r = ArEnEntry(
//                 root: s.root,
//                 word: p.word + s.word + su.word,
//                 def: _formatDef(p.def, s.def, su.def, su.isVerb),
//               );
//               res.add(r);
//             }
//           }
//         }
//       }
//     }
//   }
//   return res;
// }

// String _formatDef(String pre, String stem, String suf, bool isVerb) {
//   final res = StringBuffer(pre);
//   if (isVerb) {
//     res.write(suf.replaceFirst('<verb>', stem));
//   } else {
//     res.write(stem);
//     res.write(suf);
//   }
//   return res.toString();
// }
