import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'reading_home.dart';

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
