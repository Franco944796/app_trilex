import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/markdown.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';
import 'exercise_view.dart';
import 'practice.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});
  final Json lesson;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Json? raw;
  Object? error;
  final scroll = ScrollController();
  final resultKey = GlobalKey();
  final practiceKey = GlobalKey<PracticeState>();
  double score = 0;
  int answered = 0;
  Widget? result;
  Json? _local;
  String _localLang = '';

  Json get localized {
    if (_local == null || _localLang != i18n.lang) {
      _local = course.localize(raw!);
      _localLang = i18n.lang;
    }
    return _local!;
  }

  Json get ent => widget.lesson;

  @override
  void initState() {
    super.initState();
    content.obj(str(ent['file'])).then((v) {
      if (mounted) setState(() => raw = v);
    }, onError: (Object e) {
      if (mounted) setState(() => error = e);
    });
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void _finish(Json L, double sc, int n) {
    final p = n == 0 ? 1.0 : sc / n;
    final pass = ((L['checkpoint'] as Map?)?['pass_score'] as num?)?.toDouble() ?? 0.7;
    final ok = p >= pass;
    final k = course.flat.indexWhere((x) => x['id'] == ent['id']);
    final nx = k + 1 < course.flat.length ? course.flat[k + 1] : null;
    final u = course.unitOf(ent);
    final lv = course.levelOf(ent['cefr']);
    final ul = Course.lessonsOf(u);
    final unitWas = ul.every((x) => course.isDone(x['id']));
    final examWas = course.examOpen(lv);
    if (ok) {
      final prev = progress.done[L['id']] as Map?;
      if (prev == null || ((prev['score'] as num?) ?? 0) < p) {
        progress.done[L['id']] = {'score': p, 'at': DateTime.now().millisecondsSinceEpoch};
      }
      for (final i in jsonList(L['srs_items'])) {
        progress.srs.putIfAbsent(str(i['id']), () => {'box': 1, 'due': dayNumber() + 1, 'lapses': 0});
      }
      progress.save();
    }
    final news = <String>[
      if (ok && !unitWas && ul.every((x) => course.isDone(x['id']))) tr('unitCompleted', {'n': u['order']}),
      if (ok && !examWas && course.examOpen(lv)) tr('examUnlocked', {'l': lv['cefr']}),
    ];
    final msg = ok
        ? tr(p >= 0.95 ? 'perfect' : (p >= 0.85 ? 'veryGood' : 'lessonPassed'))
        : '${tr('almost', {'p': (pass * 100).round()})} ${tr('tryAgain')}';
    final phrases = strList((L['summary'] as Map?)?['key_phrases']);
    setState(() {
      result = Column(key: resultKey, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Panel(
          color: ok ? Tx.blueSoft : Tx.rustSoft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(tr('resultH'), color: ok ? Tx.blue : Tx.rust),
            const SizedBox(height: 6),
            Text(pct(p), style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: Tx.ink)),
            Text(msg),
            for (final t in news) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t, style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink))),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (ok && nx != null)
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LessonScreen(lesson: nx))),
                  child: Text(tr('nextLessonArrow')),
                ),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('mapBack'))),
              OutlinedButton(onPressed: _restart, child: Text(tr('restart'))),
            ]),
          ]),
        ),
        if (phrases.isNotEmpty) ...[
          const SizedBox(height: 14),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Kicker(tr('keyPhrases')),
              for (final q in phrases)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [SayButton(q), const SizedBox(width: 10), Expanded(child: Text(q))]),
                ),
            ]),
          ),
        ],
      ]);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = resultKey.currentContext;
      if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 400));
    });
  }

  void _restart() {
    practiceKey.currentState?.restart();
    setState(() {
      result = null;
      score = 0;
      answered = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = course.unitOf(ent);
    return Scaffold(
      appBar: AppBar(title: Text('${ent['cefr']} · ${tr('unitN', {'n': u['order']})} · ${tr('lessonN', {'n': ent['order']})}')),
      body: raw == null
          ? (error != null ? LoadError(error!) : const Center(child: CircularProgressIndicator()))
          : _body(localized),
      bottomNavigationBar: raw == null || answered == 0
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Tx.blueSoft, border: Border(top: BorderSide(color: Tx.line))),
                child: Row(children: [
                  Kicker(tr('scoreH'), color: Tx.blue),
                  const SizedBox(width: 8),
                  Text('${fmtScore(score)} / ${jsonList(raw!['exercises']).length}', style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                  const Spacer(),
                  Text(tr('answeredNofM', {'a': answered, 'n': jsonList(raw!['exercises']).length}), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
                ]),
              ),
            ),
    );
  }

  Widget _body(Json L) {
    final x = (L['explanation'] as Map?)?.cast<String, dynamic>() ?? {};
    final input = (L['input'] as Map?)?.cast<String, dynamic>() ?? {};
    final gloss = jsonList(input['glossary']);
    final exs = jsonList(L['exercises']);
    final title = (L['title'] as Map).cast<String, dynamic>();
    final mistakes = jsonList(x['common_mistakes_es']);
    final friends = jsonList(x['false_friends']);
    return PageList(controller: scroll, children: [
      PageHeader(
        kicker: '${ent['cefr']} · ${tr('unitN', {'n': course.unitOf(ent)['order']})} · ${tr('lessonN', {'n': ent['order']})}',
        title: str(title['target']),
        sub: str(title['es']),
        lede: str(L['objective']),
      ),
      Text(tr('minExercises', {'m': L['est_minutes'], 'n': exs.length}), style: TextStyle(color: Tx.muted)),
      const SizedBox(height: 16),
      if (L['warmup'] is Map) NoteBlock(label: tr('secWarmup'), text: str((L['warmup'] as Map)['prompt_es'])),
      SectionTitle('01 · ${tr('secInput')}'),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InputText(input: input),
          if (gloss.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(tr('vocabH'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
            const SizedBox(height: 6),
            for (final w in gloss) _word(w),
          ],
        ]),
      ),
      SectionTitle('02 · ${tr('secExplain')}'),
      CardBox(child: MiniMarkdown(str(x['md_es']))),
      if (mistakes.isNotEmpty) ...[
        const SizedBox(height: 12),
        Panel(
          color: Tx.rustSoft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(tr('commonMistakes'), color: Tx.rust),
            for (final m in mistakes)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: str(m['wrong']), style: TextStyle(decoration: TextDecoration.lineThrough, color: Tx.bad)),
                    const TextSpan(text: '  →  '),
                    TextSpan(text: str(m['right']), style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                  ])),
                  if (str(m['note']).isNotEmpty) Text(str(m['note']), style: TextStyle(fontSize: 13, color: Tx.muted)),
                ]),
              ),
          ]),
        ),
      ],
      if (friends.isNotEmpty) ...[
        const SizedBox(height: 12),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(tr('falseFriends')),
            for (final f in friends)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${str(f['word'])}: ', style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                    TextSpan(text: tr('ffLine', {'f': f['es_false'], 'r': f['real']})),
                  ])),
                  Text(str(f['note']), style: TextStyle(fontSize: 13, color: Tx.muted)),
                ]),
              ),
          ]),
        ),
      ],
      SectionTitle('03 · ${tr('secPractice')}', title: tr('practiceH'), lede: tr('practiceLede')),
      Practice(
        key: practiceKey,
        exercises: exs,
        input: input,
        onProgress: (s, a) => setState(() {
          score = s;
          answered = a;
          if (a == 0) result = null;
        }),
        onFinished: (s, n, _) => _finish(L, s, n),
      ),
      if (result != null) result!,
    ]);
  }

  Widget _word(Json w) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Tx.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SayButton(str(w['lemma'])),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: str(w['lemma']), style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                TextSpan(text: '  ${str(w['pos'])}  ', style: TextStyle(fontSize: 12, color: Tx.muted)),
                TextSpan(text: str(w['ipa']), style: TextStyle(fontFamily: Tx.mono, fontSize: 12, color: Tx.muted)),
              ])),
              Text(str(w['es'])),
              if (str(w['example']).isNotEmpty) Text(str(w['example']), style: TextStyle(fontSize: 13, color: Tx.muted, fontStyle: FontStyle.italic)),
            ]),
          ),
        ]),
      );
}
