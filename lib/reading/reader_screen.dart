import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'reading.dart';

class _Doc {
  _Doc({
    required this.id,
    required this.noteTitle,
    required this.href,
    required this.level,
    required this.kicker,
    required this.title,
    required this.sub,
    required this.blocks,
    required this.glossary,
    required this.questions,
    this.summary = '',
    this.task = '',
    this.prev,
    this.next,
    this.prevBest,
    required this.onScore,
  });
  final String id, noteTitle, href, level, kicker, title, sub, summary, task;
  final List<Json> blocks, glossary, questions;
  final Widget Function()? prev, next;
  final double? prevBest;
  final void Function(double score) onScore;
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen.text(this.id, {super.key}) : chapterN = null;
  const ReaderScreen.chapter(this.id, int n, {super.key}) : chapterN = n;
  final String id;
  final int? chapterN;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  _Doc? doc;
  Object? error;
  final scroll = ScrollController();
  final paraKeys = <GlobalKey>[];
  bool keywords = false;
  int? speaking;
  ({int p, int s})? rangeStart;
  final draft = TextEditingController();
  Map<String, String> glossTr = {};

  bool get isBook => widget.chapterN != null;

  @override
  void initState() {
    super.initState();
    _load().catchError((Object e) {
      if (mounted) setState(() => error = e);
    });
  }

  @override
  void dispose() {
    speech.stop();
    scroll.dispose();
    draft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ix = await reading.index();
    late _Doc d;
    if (!isBook) {
      final t = await content.obj('reading/texts/${widget.id}.json');
      final same = jsonList(ix['texts']).where((x) => x['level'] == t['level']).toList();
      final k = same.indexWhere((x) => x['id'] == widget.id);
      final best = (progress.texts[widget.id] as Map?)?['best'] as num?;
      d = _Doc(
        id: 't:${widget.id}',
        noteTitle: str(t['title']),
        href: '#/texto/${widget.id}',
        level: str(t['level']),
        kicker: '${tr('tabTexts')} · ${t['level']} · ${i18n.topic(str(t['topic']))}',
        title: str(t['title']),
        sub: '${i18n.isEs ? '${t['title_es']} · ' : ''}${tr('wordsN', {'n': t['words']})} · ~${tr('minN', {'n': t['minutes']})}',
        blocks: [for (final p in strList(t['paragraphs'])) {'t': 'p', 'text': p}],
        glossary: jsonList(t['glossary']),
        questions: jsonList(t['questions']),
        task: str(t['task']),
        prev: k > 0 ? () => ReaderScreen.text(str(same[k - 1]['id'])) : null,
        next: k >= 0 && k < same.length - 1 ? () => ReaderScreen.text(str(same[k + 1]['id'])) : null,
        prevBest: best?.toDouble(),
        onScore: (s) {
          final p = (progress.texts[widget.id] as Map?) ?? {};
          final b = ((p['best'] as num?) ?? 0).toDouble();
          progress.texts[widget.id] = {'best': s > b ? s : b, 'last': s, 'at': DateTime.now().millisecondsSinceEpoch};
          progress.save();
        },
      );
      draft.text = str(progress.drafts[d.id]);
    } else {
      final n = widget.chapterN!;
      final b = await content.obj('reading/books/${widget.id}/book.json');
      final c = await content.obj('reading/books/${widget.id}/ch-${pad2(n)}.json');
      final total = jsonList(b['chapters']).length;
      final st = _bookState();
      st['last'] = n;
      progress.save();
      final best = ((st['c'] as Map)['$n'] as Map?)?['best'] as num?;
      d = _Doc(
        id: 'b:${widget.id}:$n',
        noteTitle: '${b['title']} · $n. ${c['title']}',
        href: '#/libro/${widget.id}/$n',
        level: str(b['level']),
        kicker: '${b['title']} · ${tr('chapterOf', {'n': n, 'm': total})}',
        title: '$n. ${c['title']}',
        sub: '${b['author']} · ${tr('wordsN', {'n': c['words']})}',
        summary: i18n.isEs ? str(c['summary_es']) : '',
        blocks: jsonList(c['blocks']),
        glossary: jsonList(c['glossary']),
        questions: jsonList(c['questions']),
        prev: n > 1 ? () => ReaderScreen.chapter(widget.id, n - 1) : null,
        next: n < total ? () => ReaderScreen.chapter(widget.id, n + 1) : null,
        prevBest: best?.toDouble(),
        onScore: (s) {
          final st = _bookState();
          final cs = st['c'] as Map;
          final b = (((cs['$n'] as Map?)?['best'] as num?) ?? 0).toDouble();
          cs['$n'] = {'best': s > b ? s : b, 'at': DateTime.now().millisecondsSinceEpoch};
          if (n < total) st['last'] = n + 1;
          progress.save();
        },
      );
    }
    reading.setGlossary(d.glossary);
    final tr_ = <String, String>{};
    for (final g in d.glossary) {
      tr_[str(g['en'])] = await reading.glossMeaning(g);
    }
    paraKeys
      ..clear()
      ..addAll(List.generate(d.blocks.length, (_) => GlobalKey()));
    if (!mounted) return;
    setState(() {
      doc = d;
      glossTr = tr_;
    });
    if (isBook) _restorePosition();
  }

  Map _bookState() {
    final st = (progress.books[widget.id] as Map?) ?? {};
    progress.books[widget.id] = st;
    st['c'] = (st['c'] as Map?) ?? {};
    st['pos'] = (st['pos'] as Map?) ?? {};
    return st;
  }

  void _restorePosition() {
    final f = ((_bookState()['pos'] as Map)['${widget.chapterN}'] as num?)?.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (f != null && scroll.hasClients) {
        scroll.jumpTo((scroll.position.maxScrollExtent * f).clamp(0, scroll.position.maxScrollExtent).toDouble());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('resumed')), duration: const Duration(seconds: 2)));
      }
      scroll.addListener(_savePosition);
    });
  }

  int _lastPosSave = 0;
  void _savePosition() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPosSave < 800 || !scroll.hasClients || scroll.position.maxScrollExtent <= 0) return;
    _lastPosSave = now;
    (_bookState()['pos'] as Map)['${widget.chapterN}'] = double.parse((scroll.offset / scroll.position.maxScrollExtent).toStringAsFixed(3));
    progress.save();
  }

  Map? get notesDoc => progress.notes[doc!.id] as Map?;
  List<Json> get marks => jsonList(notesDoc?['marks']);

  Map _ensureNotes() {
    final d = doc!;
    final n = notesDoc ?? {'title': d.noteTitle, 'href': d.href, 'level': d.level, 'general': '', 'marks': <dynamic>[]};
    progress.notes[d.id] = n;
    return n;
  }

  void _tidyNotes() {
    final n = notesDoc;
    if (n != null && str(n['general']).isEmpty && (n['marks'] as List).isEmpty) progress.notes.remove(doc!.id);
  }

  String _text(int p) => str(doc!.blocks[p]['text']);

  void _addMark(List<Map<String, int>> ranges, String color, {bool openNote = false}) {
    final quote = [for (final r in ranges) _text(r['p']!).substring(r['s']!, r['e']!)].join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final m = {
      'id': 'm${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      'color': color,
      'quote': quote,
      'note': '',
      'at': DateTime.now().millisecondsSinceEpoch,
      'ranges': ranges,
    };
    (_ensureNotes()['marks'] as List).add(m);
    progress.save();
    setState(() {});
    if (openNote) _openNotes(focus: m['id'] as String);
  }

  Map<String, int> _sentence(int p, int s, int e) {
    final t = _text(p);
    var a = s, b = e;
    while (a > 0 && !RegExp(r'[.!?]').hasMatch(t[a - 1])) {
      a--;
    }
    while (b < t.length && !RegExp(r'[.!?]').hasMatch(t[b - 1 < 0 ? 0 : b - 1])) {
      b++;
    }
    while (a < b && t[a].trim().isEmpty) {
      a++;
    }
    return {'p': p, 's': a, 'e': b};
  }

  List<Map<String, int>> _span(({int p, int s}) a, ({int p, int s, int e}) b) {
    var x = a, y = b;
    if (b.p < a.p || (b.p == a.p && b.s < a.s)) {
      // se tocó primero la última palabra
      final endA = RegExp(r"[A-Za-z’'-]*").matchAsPrefix(_text(a.p), a.s)!.end;
      x = (p: b.p, s: b.s);
      y = (p: a.p, s: a.s, e: endA);
    }
    return [
      for (var p = x.p; p <= y.p; p++)
        {'p': p, 's': p == x.p ? x.s : 0, 'e': p == y.p ? y.e : _text(p).length},
    ];
  }

  void _onWord(int p, int s, int e, String word, String sentence) {
    final st = rangeStart;
    if (st != null) {
      setState(() => rangeStart = null);
      final ranges = _span(st, (p: p, s: s, e: e));
      _pickColor(ranges);
      return;
    }
    _wordSheet(p, s, e, word, sentence);
  }

  Future<void> _pickColor(List<Map<String, int>> ranges) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(tr('markW')),
            const SizedBox(height: 12),
            _ColorRow(onPick: (c) {
              Navigator.pop(ctx);
              _addMark(ranges, c);
            }),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _addMark(ranges, 'yellow', openNote: true);
              },
              child: Text('✎ ${tr('noteAdd')}'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _wordSheet(int p, int s, int e, String word, String ctxSentence) async {
    final r = await reading.lookup(word);
    if (r == null || !mounted) return;
    final saved = progress.words.any((w) => (w as Map)['w'] == r.base);
    final inMark = marks.where((m) => jsonList(m['ranges']).any((x) => x['p'] == p && (x['s'] as int) < e && (x['e'] as int) > s)).toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(r.base, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Tx.ink)),
              const SizedBox(width: 10),
              SayButton(r.base),
            ]),
            const SizedBox(height: 8),
            if (r.tr != null) ...[
              Text(r.tr!, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Tx.ink)),
              Text(
                tr(r.src == 'glosario' ? 'popGloss' : 'popCourse') + (r.fallback ? ', ${tr('inSpanish')}' : ''),
                style: TextStyle(fontSize: 12.5, color: Tx.muted),
              ),
              if (r.def != null) ...[
                const SizedBox(height: 8),
                Panel(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Kicker(tr('defEn')),
                    const SizedBox(height: 2),
                    Text(r.def!),
                  ]),
                ),
              ],
            ] else
              Text(tr('popNotFound'), style: TextStyle(color: Tx.muted)),
            const SizedBox(height: 4),
            Wrap(spacing: 4, children: [
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse('https://dictionary.cambridge.org/dictionary/${_cambridge()}/${Uri.encodeComponent(r.word)}'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text('${tr('dictionary')} Cambridge'),
              ),
            ]),
            OutlinedButton(
              onPressed: saved
                  ? null
                  : () {
                      progress.words.insert(0, {
                        'w': r.base,
                        'es': r.es,
                        'tr': r.tr ?? '',
                        'lg': i18n.lang,
                        'ctx': ctxSentence,
                        'at': DateTime.now().millisecondsSinceEpoch,
                      });
                      progress.save();
                      Navigator.pop(ctx);
                    },
              child: Text(tr(saved ? 'savedWord' : 'saveWord')),
            ),
            const Divider(height: 28),
            Kicker(tr('markW')),
            const SizedBox(height: 10),
            Text(tr('markWord'), style: TextStyle(fontSize: 13, color: Tx.muted)),
            const SizedBox(height: 6),
            _ColorRow(onPick: (c) {
              Navigator.pop(ctx);
              _addMark([{'p': p, 's': s, 'e': e}], c);
            }),
            const SizedBox(height: 12),
            Text(tr('markSentence'), style: TextStyle(fontSize: 13, color: Tx.muted)),
            const SizedBox(height: 6),
            _ColorRow(onPick: (c) {
              Navigator.pop(ctx);
              _addMark([_sentence(p, s, e)], c);
            }),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => rangeStart = (p: p, s: s));
                },
                child: Text(tr('markRange')),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _addMark([_sentence(p, s, e)], 'yellow', openNote: true);
                },
                child: Text('✎ ${tr('noteAdd')}'),
              ),
              if (inMark.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openNotes(focus: str(inMark.last['id']));
                  },
                  child: Text(tr('notesH')),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  String _cambridge() =>
      const {
        'es': 'english-spanish',
        'fr': 'english-french',
        'de': 'english-german',
        'it': 'english-italian',
        'pt': 'english-portuguese',
        'ru': 'english-russian',
        'zh': 'english-chinese-simplified',
      }[i18n.lang] ??
      'english';

  Future<void> _openNotes({String? focus}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, sc) => _NotesSheet(
          controller: sc,
          notes: _ensureNotes(),
          focus: focus,
          onGo: (m) {
            Navigator.pop(ctx);
            final p = (jsonList(m['ranges']).first['p'] as num).toInt();
            final c = paraKeys[p].currentContext;
            if (c != null) Scrollable.ensureVisible(c, alignment: 0.3, duration: const Duration(milliseconds: 400));
          },
          onChanged: () {
            progress.save();
            setState(() {});
          },
        ),
      ),
    );
    _tidyNotes();
    progress.save();
    if (mounted) setState(() {});
  }

  void _play() {
    if (speaking != null) {
      speech.stop();
      setState(() => speaking = null);
      return;
    }
    _readFrom(0);
  }

  void _readFrom(int i) {
    final d = doc!;
    if (i >= d.blocks.length || !mounted) {
      setState(() => speaking = null);
      return;
    }
    setState(() => speaking = i);
    final c = paraKeys[i].currentContext;
    if (c != null) Scrollable.ensureVisible(c, alignment: 0.3, duration: const Duration(milliseconds: 300));
    speech.say(_text(i), rate: progress.rate, onDone: () {
      if (mounted && speaking == i) _readFrom(i + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = doc;
    final nMarks = d == null ? 0 : marks.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.title ?? ''),
        actions: [
          if (d != null)
            TextButton.icon(
              onPressed: _openNotes,
              icon: const Icon(Icons.sticky_note_2_outlined, size: 20),
              label: Text(nMarks > 0 ? '${tr('notesH')} ($nMarks)' : tr('notesH')),
            ),
        ],
      ),
      body: d == null ? (error != null ? LoadError(error!) : const Center(child: CircularProgressIndicator())) : _body(d),
      bottomNavigationBar: rangeStart == null
          ? null
          : SafeArea(
              child: Container(
                color: Tx.feature,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Expanded(child: Text(tr('rangeHint'), style: TextStyle(color: Tx.onFeatureStrong))),
                  TextButton(
                    onPressed: () => setState(() => rangeStart = null),
                    child: Text(tr('cancel'), style: TextStyle(color: Tx.featureAccent)),
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _body(_Doc d) {
    final size = progress.textSize;
    final glossRe = d.glossary.isEmpty
        ? null
        : RegExp(
            '\\b(${(d.glossary.map((g) => RegExp.escape(str(g['en']))).toList()..sort((a, b) => b.length - a.length)).join('|')})\\b',
            caseSensitive: false,
          );
    return PageList(controller: scroll, children: [
      PageHeader(kicker: d.kicker, title: d.title, lede: d.sub),
      if (d.summary.isNotEmpty) ...[NoteBlock(label: tr('summaryK'), text: d.summary), const SizedBox(height: 14)],
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FilledButton(onPressed: _play, child: Text(speaking != null ? tr('stopAudio') : tr('playAudio'))),
        DropdownButton<double>(
          value: const [0.7, 0.9, 1.05].contains(progress.rate) ? progress.rate : 0.9,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(value: 0.9, child: Text(tr('speedNormal'))),
            DropdownMenuItem(value: 0.7, child: Text(tr('speedSlow'))),
            DropdownMenuItem(value: 1.05, child: Text(tr('speedFast'))),
          ],
          onChanged: (v) {
            progress.reading['rate'] = v ?? 0.9;
            progress.save();
            setState(() {});
          },
        ),
        OutlinedButton(onPressed: () => _resize(-0.1), child: const Text('A−')),
        OutlinedButton(onPressed: () => _resize(0.1), child: const Text('A+')),
        FilterChip(
          label: Text(tr('highlight')),
          selected: keywords,
          onSelected: (v) => setState(() => keywords = v),
        ),
      ]),
      if (d.glossary.isNotEmpty) ...[
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: !isBook,
              tilePadding: EdgeInsets.zero,
              title: Text(tr('keywords', {'n': d.glossary.length}), style: TextStyle(fontWeight: FontWeight.w500, color: Tx.ink)),
              children: [
                for (final g in d.glossary)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: str(g['en']), style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                        TextSpan(text: ' — ${glossTr[str(g['en'])] ?? str(g['es'])}'),
                      ])),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 10),
      Text('${tr('tapTip')} ${tr('markHintApp')}', style: TextStyle(fontSize: 12.5, color: Tx.muted)),
      const SizedBox(height: 14),
      for (var i = 0; i < d.blocks.length; i++)
        Container(
          key: paraKeys[i],
          margin: const EdgeInsets.only(bottom: 14),
          padding: speaking == i ? const EdgeInsets.all(6) : EdgeInsets.zero,
          decoration: BoxDecoration(color: speaking == i ? Tx.blueSoft : null, borderRadius: BorderRadius.circular(6)),
          child: _Paragraph(
            index: i,
            text: _text(i),
            verse: d.blocks[i]['t'] == 'v',
            size: size,
            marks: marks,
            keywords: keywords ? glossRe : null,
            rangeStart: rangeStart,
            onWord: _onWord,
          ),
        ),
      SectionTitle(tr('questionsN', {'n': d.questions.length}), title: tr('compQ'), lede: tr('qNote')),
      _Quiz(doc: d),
      if (d.task.isNotEmpty) ...[
        SectionTitle(tr('afterReading')),
        Text(d.task),
        const SizedBox(height: 8),
        TextField(
          controller: draft,
          minLines: 5,
          maxLines: 12,
          decoration: InputDecoration(hintText: tr('writeHere')),
          onChanged: (v) {
            progress.drafts[d.id] = v;
            progress.save();
          },
        ),
        const SizedBox(height: 4),
        Text(tr('draftNote'), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
      ],
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 12),
      Row(children: [
        if (d.prev != null)
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => d.prev!())),
            child: Text(tr('prev')),
          ),
        const Spacer(),
        if (d.next != null)
          FilledButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => d.next!())),
            child: Text(tr('next')),
          ),
      ]),
    ]);
  }

  void _resize(double delta) {
    final v = ((progress.textSize + delta).clamp(0.85, 1.6) * 100).round() / 100;
    progress.reading['size'] = v;
    progress.save();
    setState(() {});
  }
}

class _Paragraph extends StatefulWidget {
  const _Paragraph({
    required this.index,
    required this.text,
    required this.verse,
    required this.size,
    required this.marks,
    required this.keywords,
    required this.rangeStart,
    required this.onWord,
  });
  final int index;
  final String text;
  final bool verse;
  final double size;
  final List<Json> marks;
  final RegExp? keywords;
  final ({int p, int s})? rangeStart;
  final void Function(int p, int s, int e, String word, String sentence) onWord;
  @override
  State<_Paragraph> createState() => _ParagraphState();
}

class _ParagraphState extends State<_Paragraph> {
  final tokens = <({int s, int e, bool word})>[];
  final taps = <int, TapGestureRecognizer>{};

  @override
  void initState() {
    super.initState();
    for (final m in RegExp(r"[A-Za-z’'-]+|[^A-Za-z’'-]+").allMatches(widget.text)) {
      final word = RegExp(r'[A-Za-z]').hasMatch(m[0]!);
      tokens.add((s: m.start, e: m.end, word: word));
      if (word) {
        final i = tokens.length - 1;
        taps[i] = TapGestureRecognizer()..onTap = () => _tap(i);
      }
    }
  }

  @override
  void dispose() {
    for (final t in taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  void _tap(int i) {
    final t = tokens[i];
    var w = widget.text.substring(t.s, t.e);
    final lead = RegExp(r"^[-’']+").firstMatch(w)?.end ?? 0;
    final trail = RegExp(r"[-’']+$").firstMatch(w)?.start ?? w.length;
    final s = t.s + lead, e = t.s + (trail > lead ? trail : w.length);
    w = widget.text.substring(s, e);
    final a = widget.text.lastIndexOf(RegExp(r'[.!?]'), s > 0 ? s - 1 : 0);
    final b = widget.text.indexOf(RegExp(r'[.!?]'), e);
    final sentence = widget.text.substring(a < 0 || a >= s ? 0 : a + 1, b < 0 ? widget.text.length : b + 1).trim();
    widget.onWord(widget.index, s, e, w, sentence.length > 200 ? sentence.substring(0, 200) : sentence);
  }

  @override
  Widget build(BuildContext context) {
    final ranges = <(int, int, String)>[];
    for (final m in widget.marks) {
      for (final r in jsonList(m['ranges'])) {
        if (r['p'] == widget.index) ranges.add(((r['s'] as num).toInt(), (r['e'] as num).toInt(), str(m['color'])));
      }
    }
    final keys = widget.keywords == null ? const <RegExpMatch>[] : widget.keywords!.allMatches(widget.text).toList();
    final base = TextStyle(
      fontFamily: Tx.serif,
      fontSize: 17 * widget.size,
      height: 1.7,
      color: Tx.readerText,
      fontStyle: widget.verse ? FontStyle.italic : FontStyle.normal,
    );
    final spans = <InlineSpan>[];
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      String? color;
      for (final r in ranges) {
        if (t.s < r.$2 && t.e > r.$1) color = r.$3;
      }
      final key = keys.any((k) => t.s < k.end && t.e > k.start) && t.word;
      final start = widget.rangeStart != null && widget.rangeStart!.p == widget.index && widget.rangeStart!.s >= t.s && widget.rangeStart!.s < t.e;
      spans.add(TextSpan(
        text: widget.text.substring(t.s, t.e),
        recognizer: taps[i],
        style: TextStyle(
          backgroundColor: start ? Tx.rangeStart : (color != null ? Tx.marks[color]?[0] : null),
          decoration: key ? TextDecoration.underline : null,
          decorationColor: Tx.blue,
          decorationThickness: 2,
        ),
      ));
    }
    return Padding(
      padding: EdgeInsets.only(left: widget.verse ? 18 : 0),
      child: Text.rich(TextSpan(style: base, children: spans)),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.onPick, this.selected});
  final void Function(String color) onPick;
  final String? selected;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (final c in Tx.marks.keys)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onPick(c),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Tx.marks[c]![0],
                  shape: BoxShape.circle,
                  border: Border.all(color: Tx.marks[c]![1], width: selected == c ? 3 : 1.5),
                ),
              ),
            ),
          ),
      ]);
}

class _NotesSheet extends StatefulWidget {
  const _NotesSheet({required this.controller, required this.notes, required this.onGo, required this.onChanged, this.focus});
  final ScrollController controller;
  final Map notes;
  final String? focus;
  final void Function(Json mark) onGo;
  final VoidCallback onChanged;
  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  late final general = TextEditingController(text: str(widget.notes['general']));
  final fields = <String, TextEditingController>{};
  final focusNode = FocusNode();

  @override
  void dispose() {
    general.dispose();
    for (final c in fields.values) {
      c.dispose();
    }
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marks = jsonList(widget.notes['marks'])
      ..sort((a, b) {
        final ra = jsonList(a['ranges']).first, rb = jsonList(b['ranges']).first;
        final c = (ra['p'] as num).compareTo(rb['p'] as num);
        return c != 0 ? c : (ra['s'] as num).compareTo(rb['s'] as num);
      });
    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.fromLTRB(18, 16, 18, 24 + MediaQuery.of(context).viewInsets.bottom),
      children: [
        Row(children: [
          Expanded(child: Kicker(tr('notesH'), color: Tx.blue)),
          Text(tr('notesN', {'n': marks.length}), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
        ]),
        const SizedBox(height: 12),
        Text(tr('notesGeneral'), style: TextStyle(fontSize: 13, color: Tx.muted)),
        const SizedBox(height: 4),
        TextField(
          controller: general,
          minLines: 2,
          maxLines: 6,
          decoration: InputDecoration(hintText: tr('notesGeneralPh')),
          onChanged: (v) {
            widget.notes['general'] = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),
        if (marks.isEmpty) Text(tr('markHintApp'), style: TextStyle(color: Tx.muted)),
        for (final m in marks) _bubble(m),
      ],
    );
  }

  Widget _bubble(Json m) {
    final id = str(m['id']);
    final c = fields.putIfAbsent(id, () => TextEditingController(text: str(m['note'])));
    return MarkBubble(
      color: str(m['color']),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => widget.onGo(m),
          child: Text('«${str(m['quote'])}»', style: TextStyle(fontFamily: Tx.serif, fontStyle: FontStyle.italic, color: Tx.ink)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          autofocus: widget.focus == id,
          minLines: 1,
          maxLines: 5,
          decoration: InputDecoration(hintText: tr('notePh'), filled: true, fillColor: Tx.noteBg),
          onChanged: (v) {
            m['note'] = v;
            widget.onChanged();
          },
        ),
        Row(children: [
          for (final k in Tx.marks.keys)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                m['color'] = k;
                widget.onChanged();
                setState(() {});
              },
              icon: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Tx.marks[k]![0],
                  shape: BoxShape.circle,
                  border: Border.all(color: Tx.marks[k]![1], width: m['color'] == k ? 3 : 1),
                ),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: () {
              (widget.notes['marks'] as List).removeWhere((x) => (x as Map)['id'] == id);
              widget.onChanged();
              setState(() {});
            },
            child: Text(tr('delete')),
          ),
        ]),
      ]),
    );
  }
}

class _Quiz extends StatefulWidget {
  const _Quiz({required this.doc});
  final _Doc doc;
  @override
  State<_Quiz> createState() => _QuizState();
}

class _QuizState extends State<_Quiz> {
  late List<bool?> ans;
  late List<List<(String, Object)>> opts;
  final inputs = <int, TextEditingController>{};
  final shown = <int, String?>{};
  final picked = <int, int>{};

  List<Json> get qs => widget.doc.questions;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    ans = List<bool?>.filled(qs.length, null);
    opts = [
      for (final q in qs)
        q['type'] == 'tf'
            ? [(tr('trueW'), true), (tr('falseW'), false)]
            : [for (final o in strList(q['options'])) (o, o)],
    ];
    for (final c in inputs.values) {
      c.clear();
    }
    shown.clear();
    picked.clear();
  }

  @override
  void dispose() {
    for (final c in inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _done(int i, bool ok, [String? answer]) {
    setState(() {
      ans[i] = ok;
      shown[i] = answer;
    });
    if (ans.every((a) => a != null)) widget.doc.onScore(ans.where((a) => a == true).length / qs.length);
  }

  @override
  Widget build(BuildContext context) {
    if (qs.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(onPressed: () => widget.doc.onScore(1), child: Text(tr('markRead'))),
      );
    }
    final answered = ans.where((a) => a != null).length;
    final sc = ans.where((a) => a == true).length;
    final finished = answered == qs.length;
    final s = qs.isEmpty ? 0.0 : sc / qs.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.doc.prevBest != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(tr('yourBest', {'s': pct(widget.doc.prevBest!)}), style: TextStyle(color: Tx.muted)),
        ),
      ScorePanel(score: sc.toDouble(), total: qs.length, answered: answered, onRestart: () => setState(_reset)),
      const SizedBox(height: 12),
      for (var i = 0; i < qs.length; i++)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(i)),
      if (finished)
        Panel(
          color: s >= 0.5 ? Tx.blueSoft : Tx.rustSoft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(tr('resultH')),
            Text('$sc/${qs.length}', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Tx.ink)),
            Text(tr(s == 1 ? 'msgPerfect' : (s >= 0.75 ? 'msgGood' : (s >= 0.5 ? 'msgOk' : 'msgLow')))),
          ]),
        ),
    ]);
  }

  Widget _card(int i) {
    final q = qs[i];
    final a = ans[i];
    Widget body;
    if (q['type'] == 'mc' || q['type'] == 'tf') {
      body = Wrap(spacing: 8, runSpacing: 8, children: [
        for (var k = 0; k < opts[i].length; k++)
          Builder(builder: (_) {
            final (label, value) = opts[i][k];
            final good = value == q['answer'];
            final bg = a == null ? null : (good ? Tx.okSoft : (picked[i] == k ? Tx.badSoft : null));
            return OutlinedButton(
              onPressed: a != null
                  ? null
                  : () {
                      picked[i] = k;
                      _done(i, good);
                    },
              style: OutlinedButton.styleFrom(
                backgroundColor: bg,
                disabledForegroundColor: bg == Tx.okSoft ? Tx.ok : (bg == Tx.badSoft ? Tx.bad : Tx.muted),
              ),
              child: Text(label),
            );
          }),
      ]);
    } else {
      final c = inputs.putIfAbsent(i, () => TextEditingController());
      void check() {
        if (c.text.trim().isEmpty) return;
        final answers = strList(q['answer']);
        final ok = answers.any((x) => normWord(x) == normWord(c.text));
        _done(i, ok, ok ? null : (answers.isEmpty ? '' : answers.first));
      }

      body = Row(children: [
        Expanded(
          child: TextField(
            controller: c,
            enabled: a == null,
            autocorrect: false,
            decoration: InputDecoration(hintText: tr('answerLabel')),
            onSubmitted: (_) => check(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: a == null ? check : null, child: Text(tr('check'))),
      ]);
    }
    final fbColor = a == null ? Tx.grey : (a ? Tx.okSoft : Tx.badSoft);
    return CardBox(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberDot(i + 1),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(str(q['q']), style: TextStyle(fontWeight: FontWeight.w500, color: Tx.ink)),
            const SizedBox(height: 10),
            body,
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: fbColor, borderRadius: BorderRadius.circular(8)),
              child: a == null
                  ? Text(tr('answerToSee'), style: TextStyle(color: Tx.muted, fontSize: 13.5))
                  : Text.rich(TextSpan(children: [
                      TextSpan(
                        text: a ? tr('correct') : (shown[i] != null ? '${tr('answerIs')} ${shown[i]}' : '✘'),
                        style: TextStyle(fontWeight: FontWeight.w600, color: a ? Tx.ok : Tx.bad),
                      ),
                      TextSpan(text: '  ${str(q['why'])}'),
                    ])),
            ),
          ]),
        ),
      ]),
    );
  }
}
