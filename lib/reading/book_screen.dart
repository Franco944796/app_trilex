import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'reader_screen.dart';
import 'reading.dart';
import 'reading_home.dart';

/// Ficha de un libro: sinopsis, seguir leyendo, descargar el PDF y lista de capítulos.
class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.id});
  final String id;
  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  Json? book, meta;

  @override
  void initState() {
    super.initState();
    () async {
      final b = await content.obj('reading/books/${widget.id}/book.json');
      final ix = await reading.index();
      if (!mounted) return;
      setState(() {
        book = b;
        meta = jsonList(ix['books']).firstWhere((x) => x['id'] == widget.id, orElse: () => <String, dynamic>{});
      });
    }();
  }

  Future<void> _open(int n) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen.chapter(widget.id, n)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final b = book;
    if (b == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final st = progress.books[widget.id] as Map?;
    final next = (st?['last'] as num?)?.toInt() ?? 1;
    final chapters = jsonList(b['chapters']);
    final blurb = (b['blurb'] as Map?) ?? const {};
    final hours = (b['hours'] as num?) ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(tr('tabBooks'))),
      body: PageList(children: [
        PageHeader(kicker: '${tr('tabBooks')} · ${b['level']}', title: str(b['title']), lede: str(blurb[i18n.lang] ?? blurb['en'])),
        Text(
          '${b['author']} · ${b['year']} · ${tr('wordsN', {'n': b['words']})} · '
          '${hours >= 1 ? tr('hoursReading', {'n': hours}) : tr('minN', {'n': ((b['words'] as num) / 150).round()})}',
          style: TextStyle(color: Tx.muted),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(
            onPressed: () => _open(next),
            child: Text(st?['last'] != null ? tr('continueReading', {'n': next}) : tr('startReading')),
          ),
          if (meta?['pdf_kb'] != null)
            OutlinedButton(
              onPressed: () => openBookPdf(widget.id),
              child: Text('${tr('downloadPdf')} · ${pdfSize(meta!['pdf_kb'] as num)}'),
            ),
        ]),
        if (meta?['pdf_kb'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(tr('pdfNote'), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
          ),
        SectionTitle(tr('chapters')),
        for (final c in chapters) _row(c, next, st),
        const SizedBox(height: 12),
        Text(tr('pdSource'), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
      ]),
    );
  }

  Widget _row(Json c, int next, Map? st) {
    final n = (c['n'] as num).toInt();
    final p = (st?['c'] as Map?)?['$n'] as Map?;
    final notes = progress.notes['b:${widget.id}:$n'] as Map?;
    final cur = n == next;
    return InkWell(
      onTap: () => _open(n),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: cur ? Tx.blueSoft : null,
          borderRadius: cur ? BorderRadius.circular(8) : null,
          border: cur ? null : Border(top: BorderSide(color: Tx.line)),
        ),
        child: Row(children: [
          SizedBox(width: 30, child: Text(pad2(n), style: TextStyle(fontFamily: Tx.mono, fontSize: 12, color: Tx.faint))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(str(c['title']), style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '${tr('wordsN', {'n': c['words']})} · ~${tr('minN', {'n': c['minutes']})} · ${tr('questionsN', {'n': c['questions']})}'
                '${notes != null ? ' · ${tr('notesN', {'n': (notes['marks'] as List).length})}' : ''}',
                style: TextStyle(fontSize: 12.5, color: Tx.muted),
              ),
            ]),
          ),
          if (p != null)
            Text('✓ ${pct(p['best'] as num)}', style: TextStyle(color: Tx.ok, fontWeight: FontWeight.w600, fontSize: 13))
          else
            Text(tr('readGo'), style: TextStyle(color: Tx.blue, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}
