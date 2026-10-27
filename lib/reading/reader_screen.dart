import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../course/course.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'activities.dart';
import 'reading.dart';

typedef _Ranges = List<Map<String, int>>;

/// Si el párrafo está acomodado en la lista ahora. Uno que se conserva fuera de la pantalla
/// (el párrafo donde empezó el arrastre) tiene una posición vieja y no sirve para medir.
bool _placed(RenderObject r) {
  if (!r.attached || r is! RenderBox || !r.hasSize) return false;
  RenderObject? o = r;
  while (o != null && o.parentData is! SliverMultiBoxAdaptorParentData) {
    o = o.parent;
  }
  final pd = o?.parentData;
  return pd is SliverMultiBoxAdaptorParentData && !pd.keptAlive;
}

/// Selección del lector: un rango {p, s, e} por párrafo; [done] es falso mientras se arrastra.
typedef _Sel = ({_Ranges ranges, bool done});

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
    this.summaryModel = '',
    this.words = 0,
    this.prev,
    this.next,
    this.prevBest,
    required this.onScore,
  });
  final String id, noteTitle, href, level, kicker, title, sub, summary, task, summaryModel;
  final int words;
  final List<Json> blocks, glossary, questions;
  final Widget Function()? prev, next;

  /// Se actualiza al terminar el cuestionario, así «Reiniciar» muestra el mejor puntaje nuevo.
  double? prevBest;
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
  final viewKey = GlobalKey();
  final paraKeys = <GlobalKey>[];

  /// Párrafos construidos en este momento: la lista es perezosa y solo existen los cercanos a la pantalla.
  final live = <int, _ParagraphState>{};
  final sel = ValueNotifier<_Sel>((ranges: const <Map<String, int>>[], done: true));
  ({int p, int s, int e})? anchor;
  Offset? dragAt;

  /// Dónde se soltó la selección, en coordenadas del texto (no de la pantalla): la barra lo acompaña al desplazar.
  Offset barAt = Offset.zero;
  Timer? edgeTimer;
  bool keywords = false;
  RegExp? glossRe;
  int? speaking;
  final draft = TextEditingController();
  Map<String, String> glossTr = {};
  List<String> sentences = [];
  List<ClozeItem> cloze = [];
  DateTime? tmStart;
  String tmMsg = '';

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
    edgeTimer?.cancel();
    reading.clearGlossary();
    scroll.dispose();
    draft.dispose();
    sel.dispose();
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
        blocks: [
          for (final p in strList(t['paragraphs'])) {'t': 'p', 'text': p}
        ],
        glossary: jsonList(t['glossary']),
        questions: jsonList(t['questions']),
        task: str(t['task']),
        summaryModel: course.summaryOf(widget.id) ?? '',
        words: (t['words'] as num?)?.toInt() ?? 0,
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
        words: (c['words'] as num?)?.toInt() ?? 0,
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
    // para «Hoy»: lo último que se abrió, para seguir leyendo y para volver a contarlo
    progress.reading['lastRead'] = {'href': d.href, 'title': d.noteTitle, 'level': d.level, 'at': DateTime.now().millisecondsSinceEpoch};
    progress.save();
    final sents = [for (final b in d.blocks) ...sentencesOf(str(b['text']))];
    if (!mounted) return;
    setState(() {
      doc = d;
      glossTr = tr_;
      sentences = sents;
      cloze = clozeItems(d.glossary, sents, tr_);
      glossRe = d.glossary.isEmpty
          ? null
          : RegExp(
              '\\b(${(d.glossary.map((g) => RegExp.escape(str(g['en']))).toList()..sort((a, b) => b.length - a.length)).join('|')})\\b',
              caseSensitive: false,
            );
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
    final n = doc!.blocks.length;
    final v = (_bookState()['pos'] as Map)['${widget.chapterN}'] as num?;
    // antes se guardaba la fracción desplazada (0–1); ahora, el número de párrafo
    final p = v == null || n == 0 ? 0 : (v is double ? (v * n).floor() : v.toInt()).clamp(0, n - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (p > 0) {
        await _reveal(p, alignment: 0, duration: Duration.zero);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('resumed')), duration: const Duration(seconds: 2)));
      }
      scroll.addListener(_savePosition);
    });
  }

  int _lastPosSave = 0;
  void _savePosition() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPosSave < 800) return;
    final p = _topParagraph();
    if (p == null) return;
    _lastPosSave = now;
    (_bookState()['pos'] as Map)['${widget.chapterN}'] = p;
    progress.save();
  }

  RenderBox? _box(int p) {
    final r = paraKeys[p].currentContext?.findRenderObject();
    return r is RenderBox && _placed(r) ? r : null;
  }

  /// Primer párrafo que se ve arriba de la pantalla.
  int? _topParagraph() {
    final view = viewKey.currentContext?.findRenderObject() as RenderBox?;
    if (view == null) return null;
    final top = view.localToGlobal(Offset.zero).dy;
    int? best;
    for (final i in live.keys) {
      final box = _box(i);
      if (box != null && box.localToGlobal(Offset(0, box.size.height)).dy > top && (best == null || i < best)) best = i;
    }
    return best;
  }

  /// Lleva el párrafo [p] a la pantalla. Si todavía no está construido, salta a una posición estimada
  /// por la cantidad de letras y repite hasta que aparezca.
  Future<void> _reveal(int p, {double alignment = 0.3, Duration duration = const Duration(milliseconds: 400)}) async {
    for (var i = 0; i < 8 && mounted; i++) {
      final c = paraKeys[p].currentContext;
      if (c != null && c.mounted) return Scrollable.ensureVisible(c, alignment: alignment, duration: duration);
      final off = _estimate(p);
      if (off == null || !scroll.hasClients) return;
      scroll.jumpTo(off.clamp(0.0, scroll.position.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  double? _estimate(int p) {
    var chars = 0, count = 0, height = 0.0;
    int? near;
    var nearOff = 0.0;
    for (final i in live.keys) {
      final box = _box(i);
      if (box == null) continue;
      chars += _text(i).length;
      height += box.size.height;
      count++;
      if (near == null || (i - p).abs() < (near - p).abs()) {
        near = i;
        nearOff = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
      }
    }
    if (near == null || chars == 0) return null;
    const gap = 14.0;
    final perChar = (height - gap * count).clamp(0.0, double.infinity) / chars;
    var off = nearOff;
    for (var k = near; k < p; k++) {
      off += _text(k).length * perChar + gap;
    }
    for (var k = p; k < near; k++) {
      off -= _text(k).length * perChar + gap;
    }
    return off;
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

  bool _overlaps(_Ranges ranges) => marks.any((m) =>
      jsonList(m['ranges']).any((a) => ranges.any((b) => a['p'] == b['p'] && (a['s'] as num) < b['e']! && b['s']! < (a['e'] as num))));

  void _snack(String key) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(key)), duration: const Duration(seconds: 2)));

  String _quote(_Ranges ranges) =>
      [for (final r in ranges) _text(r['p']!).substring(r['s']!, r['e']!)].join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  void _addMark(_Ranges ranges, String color, {bool openNote = false}) {
    if (_overlaps(ranges)) return _snack('alreadyMarked');
    final quote = _quote(ranges);
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

  void _onWord(int p, int s, int e, String word, String sentence) {
    // con una selección abierta, tocar el texto solo la quita
    if (sel.value.ranges.isNotEmpty) return _selClear();
    _wordSheet(p, s, e, word, sentence);
  }

  // ── selección: mantener presionado y arrastrar, también entre párrafos ──

  static final _wordCh = RegExp(r"[A-Za-z’'-]");

  /// Párrafo y letra bajo un punto de la pantalla; entre párrafos, el más cercano.
  ({int p, int o})? _hit(Offset global) {
    ({int p, int o})? best;
    var bestD = double.infinity;
    for (final e in live.entries) {
      final rp = e.value.paragraph;
      if (rp == null) continue;
      final local = rp.globalToLocal(global);
      final h = rp.size.height;
      final d = local.dy < 0 ? -local.dy : (local.dy > h ? local.dy - h : 0.0);
      if (d < bestD) {
        bestD = d;
        best = (p: e.key, o: rp.getPositionForOffset(Offset(local.dx, local.dy.clamp(0.0, h - 1))).offset);
      }
    }
    return best;
  }

  _Ranges _trim(_Ranges rs) {
    final out = <Map<String, int>>[];
    for (final r in rs) {
      final t = _text(r['p']!);
      var s = r['s']!, e = r['e']!;
      while (s < e && t[s].trim().isEmpty) {
        s++;
      }
      while (e > s && t[e - 1].trim().isEmpty) {
        e--;
      }
      if (e > s) out.add({'p': r['p']!, 's': s, 'e': e});
    }
    return out;
  }

  void _selStart(Offset global) {
    final h = _hit(global);
    if (h == null) return;
    final t = _text(h.p);
    var at = h.o;
    // sobre comillas o signos pegados a una palabra, se toma esa palabra
    for (final d in const [0, 1, -1, 2, -2]) {
      final i = h.o + d;
      if (i >= 0 && i < t.length && _wordCh.hasMatch(t[i])) {
        at = i;
        break;
      }
    }
    var s = at, e = at;
    while (s > 0 && _wordCh.hasMatch(t[s - 1])) {
      s--;
    }
    while (e < t.length && _wordCh.hasMatch(t[e])) {
      e++;
    }
    if (e == s) return;
    HapticFeedback.selectionClick();
    anchor = (p: h.p, s: s, e: e);
    dragAt = global;
    sel.value = (ranges: _trim([{'p': h.p, 's': s, 'e': e}]), done: false);
  }

  void _selMove(Offset global) {
    if (anchor == null) return;
    dragAt = global;
    _extend();
    _autoScroll();
  }

  void _selEnd() {
    edgeTimer?.cancel();
    edgeTimer = null;
    final at = dragAt;
    dragAt = null;
    if (anchor == null) return;
    final view = viewKey.currentContext?.findRenderObject() as RenderBox?;
    if (at != null && view != null && scroll.hasClients) barAt = view.globalToLocal(at) + Offset(0, scroll.offset);
    anchor = null;
    sel.value = (ranges: sel.value.ranges, done: true);
  }

  void _selClear() => sel.value = (ranges: const <Map<String, int>>[], done: true);

  /// Lleva la selección hasta la palabra bajo el dedo (siempre palabras enteras).
  void _extend() {
    final a = anchor, at = dragAt;
    final f = a == null || at == null ? null : _hit(at);
    if (a == null || f == null) return;
    final t = _text(f.p);
    final _Ranges r;
    if (f.p > a.p || (f.p == a.p && f.o >= a.s)) {
      var e = f.o;
      while (e < t.length && _wordCh.hasMatch(t[e])) {
        e++;
      }
      if (f.p == a.p && e < a.e) e = a.e;
      r = [for (var p = a.p; p <= f.p; p++) {'p': p, 's': p == a.p ? a.s : 0, 'e': p == f.p ? e : _text(p).length}];
    } else {
      var s = f.o;
      while (s > 0 && _wordCh.hasMatch(t[s - 1])) {
        s--;
      }
      r = [for (var p = f.p; p <= a.p; p++) {'p': p, 's': p == f.p ? s : 0, 'e': p == a.p ? a.e : _text(p).length}];
    }
    final next = _trim(r);
    final now = sel.value.ranges;
    final same = next.length == now.length &&
        [for (var i = 0; i < next.length; i++) i].every((i) => mapEquals(next[i], now[i]));
    if (!same) sel.value = (ranges: next, done: false);
  }

  /// Velocidad del desplazamiento automático: el dedo cerca del borde de arriba o de abajo.
  double _edgeSpeed() {
    final view = viewKey.currentContext?.findRenderObject() as RenderBox?;
    final at = dragAt;
    if (view == null || at == null) return 0;
    final y = view.globalToLocal(at).dy, h = view.size.height;
    const zone = 60.0;
    final v = y < zone ? y - zone : (y > h - zone ? y - (h - zone) : 0.0);
    return (v * 0.4).clamp(-22.0, 22.0);
  }

  void _autoScroll() {
    if (edgeTimer != null || _edgeSpeed() == 0) return;
    edgeTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final v = _edgeSpeed();
      if (v == 0 || anchor == null || !scroll.hasClients) {
        t.cancel();
        edgeTimer = null;
        return;
      }
      final pos = scroll.position;
      final to = (scroll.offset + v).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (to == scroll.offset) return;
      scroll.jumpTo(to);
      // las posiciones de los párrafos cambian recién al dibujar el cuadro siguiente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _extend();
      });
    });
  }

  /// Barra flotante de la selección, junto al punto donde se soltó (arriba si hay lugar; si no, abajo).
  Widget _selBar(_Ranges ranges) {
    final quote = _quote(ranges);
    final r = ranges.first;
    final small = TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 40));
    void act(void Function() f) {
      _selClear();
      f();
    }

    final bar = Material(
      color: Tx.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Tx.line)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final c in Tx.marks.keys)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => act(() => _addMark(ranges, c)),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Tx.marks[c]![0],
                    shape: BoxShape.circle,
                    border: Border.all(color: Tx.marks[c]![1], width: 1.5),
                  ),
                ),
              ),
            ),
          TextButton(
            style: small,
            onPressed: () => act(() => _addMark(ranges, 'yellow', openNote: true)),
            child: Text('✎ ${tr('noteAdd')}'),
          ),
          if (ranges.length == 1 && quote.split(' ').length <= 4)
            TextButton(
              style: small,
              onPressed: () => act(() => _wordSheet(r['p']!, r['s']!, r['e']!, quote, _quote([_sentence(r['p']!, r['s']!, r['e']!)]))),
              child: Text(tr('translateW')),
            ),
          TextButton(
            style: small,
            onPressed: () => act(() {
              Clipboard.setData(ClipboardData(text: quote));
              _snack('copiedW');
            }),
            child: Text(tr('copyW')),
          ),
          IconButton(tooltip: tr('close'), onPressed: _selClear, icon: const Icon(Icons.close, size: 20)),
        ]),
      ),
    );
    return AnimatedBuilder(
      animation: scroll,
      builder: (context, child) => CustomSingleChildLayout(
        delegate: _BarLayout(barAt - Offset(0, scroll.hasClients ? scroll.offset : 0)),
        child: child,
      ),
      child: bar,
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
            if (inMark.isNotEmpty) ...[
              Text(tr('alreadyMarked'), style: TextStyle(fontSize: 13, color: Tx.muted)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openNotes(focus: str(inMark.last['id']));
                },
                child: Text('✎ ${tr('seeNote')}'),
              ),
            ] else ...[
              Kicker(tr('markW')),
              const SizedBox(height: 10),
              Text(tr('markWord'), style: TextStyle(fontSize: 13, color: Tx.muted)),
              const SizedBox(height: 6),
              _ColorRow(onPick: (c) {
                Navigator.pop(ctx);
                _addMark([
                  {'p': p, 's': s, 'e': e}
                ], c);
              }),
              const SizedBox(height: 12),
              Text(tr('markSentence'), style: TextStyle(fontSize: 13, color: Tx.muted)),
              const SizedBox(height: 6),
              _ColorRow(onPick: (c) {
                Navigator.pop(ctx);
                _addMark([_sentence(p, s, e)], c);
              }),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _addMark([_sentence(p, s, e)], 'yellow', openNote: true);
                },
                child: Text('✎ ${tr('noteAdd')}'),
              ),
            ],
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
    _selClear();
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
            _reveal((jsonList(m['ranges']).first['p'] as num).toInt());
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

  List<int> get _speeds => [
        for (final x in ((progress.reading['speed'] as Map?)?[doc!.id] as List?) ?? const []) ((x as Map)['wpm'] as num).toInt(),
      ];

  void _startTimed() {
    speech.stop();
    _selClear();
    setState(() {
      tmMsg = '';
      tmStart = DateTime.now();
      speaking = null;
    });
    scroll.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  void _stopTimed() {
    final secs = DateTime.now().difference(tmStart!).inMilliseconds / 1000;
    final d = doc!;
    final wpm = secs <= 0 ? 0 : (d.words / (secs / 60)).round();
    setState(() => tmStart = null);
    // más de 600 palabras por minuto no es leer: probablemente se tocó sin querer
    if (d.words == 0 || wpm > 600) {
      setState(() => tmMsg = tr('tmTooFast'));
      return;
    }
    final all = (progress.reading['speed'] as Map?) ?? (progress.reading['speed'] = <String, dynamic>{});
    ((all[d.id] as List?) ?? (all[d.id] = <dynamic>[])).add({'wpm': wpm, 'at': DateTime.now().millisecondsSinceEpoch});
    progress.save();
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
    _reveal(i, duration: const Duration(milliseconds: 300));
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
      body: d == null
          ? (error != null ? LoadError(error!) : const Center(child: CircularProgressIndicator()))
          : Stack(children: [
              _body(d),
              ValueListenableBuilder<_Sel>(
                valueListenable: sel,
                builder: (context, s, child) =>
                    s.done && s.ranges.isNotEmpty ? Positioned.fill(child: _selBar(s.ranges)) : const SizedBox.shrink(),
              ),
            ]),
      bottomNavigationBar: tmStart != null ? _TimerBar(start: tmStart!, onStop: _stopTimed) : null,
    );
  }

  Widget _body(_Doc d) {
    final size = progress.textSize;
    final byPara = <int, List<(int, int, String)>>{};
    for (final m in marks) {
      for (final r in jsonList(m['ranges'])) {
        (byPara[(r['p'] as num).toInt()] ??= []).add(((r['s'] as num).toInt(), (r['e'] as num).toInt(), str(m['color'])));
      }
    }
    const side = EdgeInsets.symmetric(horizontal: 16);
    // Lista perezosa: en un capítulo de 10 000 palabras solo se arman los párrafos cercanos a la pantalla.
    return CustomScrollView(
      key: viewKey,
      controller: scroll,
      scrollCacheExtent: const ScrollCacheExtent.pixels(600),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: _header(d)),
        ),
        SliverPadding(
          padding: side,
          sliver: SliverList.builder(
            itemCount: d.blocks.length,
            itemBuilder: (context, i) => Container(
              key: paraKeys[i],
              margin: const EdgeInsets.only(bottom: 14),
              padding: speaking == i ? const EdgeInsets.all(6) : EdgeInsets.zero,
              decoration: BoxDecoration(color: speaking == i ? Tx.blueSoft : null, borderRadius: BorderRadius.circular(6)),
              child: _Paragraph(
                index: i,
                text: _text(i),
                verse: d.blocks[i]['t'] == 'v',
                size: size,
                marks: byPara[i] ?? const [],
                keywords: keywords ? glossRe : null,
                selection: sel,
                live: live,
                onWord: _onWord,
                onPress: _selStart,
                onDrag: _selMove,
                onRelease: _selEnd,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          // también perezosas; una vez armadas se conservan (respuestas del cuestionario, grabaciones…)
          sliver: SliverList.list(children: [for (final w in _after(d)) _Keep(child: w)]),
        ),
      ],
    );
  }

  Widget _header(_Doc d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            // Material propio: sin él, el fondo del Panel tapa el efecto del toque (y Flutter avisa)
            child: Material(
              type: MaterialType.transparency,
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
          ),
        ],
        const SizedBox(height: 10),
        Text('${tr('tapTip')} ${tr('markHintApp')}', style: TextStyle(fontSize: 12.5, color: Tx.muted)),
        const SizedBox(height: 14),
      ]);

  List<Widget> _after(_Doc d) {
    Widget group(List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    return [
      ShadowSection(sentences: sentences),
      group([
        SectionTitle(tr('questionsN', {'n': d.questions.length}), title: tr('compQ'), lede: tr('qNote')),
        _Quiz(doc: d),
      ]),
      ClozeSection(items: cloze),
      if (d.summaryModel.isNotEmpty) SummarySection(docId: d.id, level: d.level, model: d.summaryModel),
      group([
        SectionTitle(tr('fluH')),
        TimedReadingCard(history: _speeds, running: tmStart != null, onStart: _startTimed, message: tmMsg),
        const SizedBox(height: 12),
        const RetellCard(),
      ]),
      if (d.task.isNotEmpty)
        group([
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
        ]),
      group([
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
      ]),
    ];
  }

  void _resize(double delta) {
    final v = ((progress.textSize + delta).clamp(0.85, 1.6) * 100).round() / 100;
    progress.reading['size'] = v;
    progress.save();
    setState(() {});
  }
}

class _Keep extends StatefulWidget {
  const _Keep({required this.child});
  final Widget child;
  @override
  State<_Keep> createState() => _KeepState();
}

class _KeepState extends State<_Keep> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _BarLayout extends SingleChildLayoutDelegate {
  _BarLayout(this.at);
  final Offset at;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) => BoxConstraints.loose(Size(c.maxWidth - 16, c.maxHeight));

  @override
  Offset getPositionForChild(Size size, Size child) {
    const gap = 28.0;
    final x = (at.dx - child.width / 2).clamp(8.0, size.width - child.width - 8);
    final above = at.dy - gap - child.height;
    // sin clamp vertical: si la selección sale de la pantalla al desplazar, la barra se va con ella
    return Offset(x, above >= 8 ? above : at.dy + gap);
  }

  @override
  bool shouldRelayout(_BarLayout old) => old.at != at;
}

/// Barra del cronómetro: se redibuja sola cada segundo, sin reconstruir el lector.
class _TimerBar extends StatefulWidget {
  const _TimerBar({required this.start, required this.onStop});
  final DateTime start;
  final VoidCallback onStop;
  @override
  State<_TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<_TimerBar> {
  Timer? tick;

  @override
  void initState() {
    super.initState();
    tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          color: Tx.feature,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Expanded(
              child: Text('⏱ ${clock(DateTime.now().difference(widget.start).inSeconds)}',
                  style: TextStyle(fontFamily: Tx.mono, fontSize: 18, color: Tx.onFeatureStrong)),
            ),
            FilledButton(
              onPressed: widget.onStop,
              style: FilledButton.styleFrom(backgroundColor: Tx.lightBtn, foregroundColor: Tx.lightBtnText),
              child: Text(tr('tmStop')),
            ),
          ]),
        ),
      );
}

class _Paragraph extends StatefulWidget {
  const _Paragraph({
    required this.index,
    required this.text,
    required this.verse,
    required this.size,
    required this.marks,
    required this.keywords,
    required this.selection,
    required this.live,
    required this.onWord,
    required this.onPress,
    required this.onDrag,
    required this.onRelease,
  });
  final int index;
  final String text;
  final bool verse;
  final double size;

  /// Subrayados de este párrafo: (inicio, fin, color).
  final List<(int, int, String)> marks;
  final RegExp? keywords;
  final ValueListenable<_Sel> selection;
  final Map<int, _ParagraphState> live;
  final void Function(int p, int s, int e, String word, String sentence) onWord;
  final void Function(Offset global) onPress, onDrag;
  final VoidCallback onRelease;
  @override
  State<_Paragraph> createState() => _ParagraphState();
}

class _ParagraphState extends State<_Paragraph> with AutomaticKeepAliveClientMixin {
  final tokens = <({int s, int e, bool word})>[];
  final _textKey = GlobalKey();
  (int, int)? sel;
  bool pressing = false;
  Widget? cached;
  Object? cachedFor;
  List<(int, int, String)> cachedMarks = const [];

  // El párrafo donde empezó a arrastrarse no se descarta aunque salga de la pantalla:
  // con él se iría el gesto y la selección quedaría a medias.
  @override
  bool get wantKeepAlive => pressing;

  RenderParagraph? get paragraph {
    final r = _textKey.currentContext?.findRenderObject();
    return r is RenderParagraph && _placed(r) ? r : null;
  }

  @override
  void initState() {
    super.initState();
    _tokenize();
    widget.live[widget.index] = this;
    widget.selection.addListener(_onSel);
    sel = _mine();
  }

  @override
  void didUpdateWidget(_Paragraph old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _tokenize();
  }

  @override
  void dispose() {
    if (identical(widget.live[widget.index], this)) widget.live.remove(widget.index);
    widget.selection.removeListener(_onSel);
    if (pressing) widget.onRelease();
    super.dispose();
  }

  (int, int)? _mine() {
    for (final r in widget.selection.value.ranges) {
      if (r['p'] == widget.index) return (r['s']!, r['e']!);
    }
    return null;
  }

  void _onSel() {
    final m = _mine();
    if (m != sel) setState(() => sel = m);
  }

  void _press(bool v) {
    pressing = v;
    updateKeepAlive();
  }

  void _tokenize() {
    tokens.clear();
    for (final m in RegExp(r"[A-Za-z’'-]+|[^A-Za-z’'-]+").allMatches(widget.text)) {
      tokens.add((s: m.start, e: m.end, word: RegExp(r'[A-Za-z]').hasMatch(m[0]!)));
    }
  }

  // Un solo detector por párrafo: con un reconocedor por palabra, los capítulos largos
  // (~9000 palabras) dejaban la app muy lenta.
  void _onTapUp(TapUpDetails d) {
    final box = paragraph;
    if (box == null) return;
    final at = box.getPositionForOffset(d.localPosition).offset;
    final i = tokens.indexWhere((t) => t.word && at >= t.s && at <= t.e);
    if (i < 0) return;
    final t = tokens[i];
    final hit = box
        .getBoxesForSelection(TextSelection(baseOffset: t.s, extentOffset: t.e))
        .any((b) => b.toRect().inflate(2).contains(d.localPosition));
    if (hit) _tap(i);
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
    super.build(context);
    // el lector se reconstruye entero al cambiar algo (un subrayado, el párrafo leído en voz alta):
    // si este párrafo no cambió, se devuelve el mismo widget y Flutter no lo vuelve a armar
    final key = (widget.text, widget.size, widget.verse, widget.keywords, sel, Tx.readerText);
    if (cached != null && key == cachedFor && listEquals(widget.marks, cachedMarks)) return cached!;
    cachedFor = key;
    cachedMarks = widget.marks;
    return cached = _build();
  }

  Widget _build() {
    final keys = widget.keywords == null ? const <RegExpMatch>[] : widget.keywords!.allMatches(widget.text).toList();
    final base = TextStyle(
      fontFamily: Tx.serif,
      fontSize: 17 * widget.size,
      height: 1.7,
      color: Tx.readerText,
      fontStyle: widget.verse ? FontStyle.italic : FontStyle.normal,
    );
    final sel = this.sel;
    // las palabras seguidas con el mismo estilo van en un mismo tramo de texto
    final spans = <InlineSpan>[];
    var runStart = 0;
    Color? runBg;
    var runKey = false;
    void flush(int end) {
      if (end <= runStart) return;
      spans.add(TextSpan(
        text: widget.text.substring(runStart, end),
        style: runBg == null && !runKey
            ? null
            : TextStyle(
                backgroundColor: runBg,
                decoration: runKey ? TextDecoration.underline : null,
                decorationColor: Tx.blue,
                decorationThickness: 2,
              ),
      ));
      runStart = end;
    }

    for (final t in tokens) {
      String? color;
      for (final r in widget.marks) {
        if (t.s < r.$2 && t.e > r.$1) color = r.$3;
      }
      final key = t.word && keys.any((k) => t.s < k.end && t.e > k.start);
      final mark = color != null ? Tx.marks[color]?.first : null;
      final chosen = sel != null && t.s < sel.$2 && t.e > sel.$1;
      final bg = chosen ? (mark == null ? Tx.selection : Color.alphaBlend(Tx.selection, mark)) : mark;
      if (bg != runBg || key != runKey) {
        flush(t.s);
        runBg = bg;
        runKey = key;
      }
    }
    flush(widget.text.length);
    return Padding(
      padding: EdgeInsets.only(left: widget.verse ? 18 : 0),
      child: RepaintBoundary(
        // con el mouse alcanza con hacer clic y arrastrar, como en la web: el mouse no desplaza la lista,
        // así que el arrastre no compite con el desplazamiento
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
              () => PanGestureRecognizer(supportedDevices: {PointerDeviceKind.mouse}),
              (r) => r
                ..onStart = (d) {
                  _press(true);
                  widget.onPress(d.globalPosition);
                }
                ..onUpdate = ((d) => widget.onDrag(d.globalPosition))
                ..onEnd = (_) {
                  _press(false);
                  widget.onRelease();
                },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _onTapUp,
            onLongPressStart: (d) {
              _press(true);
              widget.onPress(d.globalPosition);
            },
            onLongPressMoveUpdate: (d) => widget.onDrag(d.globalPosition),
            onLongPressEnd: (_) {
              _press(false);
              widget.onRelease();
            },
            child: Text.rich(TextSpan(style: base, children: spans), key: _textKey),
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.onPick});
  final void Function(String color) onPick;
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
                  border: Border.all(color: Tx.marks[c]![1], width: 1.5),
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
            : [for (final o in seededShuffle(strList(q['options']), str(q['q']))) (o, o)],
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
    if (ans.every((a) => a != null)) {
      final s = ans.where((a) => a == true).length / qs.length;
      widget.doc.onScore(s);
      progress.markToday('read');
      final b = widget.doc.prevBest;
      widget.doc.prevBest = b == null || s > b ? s : b;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (qs.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: () {
            widget.doc.onScore(1);
            progress.markToday('read');
          },
          child: Text(tr('markRead')),
        ),
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
      for (var i = 0; i < qs.length; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(i)),
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
