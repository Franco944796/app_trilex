import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../course/vocab_screen.dart';
import '../reading/reading.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'review_screen.dart';
import 'srs.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});
  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final meanings = <String, String>{};
  Set<String> known = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    appVocabIds().then((v) {
      if (mounted) setState(() => known = v);
    });
  }

  // significado en el idioma actual (las palabras pueden haberse guardado en otro)
  Future<void> _translate() async {
    reading.clearGlossary();
    for (final x in progress.words) {
      final w = (x as Map).cast<String, dynamic>();
      if (w['lg'] == i18n.lang && str(w['tr']).isNotEmpty) {
        meanings[str(w['w'])] = str(w['tr']);
      } else if (i18n.isEs && str(w['es']).isNotEmpty) {
        meanings[str(w['w'])] = str(w['es']);
      } else {
        final r = await reading.lookup(str(w['w']));
        meanings[str(w['w'])] = r?.tr ?? str(w['es']);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _go(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final words = progress.words;
    final missing = words.any((x) => !meanings.containsKey(str((x as Map)['w'])));
    if (missing && !_busy) {
      _busy = true;
      Future.microtask(_translate).whenComplete(() => _busy = false);
    }
    final due = dueReadingWords + dueCourseWords(known);
    return PageList(children: [
      PageHeader(kicker: tr('navWords'), title: tr('myWordsTitle'), lede: tr('wordsLede')),
      Panel(
        color: Tx.blueSoft,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Kicker(tr('rvH'), color: Tx.blue),
          const SizedBox(height: 4),
          Text(due > 0 ? tr('pendingN', {'n': due}) : tr('rvNone'), style: TextStyle(color: Tx.ink)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: due == 0 ? null : () => _go(const WordReviewScreen()), child: Text(tr('rvBtn', {'n': due}))),
            OutlinedButton(onPressed: () => _go(const VocabScreen()), child: Text(tr('vocabT'))),
          ]),
        ]),
      ),
      const SizedBox(height: 18),
      if (words.isEmpty) Text(tr('noWords'), style: TextStyle(color: Tx.muted)),
      for (var i = 0; i < words.length; i++) _row(i, (words[i] as Map).cast<String, dynamic>()),
    ]);
  }

  Widget _row(int i, Json w) {
    final box = (w['box'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Tx.line))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(str(w['w']), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink))),
              const SizedBox(width: 8),
              // nivel de repaso: 0 = nueva, 6 = ya aprendida
              for (var k = 0; k < srsIntervals.length; k++)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: k < box ? Tx.blue : null,
                    border: Border.all(color: Tx.blue),
                  ),
                ),
            ]),
            Text(meanings[str(w['w'])] ?? ''),
            if (str(w['ctx']).isNotEmpty)
              Text(str(w['ctx']), style: TextStyle(fontSize: 12.5, color: Tx.muted, fontStyle: FontStyle.italic)),
          ]),
        ),
        SayButton(str(w['w'])),
        IconButton(
          tooltip: tr('delete'),
          icon: Icon(Icons.delete_outline, size: 20, color: Tx.muted),
          onPressed: () {
            progress.words.removeAt(i);
            progress.save();
            setState(() {});
          },
        ),
      ]),
    );
  }
}
