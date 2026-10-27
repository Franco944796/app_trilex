import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../course/course.dart';
import '../course/dicto_screen.dart';
import '../course/lesson_screen.dart';
import '../reading/activities.dart';
import '../reading/reader_screen.dart';
import '../reading/reading.dart';
import '../reading/reading_home.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../words/review_screen.dart';
import '../words/srs.dart';
import 'cando_screen.dart';

/// Plan del día: leer (entrada), repasar palabras (recordar) y producir (salida), siguiendo los
/// cuatro componentes de un curso equilibrado (Nation). La fluidez está dentro del lector.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Json? ix;
  Set<String> known = {};
  final bookWords = <String, Map<int, int>>{}; // palabras por capítulo de los libros empezados

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final i = await reading.index();
    final k = await appVocabIds();
    for (final id in progress.books.keys) {
      try {
        final b = await content.obj('reading/books/$id/book.json');
        bookWords[id] = {for (final c in jsonList(b['chapters'])) (c['n'] as num).toInt(): (c['words'] as num?)?.toInt() ?? 0};
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        ix = i;
        known = k;
      });
    }
  }

  Future<void> _go(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  /// Qué leer hoy: seguir el libro empezado; si no, la próxima lectura sin hacer del nivel.
  ({String title, String sub, Widget Function() open})? _nextReading() {
    final last = progress.reading['lastRead'] as Map?;
    final href = str(last?['href']);
    if (href.startsWith('#/libro/')) {
      final p = href.split('/');
      final st = progress.books[p[2]] as Map?;
      final n = ((st?['last'] as num?) ?? int.tryParse(p.length > 3 ? p[3] : '1') ?? 1).toInt();
      final book = jsonList(ix!['books']).where((b) => b['id'] == p[2]).firstOrNull;
      if (book != null && n <= (book['chapters'] as num).toInt()) {
        return (
          title: str(book['title']),
          sub: tr('chapterOf', {'n': n, 'm': book['chapters']}),
          open: () => ReaderScreen.chapter(p[2], n),
        );
      }
    }
    final texts = jsonList(ix!['texts']).where((t) => appLevel(t['level'])).toList();
    final order = [...texts.where((t) => t['level'] == myLevel), ...texts.where((t) => t['level'] != myLevel)];
    final t = order.where((t) => progress.texts[t['id']] == null).firstOrNull;
    if (t != null) {
      return (
        title: str(t['title']),
        sub: '${t['level']} · ${tr('wordsN', {'n': t['words']})} · ~${tr('minN', {'n': t['minutes']})}',
        open: () => ReaderScreen.text(str(t['id'])),
      );
    }
    final b = jsonList(ix!['books']).where((b) => appLevel(b['level']) && progress.books[b['id']] == null).firstOrNull;
    if (b == null) return null;
    return (title: str(b['title']), sub: tr('chapterOf', {'n': 1, 'm': b['chapters']}), open: () => ReaderScreen.chapter(str(b['id']), 1));
  }

  /// Producir: un día dictogloss de una unidad del nivel, otro día volver a contar lo último leído.
  ({String title, String sub, Widget Function() open}) _produce() {
    final day = dayNumber();
    final last = progress.reading['lastRead'] as Map?;
    if (day.isOdd && last != null) {
      return (title: tr('rtH'), sub: str(last['title']), open: () => _RetellPage(title: str(last['title'])));
    }
    final lv = course.ready.where((l) => l['cefr'] == myLevel).firstOrNull ?? course.ready.first;
    final units = Course.units(lv).where((u) => course.dictoglossOf(str(u['id'])) != null).toList();
    final u = units[(day ~/ 2) % units.length];
    return (
      title: tr('dgT'),
      sub: '${lv['cefr']} · ${tr('unitN', {'n': u['order']})} · ${u['title_target']}',
      open: () => DictoScreen(unitId: str(u['id'])),
    );
  }

  int get _wordsRead {
    var n = 0;
    for (final t in jsonList(ix!['texts'])) {
      if (progress.texts[t['id']] != null) n += (t['words'] as num).toInt();
    }
    bookWords.forEach((id, chs) {
      final done = ((progress.books[id] as Map?)?['c'] as Map?) ?? const {};
      for (final k in done.keys) {
        n += chs[int.tryParse('$k') ?? 0] ?? 0;
      }
    });
    return n;
  }

  int get _booksDone => bookWords.entries.where((e) {
        final done = ((progress.books[e.key] as Map?)?['c'] as Map?) ?? const {};
        return e.value.isNotEmpty && done.length >= e.value.length;
      }).length;

  int? get _lastWpm {
    int? best;
    var at = 0;
    for (final l in ((progress.reading['speed'] as Map?) ?? const {}).values) {
      for (final x in (l as List)) {
        final t = ((x as Map)['at'] as num).toInt();
        if (t > at) {
          at = t;
          best = (x['wpm'] as num).toInt();
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    if (ix == null) return const Center(child: CircularProgressIndicator());
    final read = _nextReading();
    final due = dueReadingWords + dueCourseWords(known);
    final prod = _produce();
    final learned = progress.words.whereType<Map>().where((w) => ((w['box'] as num?) ?? 0) >= 4).length +
        progress.srs.entries.where((e) => known.contains(e.key) && (((e.value as Map)['box'] as num?) ?? 0) >= 4).length;
    final lastRead = progress.reading['lastRead'] as Map?;
    final related = lastRead == null ? null : course.unitForReading(str(lastRead['href']).replaceFirst('#/texto/', ''));
    return PageList(children: [
      PageHeader(kicker: tr('todayK', {'l': myLevel}), title: tr('todayTitle'), lede: tr('todayLede')),
      _stats(),
      const SizedBox(height: 18),
      _step(
        n: 1,
        kicker: tr('tdRead'),
        title: read?.title ?? tr('tdAllRead'),
        sub: read?.sub ?? '',
        done: progress.doneToday('read'),
        action: read == null ? null : () => _go(read.open()),
        label: tr('readGo'),
      ),
      _step(
        n: 2,
        kicker: tr('tdReview'),
        title: due > 0 ? tr('pendingN', {'n': due}) : tr('rvNone'),
        sub: tr('tdReviewSub'),
        done: progress.doneToday('review') || due == 0,
        action: due == 0 ? null : () => _go(const WordReviewScreen()),
        label: tr('rvBtn', {'n': due}),
      ),
      _step(
        n: 3,
        kicker: tr('tdProduce'),
        title: prod.title,
        sub: prod.sub,
        done: progress.doneToday('produce'),
        action: () => _go(prod.open()),
        label: tr('tdStart'),
      ),
      if (related != null) _related(related),
      SectionTitle(tr('tdProgress')),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _tile(tr('tdWordsRead'), '$_wordsRead'),
        _tile(tr('tdBooks'), '$_booksDone'),
        _tile(tr('tdWpm'), _lastWpm == null ? '—' : '$_lastWpm'),
        _tile(tr('tdLearned'), '$learned'),
      ]),
      const SizedBox(height: 14),
      OutlinedButton(onPressed: () => _go(const CanDoScreen()), child: Text(tr('cdBtn'))),
    ]);
  }

  Widget _stats() => Panel(
        color: Tx.blueSoft,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Kicker(tr('todayH'), color: Tx.blue),
              Text('${progress.minutesToday} / ${progress.goal} min', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Tx.ink)),
              const SizedBox(height: 6),
              ProgressLine(progress.goal == 0 ? 0 : progress.minutesToday / progress.goal),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                for (final m in [10, 20, 30])
                  ChoiceChip(
                    label: Text('$m'),
                    selected: progress.goal == m,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) async {
                      progress.course['goal'] = m;
                      await progress.save();
                      setState(() {});
                    },
                  ),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(tr('streakH'), color: Tx.blue),
            Text('${progress.streak}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Tx.ink)),
            Text(tr(progress.streak == 1 ? 'day1' : 'days'), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
          ]),
        ]),
      );

  Widget _step({
    required int n,
    required String kicker,
    required String title,
    required String sub,
    required bool done,
    required VoidCallback? action,
    required String label,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CardBox(
          borderColor: done ? Tx.doneLine : Tx.line,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            done
                ? Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Tx.ok, shape: BoxShape.circle),
                    child: const Text('✓', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  )
                : NumberDot(n),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Kicker(kicker, color: Tx.blue),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
                if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 13, color: Tx.muted)),
                if (action != null) ...[
                  const SizedBox(height: 10),
                  done ? OutlinedButton(onPressed: action, child: Text(label)) : FilledButton(onPressed: action, child: Text(label)),
                ],
              ]),
            ),
          ]),
        ),
      );

  Widget _related(Json u) {
    final ls = [for (final l in Course.lessonsOf(u)) course.lessonById(l['id'])].whereType<Json>().toList();
    final l = ls.where((x) => !course.isDone(x['id'])).firstOrNull ?? (ls.isEmpty ? null : ls.first);
    if (l == null) return const SizedBox.shrink();
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Kicker(tr('tdGrammar')),
        const SizedBox(height: 4),
        Text('${u['cefr']} · ${tr('unitN', {'n': u['order']})} · ${u['title_target']}', style: TextStyle(color: Tx.muted, fontSize: 13)),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => _go(LessonScreen(lesson: l)),
          child: Text('${l['title_target']} →'),
        ),
      ]),
    );
  }

  Widget _tile(String label, String value) => SizedBox(
        width: 150,
        child: CardBox(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Tx.ink)),
            Text(label, style: TextStyle(fontSize: 12.5, color: Tx.muted)),
          ]),
        ),
      );
}

class _RetellPage extends StatelessWidget {
  const _RetellPage({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('rtH'))),
        body: PageList(children: [
          PageHeader(kicker: tr('tdProduce'), title: title, lede: tr('tdRetellLede')),
          const RetellCard(),
        ]),
      );
}
