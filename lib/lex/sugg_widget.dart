import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:flutter/material.dart';

Widget showSearchSugg(
  BuildContext context,
  TextEditingController controller,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
  VoidCallback onChange,
) {
  if (datas.sugg.isEmpty) return noRes(ts, datas.selectedWord);

  if (datas.suggDictSorted.isEmpty) {
    datas.suggDictSorted.add(datas.selectedDict);
    for (final d in allDictsExpeptArEn) {
      if (d != datas.selectedDict && datas.sugg[d] != null) {
        datas.suggDictSorted.add(d);
      }
    }
  }

  return Directionality(
    textDirection: TextDirection.rtl,
    child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16),
      reverse: true,
      child: Column(
        children: datas.suggDictSorted.reversed
            .where(
              (d) =>
                  d == datas.selectedDict ||
                  (datas.sugg[d]?.isNotEmpty ?? false),
            )
            .map((d) {
              final Set<String> res = datas.sugg[d] ?? {};
              final bool isPrimary = d == datas.selectedDict;

              return Column(
                children: [
                  Divider(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 4,
                          // crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPrimary)
                              Icon(
                                Icons.star,
                                size: 14,
                                color: isPrimary ? cs.primary : null,
                              ),
                            Text(
                              d.ar,
                              style: ts.copyWith(
                                fontSize: (ts.fontSize ?? 14) * 0.8,
                                fontWeight: FontWeight.bold,
                                color: isPrimary ? cs.primary : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        res.isEmpty
                            ? Center(
                                child: Text(
                                  /* txt */ 'لا توجد نتائج في المعجم الحالي',
                                  style: ts.copyWith(
                                    fontSize: (ts.fontSize ?? 14) * 0.9,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: res.map((r) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: ActionChip(
                                        label: Text(
                                          r.replaceAll('_', ' '),
                                          textDirection: TextDirection.rtl,
                                          style: ts.copyWith(
                                            fontSize: (ts.fontSize ?? 14) * 0.9,
                                          ),
                                        ),
                                        onPressed: () {
                                          if (r != datas.selectedWord) {
                                            final wordSet = datas.words!.map((
                                              i,
                                            ) {
                                              if (i == datas.selectedWord)
                                                return r;
                                              return i;
                                            }).toSet();

                                            // bring the new word to the end
                                            wordSet.remove(r);
                                            wordSet.add(r);

                                            datas.words = wordSet.toList();

                                            controller.text = wordSet.join(' ');
                                            controller.selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset:
                                                        controller.text.length,
                                                  ),
                                                );
                                            datas.selectedWord = r;
                                          }

                                          // here we don't need to care about showing searchSuggestions
                                          if (datas.selectedDict != d) {
                                            datas.selectedDict = d;
                                            datas.suggDictSorted.clear();
                                          }
                                          datas.isShowingSugg = false;

                                          datas.loadResults(onChange);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              );
            })
            .toList(),
      ),
    ),
  );
}

Widget s_howSearchSugg(
  BuildContext context,
  TextEditingController controller,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
  VoidCallback onChange,
) {
  if (datas.sugg.isEmpty) {
    return noRes(ts, datas.selectedWord);
  }

  final List<Dict> currDictSort = [];
  if (datas.sugg[datas.selectedDict] != null) {
    currDictSort.add(datas.selectedDict);
  }
  for (final d in allDictsExpeptArEn) {
    if (d != datas.selectedDict && datas.sugg[d] != null) {
      currDictSort.add(d);
    }
  }

  return ListView.separated(
    reverse: true,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    itemCount: currDictSort.length,
    separatorBuilder: (_, __) => Divider(
      height: 20,
      thickness: 0.5,
      color: cs.outlineVariant.withAlpha(120),
    ),
    itemBuilder: (context, index) {
      final d = currDictSort[index];
      final res = datas.sugg[d];
      final bool isPrimary = d == datas.selectedDict;

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dictionary label row ──────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? cs.primary.withAlpha(25)
                        : cs.surfaceContainerHighest.withAlpha(180),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPrimary
                          ? cs.primary.withAlpha(80)
                          : cs.outlineVariant.withAlpha(100),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPrimary) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: cs.primary.withAlpha(200),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        d.ar,
                        style: ts.copyWith(
                          fontSize: (ts.fontSize ?? 14) * 0.82,
                          fontWeight: FontWeight.w600,
                          color: isPrimary ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Suggestion chips ──────────────────────────────────────────
            if (res != null && res.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // reverse: true,
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: res.map((r) {
                    final displayText = r.replaceAll('_', ' ');
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _SuggChip(
                        label: displayText,
                        ts: ts,
                        cs: cs,
                        onTap: () {
                          final cleanR = r.split(' ').first;
                          datas.words = datas.words!.map((i) {
                            if (i == datas.selectedWord) return cleanR;
                            return i;
                          }).toList();
                          controller.text = datas.words!.join(' ');
                          datas.selectedWord = r;
                          datas.selectedDict = d;
                          datas.resetSugg();
                          datas.loadResults(onChange);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    },
  );
}

// ── Tappable suggestion chip with ink effect ──────────────────────────────────
class _SuggChip extends StatelessWidget {
  const _SuggChip({
    required this.label,
    required this.ts,
    required this.cs,
    required this.onTap,
  });

  final String label;
  final TextStyle ts;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: cs.primary.withAlpha(40),
        highlightColor: cs.primary.withAlpha(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withAlpha(15),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            style: ts.copyWith(
              fontSize: (ts.fontSize ?? 14) * 0.95,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
