import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/content.dart';
import '../core/services.dart';
import '../core/util.dart';
import '../reading/reader_screen.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';
import 'dicto_screen.dart';
import 'exam_screen.dart';
import 'lesson_screen.dart';
import 'placement_screen.dart';

/// Gramática B1–B2 como consulta, por tema, para estudiar lo que haga falta cuando aparece en una lectura.
/// Los niveles se abren según la prueba de nivel y el examen B1 (ver [Course.unlocked]).
class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});
  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  String? _open;

  Future<void> _go(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  String get _myLevel {
    final pl = str(progress.placement?['level']);
    return Course.appLevels.contains(pl) ? pl : 'B1';
  }

  @override
  Widget build(BuildContext context) {
    final pl = progress.placement;
    return PageList(children: [
      PageHeader(kicker: tr('grK'), title: tr('grTitle'), lede: tr('grLede')),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton(
          onPressed: () => _go(const PlacementScreen()),
          child: Text(pl == null ? tr('placementT') : '${tr('placementT')} · ${pl['level']}'),
        ),
      ]),
      const SizedBox(height: 20),
      for (final lv in course.ready) _level(lv, (_open ?? _myLevel) == lv['cefr']),
    ]);
  }

  Widget _level(Json lv, bool open) {
    final cefr = str(lv['cefr']);
    final locked = !course.unlocked(cefr);
    final ls = course.flat.where((l) => l['cefr'] == cefr).toList();
    final nd = ls.where((l) => course.isDone(l['id'])).length;
    final head = InkWell(
      onTap: () => setState(() => _open = open ? '' : cefr),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: Tx.ink), borderRadius: BorderRadius.circular(8)),
            child: Text(locked ? '🔒 $cefr' : cefr, style: TextStyle(fontFamily: Tx.mono, fontWeight: FontWeight.w500, color: Tx.ink)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('lv_$cefr'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Tx.ink)),
              Text(tr('grUnitsDone', {'d': nd, 't': ls.length, 'u': Course.units(lv).length}),
                  style: TextStyle(fontSize: 12.5, color: Tx.muted)),
              const SizedBox(height: 6),
              ProgressLine(ls.isEmpty ? 0 : nd / ls.length),
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
        if (open && locked) ...[
          _locked(cefr),
          const SizedBox(height: 16),
        ] else if (open) ...[
          for (final u in Course.units(lv).where((u) => Course.lessonsOf(u).isNotEmpty)) _unit(u),
          _exam(lv),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }

  Widget _locked(String cefr) {
    final below = cefr == 'B1';
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Kicker(tr('lockedW')),
        const SizedBox(height: 6),
        Text(tr(below ? 'grLockB1' : 'grLockB2')),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (below)
            FilledButton(
              onPressed: () => launchUrl(Uri.parse(Content.siteUrl), mode: LaunchMode.externalApplication),
              child: Text(tr('openWeb')),
            ),
          OutlinedButton(onPressed: () => _go(const PlacementScreen()), child: Text(tr('placementT'))),
        ]),
      ]),
    );
  }

  Widget _unit(Json u) {
    final ls = [for (final l in Course.lessonsOf(u)) course.lessonById(l['id'])!];
    final ud = ls.where((l) => course.isDone(l['id'])).length;
    final reading = course.readingOfUnit(str(u['id']));
    final dg = (progress.course['dicto'] as Map?)?[u['id']] as num?;
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
          for (final l in ls) _row(l),
          const Divider(height: 18),
          Wrap(spacing: 4, runSpacing: 0, children: [
            if (reading != null)
              TextButton(
                onPressed: () => _go(ReaderScreen.text(reading)),
                child: Text('📖 ${tr('grReading')}'),
              ),
            if (course.dictoglossOf(str(u['id'])) != null)
              TextButton(
                onPressed: () => _go(DictoScreen(unitId: str(u['id']))),
                child: Text('🎧 ${tr('dgT')}${dg != null ? ' · ${pct(dg)}' : ''}'),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _row(Json l) {
    final done = course.isDone(l['id']);
    final cp = l['kind'] == 'checkpoint';
    final sub = course.subTitle(l['id'], str(l['title_es']), str(l['title_target']));
    return InkWell(
      onTap: () => _go(LessonScreen(lesson: l)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Tx.line))),
        child: Row(children: [
          SizedBox(
            width: 30,
            child: Text(pad2((l['order'] as num).toInt()), style: TextStyle(fontFamily: Tx.mono, fontSize: 12, color: Tx.faint)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(str(l['title_target']), style: TextStyle(fontWeight: FontWeight.w500, color: Tx.text)),
              if (cp) Text(tr('checkpointTag').toUpperCase(), style: Tx.kicker.copyWith(fontSize: 10, color: Tx.rust)),
              if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 12.5, color: Tx.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          done
              ? Text('✓ ${pct(course.scoreOf(l['id']))}', style: TextStyle(color: Tx.ok, fontWeight: FontWeight.w600, fontSize: 13))
              : Text(tr('openArrow'), style: TextStyle(color: Tx.blue, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _exam(Json lv) {
    final cefr = str(lv['cefr']);
    final ex = progress.exams[cefr] as Map?;
    final exam = lv['exam'] as Map?;
    if (!course.examOpen(lv)) return const SizedBox.shrink();
    final txt = ex != null
        ? tr(ex['passed'] == true ? 'passedPct' : 'lastTry', {'p': (((ex['pct'] as num?) ?? 0) * 100).round()})
        : tr('grExamLede', {'n': exam?['items'] ?? 30});
    return Panel(
      color: Tx.rustSoft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Kicker(tr('finalExam', {'l': cefr}), color: Tx.rust),
        const SizedBox(height: 6),
        Text(txt),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => _go(ExamScreen(cefr: cefr)), child: Text(tr('takeExam'))),
      ]),
    );
  }
}
