import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';
import 'exam_screen.dart';
import 'faq_screen.dart';
import 'lesson_screen.dart';
import 'placement_screen.dart';
import 'review_screen.dart';
import 'vocab_screen.dart';

/// Mapa del curso: estado, herramientas, siguiente lección y niveles → unidades → lecciones.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _open; // nivel desplegado (por defecto, el actual)

  Future<void> _go(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  void _lesson(Json l) => _go(LessonScreen(lesson: l));

  @override
  Widget build(BuildContext context) {
    final next = course.nextLesson;
    final cur = next?['cefr'] ?? course.ready.last['cefr'];
    final nDone = course.flat.where((l) => course.isDone(l['id'])).length;
    final due = course.dueItems.length;
    final pl = progress.placement;
    return PageList(children: [
      PageHeader(kicker: tr('courseMap'), title: tr('courseTitle'), lede: tr('courseLede')),
      _stats(nDone, due),
      const SizedBox(height: 14),
      Kicker(tr('toolsH')),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton(
          onPressed: () => _go(const PlacementScreen()),
          child: Text(pl == null ? tr('placementT') : '${tr('placementT')} · ${pl['level']}'),
        ),
        OutlinedButton(
          onPressed: due == 0 ? null : () => _go(const ReviewScreen()),
          child: Text(due == 0 ? tr('reviewT') : '${tr('reviewT')} ($due)'),
        ),
        OutlinedButton(onPressed: () => _go(const VocabScreen()), child: Text(tr('vocabT'))),
        OutlinedButton(onPressed: () => _go(const FaqScreen()), child: Text(tr('helpT'))),
      ]),
      const SizedBox(height: 20),
      if (next != null) _nextCard(next, nDone > 0),
      for (final lv in course.ready) _level(lv, _open == null ? lv['cefr'] == cur : _open == lv['cefr']),
      for (final lv in course.levels.where((l) => !course.ready.contains(l)))
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('${lv['cefr']} · ${tr('lv_${lv['cefr']}')} — ${tr('comingSoon')}', style: TextStyle(color: Tx.muted)),
        ),
      const SizedBox(height: 24),
      const Divider(),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: progress.testMode,
        title: Text(tr('testMode'), style: const TextStyle(fontSize: 14)),
        onChanged: (v) async {
          progress.course['open'] = v;
          await progress.save();
          setState(() {});
        },
      ),
      if (!i18n.isEs) Text(tr('contentNote'), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
    ]);
  }

  Widget _stat(String label, String value, String sub, [Widget? extra]) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kicker(label, color: Tx.blue),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Tx.ink)),
          Text(sub, style: TextStyle(fontSize: 12.5, color: Tx.muted)),
          if (extra != null) ...[const SizedBox(height: 6), extra],
        ],
      );

  Widget _stats(int nDone, int due) {
    final n = course.flat.length;
    return Panel(
      color: Tx.blueSoft,
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _stat(tr('progressH'), '$nDone / $n', tr('lessonsWord'), ProgressLine(n == 0 ? 0 : nDone / n))),
          const SizedBox(width: 16),
          Expanded(
            child: _stat(
              tr('todayH'),
              '${progress.minutesToday} / ${progress.goal} min',
              tr('goalTitle'),
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
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _stat(tr('streakH'), '${progress.streak}', tr(progress.streak == 1 ? 'day1' : 'days'))),
          const SizedBox(width: 16),
          Expanded(child: _stat(tr('reviewT'), '$due', due > 0 ? tr('pendingN', {'n': due}) : tr('nothingDue'))),
        ]),
      ]),
    );
  }

  Widget _nextCard(Json l, bool started) {
    final u = course.unitOf(l);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Tx.feature,
          border: Border.all(color: Tx.featureLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Kicker('${tr('nextH')} · ${l['cefr']} · ${tr('unitN', {'n': u['order']})} · ${tr('lessonN', {'n': l['order']})}',
              color: Tx.onFeatureMuted),
          const SizedBox(height: 8),
          Text(str(l['title_target']), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Tx.onFeatureStrong)),
          Text(course.subTitle(l['id'], str(l['title_es']), str(l['title_target'])), style: TextStyle(color: Tx.onFeatureMuted)),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => _lesson(l),
            style: FilledButton.styleFrom(backgroundColor: Tx.lightBtn, foregroundColor: Tx.lightBtnText),
            child: Text(tr(started ? 'continueArrow' : 'startArrow')),
          ),
        ]),
      ),
    );
  }

  Widget _level(Json lv, bool open) {
    final cefr = str(lv['cefr']);
    final ls = course.flat.where((l) => l['cefr'] == cefr).toList();
    final nd = ls.where((l) => course.isDone(l['id'])).length;
    final tot = course.levelTotal(lv);
    final ex = progress.exams[cefr] as Map?;
    final head = InkWell(
      onTap: () => setState(() => _open = open ? '' : cefr),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: Tx.ink), borderRadius: BorderRadius.circular(8)),
            child: Text(cefr, style: TextStyle(fontFamily: Tx.mono, fontWeight: FontWeight.w500, color: Tx.ink)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Kicker(tr('levelK', {'l': cefr})),
              Text(tr('lv_$cefr'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Tx.ink)),
              Text(
                tr('lessonsOf', {'d': nd, 't': tot}) +
                    (ex?['passed'] == true ? tr('examPassedS') : '') +
                    (course.free(cefr) ? tr('passedPlacement') : ''),
                style: TextStyle(fontSize: 12.5, color: Tx.muted),
              ),
              const SizedBox(height: 6),
              ProgressLine(tot == 0 ? 0 : nd / tot),
            ]),
          ),
          const SizedBox(width: 10),
          Text(open ? '−' : '+', style: TextStyle(fontFamily: Tx.mono, fontSize: 22, color: Tx.muted)),
        ]),
      ),
    );
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Tx.ink, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        head,
        if (open) ...[
          if (ls.length < tot)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(tr('stagesNote', {'n': ls.length, 't': tot}), style: TextStyle(color: Tx.muted, fontSize: 13)),
            ),
          for (final u in Course.units(lv).where((u) => Course.lessonsOf(u).isNotEmpty)) _unit(u),
          _exam(lv),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }

  Widget _unit(Json u) {
    final ls = [for (final l in Course.lessonsOf(u)) course.lessonById(l['id'])!];
    final ud = ls.where((l) => course.isDone(l['id'])).length;
    final next = course.nextLesson;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardBox(
        borderColor: ud == ls.length ? Tx.doneLine : Tx.line,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Kicker(tr('unitN', {'n': pad2((u['order'] as num).toInt())}), color: Tx.blue)),
            Text('$ud/${ls.length}', style: TextStyle(fontFamily: Tx.mono, fontSize: 12, color: Tx.muted)),
          ]),
          const SizedBox(height: 6),
          Text(str(u['title_target']), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
          Text(course.subTitle(u['id'], str(u['title_es']), str(u['title_target'])), style: TextStyle(fontSize: 13, color: Tx.muted)),
          const SizedBox(height: 8),
          for (final l in ls) _row(l, next != null && next['id'] == l['id']),
        ]),
      ),
    );
  }

  Widget _row(Json l, bool cur) {
    final done = course.isDone(l['id']);
    final ok = course.unlocked(l);
    final cp = l['kind'] == 'checkpoint';
    final sub = course.subTitle(l['id'], str(l['title_es']), str(l['title_target']));
    final state = done
        ? Text('✓ ${pct(course.scoreOf(l['id']))}', style: TextStyle(color: Tx.ok, fontWeight: FontWeight.w600, fontSize: 13))
        : !ok
            ? Text(tr('lockedW'), style: TextStyle(color: Tx.faint, fontSize: 13))
            : Text(tr(cur ? 'startArrow' : 'openArrow'), style: TextStyle(color: Tx.blue, fontWeight: FontWeight.w600, fontSize: 13));
    return InkWell(
      onTap: ok ? () => _lesson(l) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: cur ? Tx.blueSoft : null,
          borderRadius: cur ? BorderRadius.circular(8) : null,
          border: cur ? null : Border(top: BorderSide(color: Tx.line)),
        ),
        child: Row(children: [
          SizedBox(
            width: 30,
            child: Text(pad2((l['order'] as num).toInt()), style: TextStyle(fontFamily: Tx.mono, fontSize: 12, color: Tx.faint)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(str(l['title_target']), style: TextStyle(fontWeight: FontWeight.w500, color: ok ? Tx.text : Tx.faint)),
              if (cp) Text(tr('checkpointTag').toUpperCase(), style: Tx.kicker.copyWith(fontSize: 10, color: Tx.rust)),
              if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 12.5, color: Tx.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          state,
        ]),
      ),
    );
  }

  Widget _exam(Json lv) {
    final cefr = str(lv['cefr']);
    final ex = progress.exams[cefr] as Map?;
    final open = course.examOpen(lv);
    final exam = lv['exam'] as Map?;
    final ready = exam != null && exam['status'] == 'ready';
    final txt = ex != null
        ? tr(ex['passed'] == true ? 'passedPct' : 'lastTry', {'p': (((ex['pct'] as num?) ?? 0) * 100).round()})
        : !ready
            ? tr('examWhenLevel')
            : open
                ? tr('examQs', {'n': exam?['items'] ?? 30})
                : tr('completeN', {'n': course.levelTotal(lv)});
    return Panel(
      color: Tx.rustSoft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Kicker(tr('finalExam', {'l': cefr}), color: Tx.rust),
        const SizedBox(height: 6),
        Text(txt),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: open ? () => _go(ExamScreen(cefr: cefr)) : null,
          child: Text(tr('takeExam')),
        ),
      ]),
    );
  }
}
