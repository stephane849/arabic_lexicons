import 'package:flutter/services.dart';
Future<ByteData> loadData(String path) async {
  return await rootBundle.load(path);
}

String bukToArabic(String s) {
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
