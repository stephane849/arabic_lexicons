class WordEntry {
  final String ar;
  final String nTk;
  final String cl;

  const WordEntry({required this.ar, required this.cl, required this.nTk});
}

typedef PeraEntry = List<WordEntry>;

typedef PeraEntries = List<PeraEntry>;
