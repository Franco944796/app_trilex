import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'reading.dart';
import 'reading_home.dart';

class WordsTab extends StatefulWidget {
  const WordsTab({super.key});
  @override
  State<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<WordsTab> {
  final meanings = <String, String>{};

  // significado en el idioma actual (las palabras pueden haberse guardado en otro)
  Future<void> _translate() async {
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

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final words = progress.words;
    final missing = words.any((x) => !meanings.containsKey(str((x as Map)['w'])));
    if (missing && !_busy) {
      _busy = true;
      Future.microtask(_translate).whenComplete(() => _busy = false);
    }
    return PageList(children: [
      PageHeader(
        kicker: tr('selfK'),
        title: tr('myWordsTitle'),
        lede: words.isEmpty ? tr('noWords') : tr('myWordsNote', {'n': words.length}),
      ),
      for (var i = 0; i < words.length; i++) _row(i, (words[i] as Map).cast<String, dynamic>()),
    ]);
  }

  Widget _row(int i, Json w) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Tx.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(str(w['w']), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
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

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});
  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  @override
  Widget build(BuildContext context) {
    int last(Map d) => jsonList(d['marks']).fold(0, (a, m) => (m['at'] as num? ?? 0) > a ? (m['at'] as num).toInt() : a);
    final ids = progress.notes.keys.toList()
      ..sort((a, b) => last(progress.notes[b] as Map).compareTo(last(progress.notes[a] as Map)));
    return PageList(children: [
      PageHeader(kicker: tr('selfK'), title: tr('myNotesTitle'), lede: ids.isEmpty ? tr('noNotes') : tr('myNotesNote')),
      for (final id in ids) _doc((progress.notes[id] as Map).cast<String, dynamic>()),
    ]);
  }

  Future<void> _open(Json d) async {
    final page = readerFor(str(d['href']));
    if (page == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Widget _doc(Json d) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Kicker(str(d['level']), color: Tx.blue),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _open(d),
            child: Text(str(d['title']), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
          ),
          const SizedBox(height: 8),
          if (str(d['general']).isNotEmpty) ...[
            Panel(padding: const EdgeInsets.all(12), child: Text(str(d['general']))),
            const SizedBox(height: 8),
          ],
          for (final m in jsonList(d['marks']))
            GestureDetector(
              onTap: () => _open(d),
              child: MarkBubble(
                color: str(m['color']),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('«${str(m['quote'])}»', style: TextStyle(fontFamily: Tx.serif, fontStyle: FontStyle.italic, color: Tx.ink)),
                  if (str(m['note']).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(str(m['note']))),
                ]),
              ),
            ),
        ]),
      );
}
