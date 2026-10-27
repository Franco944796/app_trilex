import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';

/// Partes sin contraer de una palabra: «I'm» y «I am» valen lo mismo (igual que la web).
List<String> wordParts(String w) {
  final x = w.toLowerCase().replaceAll(RegExp('[’‘]'), "'").replaceAll(RegExp(r"[^a-z0-9']"), '');
  const irr = {
    "won't": ['will', 'not'],
    "can't": ['can', 'not'],
    "shan't": ['shall', 'not'],
    'cannot': ['can', 'not'],
  };
  if (irr[x] != null) return irr[x]!;
  final m = RegExp(r"^(.+?)(n't|'m|'re|'ve|'ll|'d|'s)$").firstMatch(x);
  if (m != null) {
    const ends = {"n't": 'not', "'m": 'am', "'re": 'are', "'ve": 'have', "'ll": 'will', "'d": 'would'};
    final end = ends[m[2]];
    if (end != null) return [m[1]!, end];
    const pron = {'it', 'he', 'she', 'that', 'there', 'here', 'what', 'where', 'who', 'how', 'this'};
    if (pron.contains(m[1])) return [m[1]!, 'is'];
  }
  final k = x.replaceAll("'", '');
  return k.isEmpty ? const [] : [k];
}

typedef DgWord = ({String w, List<String> ks});

List<DgWord> dgWords(String t) => [
      for (final w in t.split(RegExp(r'\s+')))
        if (wordParts(w).isNotEmpty) (w: w, ks: wordParts(w)),
    ];

/// Qué palabras del original aparecen, en orden, en la versión escrita (subsecuencia común más
/// larga sobre las partes; una palabra cuenta si están todas sus partes).
List<bool> compareWords(List<DgWord> orig, List<DgWord> mine) {
  final a = [for (final x in orig) ...x.ks], b = [for (final x in mine) ...x.ks];
  final owner = [for (var i = 0; i < orig.length; i++) ...List.filled(orig[i].ks.length, i)];
  final m = a.length, n = b.length;
  final l = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (var x = m - 1; x >= 0; x--) {
    for (var y = n - 1; y >= 0; y--) {
      l[x][y] = a[x] == b[y] ? l[x + 1][y + 1] + 1 : (l[x + 1][y] >= l[x][y + 1] ? l[x + 1][y] : l[x][y + 1]);
    }
  }
  final ok = List.filled(orig.length, true);
  var x = 0, y = 0;
  final hit = List.filled(m, false);
  while (x < m && y < n) {
    if (a[x] == b[y]) {
      hit[x] = true;
      x++;
      y++;
    } else if (l[x + 1][y] >= l[x][y + 1]) {
      x++;
    } else {
      y++;
    }
  }
  for (var k = 0; k < m; k++) {
    if (!hit[k]) ok[owner[k]] = false;
  }
  return ok;
}

class DictoScreen extends StatefulWidget {
  const DictoScreen({super.key, required this.unitId});
  final String unitId;
  @override
  State<DictoScreen> createState() => _DictoScreenState();
}

class _DictoScreenState extends State<DictoScreen> {
  final draft = TextEditingController();
  int plays = 0;
  String warn = '';
  List<bool>? hits;

  String get text => course.dictoglossOf(widget.unitId) ?? '';

  @override
  void dispose() {
    speech.stop();
    draft.dispose();
    super.dispose();
  }

  void _compare() {
    final mine = dgWords(draft.text);
    if (mine.length < 5) {
      setState(() => warn = tr('dgNeed'));
      return;
    }
    final h = compareWords(dgWords(text), mine);
    final p = h.where((x) => x).length / h.length;
    final best = (progress.course['dicto'] as Map?) ?? {};
    progress.course['dicto'] = best;
    if (p > ((best[widget.unitId] as num?) ?? 0)) best[widget.unitId] = p;
    progress.markToday('produce');
    setState(() {
      warn = '';
      hits = h;
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = course.unitById(widget.unitId);
    final orig = dgWords(text);
    final h = hits;
    final p = h == null ? 0.0 : h.where((x) => x).length / h.length;
    return Scaffold(
      appBar: AppBar(title: Text(tr('dgT'))),
      body: PageList(children: [
        PageHeader(
          kicker: u == null ? tr('dgT') : '${u['cefr']} · ${tr('unitN', {'n': u['order']})} · ${u['title_target']}',
          title: tr('dgT'),
          lede: tr('dgLede'),
        ),
        CardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton(
                onPressed: () {
                  speech.say(text);
                  setState(() => plays++);
                },
                child: Text('🔊 ${tr('dgListen', {'n': plays})}'),
              ),
              OutlinedButton(onPressed: () => speech.say(text, rate: 0.6), child: Text('🐢 ${tr('speedSlow')}')),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: draft,
              minLines: 5,
              maxLines: 12,
              decoration: InputDecoration(hintText: tr('dgPh')),
            ),
            if (warn.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(warn, style: TextStyle(color: Tx.bad))),
            const SizedBox(height: 12),
            FilledButton(onPressed: _compare, child: Text(tr('dgCompare'))),
          ]),
        ),
        if (h != null) ...[
          const SizedBox(height: 16),
          Panel(
            color: p >= 0.7 ? Tx.blueSoft : Tx.rustSoft,
            child: Row(children: [
              Text(pct(p), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Tx.ink)),
              const SizedBox(width: 12),
              Expanded(child: Text(tr('dgScore'))),
            ]),
          ),
          const SizedBox(height: 12),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                TextSpan(children: [
                  for (var i = 0; i < orig.length; i++)
                    TextSpan(
                      text: '${orig[i].w} ',
                      style: h[i]
                          ? null
                          : TextStyle(
                              color: Tx.bad,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.wavy,
                              decorationColor: Tx.bad,
                            ),
                    ),
                ]),
                style: TextStyle(fontFamily: Tx.serif, fontSize: 17, height: 1.7, color: Tx.readerText),
              ),
              const SizedBox(height: 8),
              Text(tr('dgLegend'), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => setState(() {
                  draft.clear();
                  plays = 0;
                  hits = null;
                }),
                child: Text(tr('restart')),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
