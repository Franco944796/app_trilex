import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/content.dart';
import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'book_screen.dart';
import 'reader_screen.dart';
import 'reading.dart';
import 'words_notes.dart';

/// Autoaprendizaje: lecturas por nivel, libros completos, mis palabras y mis notas.
class ReadingHome extends StatelessWidget {
  const ReadingHome({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Column(children: [
          Material(
            color: Tx.bg,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Tx.ink,
              unselectedLabelColor: Tx.muted,
              indicatorColor: Tx.ink,
              labelStyle: const TextStyle(fontFamily: Tx.sans, fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(text: tr('tabTexts')),
                Tab(text: tr('tabBooks')),
                Tab(text: tr('tabWords')),
                Tab(text: tr('tabNotes')),
              ],
            ),
          ),
          const Divider(),
          const Expanded(child: TabBarView(children: [TextsTab(), BooksTab(), WordsTab(), NotesTab()])),
        ]),
      );
}

/// Abre un PDF de un libro en el navegador o el visor del teléfono.
Future<void> openBookPdf(String id) =>
    launchUrl(Uri.parse('${Content.baseUrl}reading/books/$id/$id.pdf'), mode: LaunchMode.externalApplication);

String pdfSize(num kb) => kb >= 1000 ? '${(kb / 1024).toStringAsFixed(1)} MB' : '$kb KB';

/// Lecturas graduadas por nivel.
class TextsTab extends StatefulWidget {
  const TextsTab({super.key});
  @override
  State<TextsTab> createState() => _TextsTabState();
}

class _TextsTabState extends State<TextsTab> {
  Json? ix;
  String level = 'A1';

  @override
  void initState() {
    super.initState();
    reading.index().then((v) {
      if (mounted) setState(() => ix = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ix == null) return const Center(child: CircularProgressIndicator());
    final texts = jsonList(ix!['texts']);
    final list = texts.where((t) => t['level'] == level).toList();
    int doneN(String l) => texts.where((t) => t['level'] == l && progress.texts[t['id']] != null).length;
    return PageList(children: [
      PageHeader(kicker: tr('selfK'), title: tr('readTitle'), lede: tr('introTexts')),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final l in strList(ix!['levels']))
          ChoiceChip(
            label: Text('$l  ${doneN(l)}/${texts.where((t) => t['level'] == l).length}'),
            selected: level == l,
            onSelected: (_) => setState(() => level = l),
          ),
      ]),
      const SizedBox(height: 14),
      for (var i = 0; i < list.length; i++) _card(list[i], i),
    ]);
  }

  Widget _card(Json t, int i) {
    final p = progress.texts[t['id']] as Map?;
    final notes = progress.notes['t:${t['id']}'] as Map?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen.text(str(t['id']))));
          if (mounted) setState(() {});
        },
        child: CardBox(
          borderColor: p != null ? Tx.doneLine : Tx.line,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker('${t['level']} · ${pad2(i + 1)}', color: Tx.blue),
            const SizedBox(height: 6),
            Text(str(t['title']), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
            Text('${i18n.isEs ? '${t['title_es']} · ' : ''}${i18n.topic(str(t['topic']))}', style: TextStyle(fontSize: 13, color: Tx.muted)),
            const SizedBox(height: 6),
            Text(
              '${tr('wordsN', {'n': t['words']})} · ${tr('minN', {'n': t['minutes']})} · ${tr('questionsN', {'n': t['questions']})}',
              style: TextStyle(fontSize: 13, color: Tx.muted),
            ),
            const SizedBox(height: 10),
            Row(children: [
              if (p != null)
                Text('${pct(p['best'] as num)} ${tr('bestScore')}', style: TextStyle(color: Tx.ok, fontWeight: FontWeight.w600))
              else
                Text(tr('readGo'), style: TextStyle(color: Tx.blue, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (notes != null) _badge(tr('notesN', {'n': (notes['marks'] as List).length})),
            ]),
          ]),
        ),
      ),
    );
  }
}

Widget _badge(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Tx.marks['yellow']![0], borderRadius: BorderRadius.circular(99)),
      child: Text(t, style: const TextStyle(fontFamily: Tx.mono, fontSize: 11)),
    );

/// Libros completos.
class BooksTab extends StatefulWidget {
  const BooksTab({super.key});
  @override
  State<BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<BooksTab> {
  Json? ix;

  @override
  void initState() {
    super.initState();
    reading.index().then((v) {
      if (mounted) setState(() => ix = v);
    });
  }

  String _dur(Json b) {
    final h = (b['hours'] as num?) ?? 0;
    return h >= 1 ? tr('hoursN', {'n': h}) : '~${tr('minN', {'n': ((b['words'] as num) / 150).round().clamp(5, 999)})}';
  }

  @override
  Widget build(BuildContext context) {
    if (ix == null) return const Center(child: CircularProgressIndicator());
    return PageList(children: [
      PageHeader(kicker: tr('selfK'), title: tr('readTitle'), lede: tr('introBooks')),
      for (final b in jsonList(ix!['books'])) _card(b),
    ]);
  }

  Widget _card(Json b) {
    final st = progress.books[b['id']] as Map?;
    final n = (b['chapters'] as num).toInt();
    final done = ((st?['c'] as Map?) ?? const {}).length;
    final last = st?['last'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookScreen(id: str(b['id']))));
              if (mounted) setState(() {});
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Kicker('${b['level']} · ${tr('chaptersN', {'n': n})}', color: Tx.blue),
              const SizedBox(height: 6),
              Text(str(b['title']), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
              Text('${b['author']} · ${b['year']}', style: TextStyle(fontSize: 13, color: Tx.muted)),
              const SizedBox(height: 6),
              Text('${_dur(b)} · ${tr('wordsN', {'n': b['words']})}', style: TextStyle(fontSize: 13, color: Tx.muted)),
              const SizedBox(height: 10),
              ProgressLine(n == 0 ? 0 : done / n),
              const SizedBox(height: 6),
              Text(
                done > 0 ? tr('chDone', {'d': done, 'n': n}) + (last != null ? tr('continueAt', {'n': last}) : '') : tr('notStarted'),
                style: TextStyle(fontSize: 12.5, color: Tx.muted),
              ),
            ]),
          ),
          Row(children: [
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookScreen(id: str(b['id'])))),
              child: Text(tr('readGo')),
            ),
            const Spacer(),
            if (b['pdf_kb'] != null)
              TextButton(
                onPressed: () => openBookPdf(str(b['id'])),
                child: Text('${tr('downloadPdf')} · ${pdfSize(b['pdf_kb'] as num)}'),
              ),
          ]),
        ]),
      ),
    );
  }
}

/// Abre un texto o un capítulo guardado como «#/texto/id» o «#/libro/id/n» (el enlace de la web).
Widget? readerFor(String href) {
  final p = href.replaceFirst('#/', '').split('/');
  if (p.length >= 2 && p[0] == 'texto') return ReaderScreen.text(p[1]);
  if (p.length >= 3 && p[0] == 'libro') return ReaderScreen.chapter(p[1], int.tryParse(p[2]) ?? 1);
  return null;
}
