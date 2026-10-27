import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../course/course.dart';
import '../reading/reading.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'srs.dart';

typedef _Card = ({String kind, Map item, String answer, String meaning, String hint, String ipa, String example});

/// Repaso escrito: se ve el significado (y la oración con un hueco) y se escribe la palabra en
/// inglés. Recordar produciendo retiene más que reconocer y marcar «la sabía».
class WordReviewScreen extends StatefulWidget {
  const WordReviewScreen({super.key});
  @override
  State<WordReviewScreen> createState() => _WordReviewScreenState();
}

class _WordReviewScreenState extends State<WordReviewScreen> {
  final cards = <_Card>[];
  final input = TextEditingController();
  final focus = FocusNode();
  int i = 0, ok = 0, before = 0;
  bool loaded = false;
  bool? good;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  static String _gap(String sentence, String word) {
    if (sentence.isEmpty || word.contains('/')) return '';
    final re = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
    return re.hasMatch(sentence) ? sentence.replaceFirst(re, '_____') : '';
  }

  Future<void> _load() async {
    reading.clearGlossary();
    for (final x in progress.words.whereType<Map>().where(readingWordDue)) {
      final w = str(x['w']);
      var m = x['lg'] == i18n.lang ? str(x['tr']) : (i18n.isEs ? str(x['es']) : '');
      if (m.isEmpty) m = (await reading.lookup(w))?.tr ?? str(x['tr']);
      cards.add((kind: 'r', item: x, answer: w, meaning: m, hint: _gap(str(x['ctx']), w), ipa: '', example: str(x['ctx'])));
    }
    final vocab = <String, Json>{};
    for (final lv in course.ready) {
      final v = await content.obj('vocab/${str(lv['cefr']).toLowerCase()}.json');
      for (final w in jsonList(v['items'])) {
        vocab[str(w['id'])] = w;
      }
    }
    final today = dayNumber();
    for (final e in progress.srs.entries) {
      final w = vocab[e.key];
      if (w == null || (((e.value as Map)['due'] as num?) ?? 0) > today) continue;
      final lemma = str(w['lemma']);
      cards.add((
        kind: 'c',
        item: e.value as Map,
        answer: lemma,
        meaning: course.meaning(w),
        hint: _gap(str(w['example']), lemma),
        ipa: str(w['ipa']),
        example: str(w['example']),
      ));
    }
    cards.shuffle();
    if (mounted) setState(() => loaded = true);
  }

  void _check() {
    if (input.text.trim().isEmpty || good != null) return;
    final c = cards[i];
    final right = c.kind == 'r' ? normWord(input.text) == normWord(c.answer) : cardMatches(c.answer, input.text);
    before = ((c.item['box'] as num?) ?? 0).toInt();
    grade(c.item, before, right);
    if (c.kind == 'c' && !right) c.item['lapses'] = ((c.item['lapses'] as num?) ?? 0) + 1;
    if (right) ok++;
    progress.save();
    speech.say(c.answer);
    setState(() => good = right);
  }

  void _typo() {
    final c = cards[i];
    grade(c.item, before, true);
    if (c.kind == 'c') c.item['lapses'] = (((c.item['lapses'] as num?) ?? 1) - 1).clamp(0, 999);
    ok++;
    progress.save();
    _next();
  }

  void _next() {
    input.clear();
    setState(() {
      i++;
      good = null;
    });
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (i >= cards.length) {
      if (cards.isNotEmpty) progress.markToday('review');
      body = PageList(children: [
        PageHeader(
          kicker: tr('rvH'),
          title: tr('reviewDone'),
          lede: cards.isEmpty ? tr('rvNone') : tr('rvResult', {'o': ok, 'n': cards.length}),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('back'))),
        ),
      ]);
    } else {
      final c = cards[i];
      body = PageList(children: [
        Kicker('${tr('rvH')} · ${i + 1}/${cards.length}', color: Tx.blue),
        const SizedBox(height: 10),
        ProgressLine(i / cards.length),
        const SizedBox(height: 18),
        CardBox(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('cardHow'), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
            const SizedBox(height: 6),
            Text(c.meaning.isEmpty ? '—' : c.meaning, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Tx.ink)),
            if (c.hint.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(c.hint, style: TextStyle(color: Tx.muted, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: input,
              focusNode: focus,
              autofocus: true,
              enabled: good == null,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _check(),
              decoration: InputDecoration(hintText: tr('rvPh')),
            ),
            const SizedBox(height: 12),
            if (good == null)
              FilledButton(onPressed: _check, child: Text(tr('check')))
            else ...[
              Panel(
                color: good! ? Tx.okSoft : Tx.badSoft,
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${good! ? tr('correctEx') : tr('answerIs')} ', style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: c.answer, style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                        if (c.ipa.isNotEmpty) TextSpan(text: '  ${c.ipa}', style: TextStyle(fontFamily: Tx.mono, color: Tx.muted)),
                      ])),
                    ),
                    SayButton(c.answer),
                  ]),
                  if (c.example.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(c.example, style: TextStyle(fontSize: 13, color: Tx.muted, fontStyle: FontStyle.italic)),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (!good!) OutlinedButton(onPressed: _typo, child: Text(tr('rvTypo'))),
                FilledButton(onPressed: _next, child: Text(tr('rvNext'))),
              ]),
            ],
          ]),
        ),
      ]);
    }
    return Scaffold(appBar: AppBar(title: Text(tr('rvH'))), body: body);
  }
}

/// Ids del vocabulario de los niveles de la app (para no contar palabras de A1–A2 del repaso).
Future<Set<String>> appVocabIds() async {
  final ids = <String>{};
  for (final lv in course.ready) {
    final v = await content.obj('vocab/${str(lv['cefr']).toLowerCase()}.json');
    for (final w in jsonList(v['items'])) {
      ids.add(str(w['id']));
    }
  }
  return ids;
}
