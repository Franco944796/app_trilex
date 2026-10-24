import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';
import 'lesson_screen.dart';
import 'practice.dart';

/// Examen final de un nivel: misma cuadrícula de ejercicios, sin dar las respuestas.
/// Al terminar muestra el resultado, los temas para repasar y las tareas opcionales.
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.cefr});
  final String cefr;
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Json? exam;
  Object? error;
  Widget? result;
  final resultKey = GlobalKey();

  Json get lv => course.levelOf(widget.cefr);

  @override
  void initState() {
    super.initState();
    content.obj(str((lv['exam'] as Map)['file'])).then(
          (v) {
            if (mounted) setState(() => exam = course.localizeExam(v));
          },
          onError: (Object e) {
            if (mounted) setState(() => error = e);
          },
        );
  }

  String _instr(Json e) {
    final n = jsonList(e['exercises']).length;
    final pass = (e['pass_score'] as num?)?.toDouble() ?? 0.75;
    return tr('examInstr', {'n': n, 'u': Course.units(lv).length, 'l': widget.cefr, 'k': (pass * n).ceil()});
  }

  String _topic(Json r) {
    final lesson = str(r['lesson']);
    final o = lesson.isNotEmpty && !i18n.isEs ? course.ovLesson(lesson) : null;
    final topic = o != null ? str(o['topic'] ?? o['title']) : str(r['topic_es']);
    return lesson.isEmpty ? topic : '$topic · ${tr('unitLesson', {'u': r['unit'], 'l': r['order']})}';
  }

  void _finish(Json e, double sc, int n, List<double?> res) {
    final p = n == 0 ? 0.0 : sc / n;
    final pass = (e['pass_score'] as num?)?.toDouble() ?? 0.75;
    final ok = p >= pass;
    final before = progress.exams[widget.cefr] as Map?;
    progress.exams[widget.cefr] = {'pct': p, 'passed': ok || before?['passed'] == true, 'at': DateTime.now().millisecondsSinceEpoch};
    progress.save();
    // temas para repasar, con los más fallados primero
    final weak = <String, ({int n, Json r})>{};
    final exs = jsonList(e['exercises']);
    for (var i = 0; i < exs.length; i++) {
      if ((res[i] ?? 0) >= 1) continue;
      final r = exs[i]['review'] is Map ? (exs[i]['review'] as Map).cast<String, dynamic>() : <String, dynamic>{'topic_es': tr('generalReview')};
      final k = str(r['topic_es']);
      weak[k] = (n: (weak[k]?.n ?? 0) + 1, r: r);
    }
    final list = weak.values.toList()..sort((a, b) => b.n.compareTo(a.n));
    setState(() {
      result = Column(key: resultKey, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Panel(
          color: ok ? Tx.blueSoft : Tx.rustSoft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(tr('resultH'), color: ok ? Tx.blue : Tx.rust),
            const SizedBox(height: 6),
            Text('${fmtScore(sc)} / $n', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: Tx.ink)),
            Text('${pct(p)} · ${ok ? tr('examPassedMsg', {'l': widget.cefr}) : tr('examNeed', {'n': (pass * n).ceil()})}'),
          ]),
        ),
        if (list.isNotEmpty) ...[
          const SizedBox(height: 14),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Kicker(tr('topicsReview')),
              for (final w in list)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Tx.line))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_topic(w.r)}  (${w.n} ${tr(w.n == 1 ? 'question1' : 'questionsW')})'),
                    if (str(w.r['lesson']).isNotEmpty && course.lessonById(str(w.r['lesson'])) != null)
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => LessonScreen(lesson: course.lessonById(str(w.r['lesson']))!)),
                        ),
                        child: Text(tr('goLesson')),
                      ),
                  ]),
                ),
            ]),
          ),
        ],
        if (jsonList(e['optional_tasks']).isNotEmpty) ...[
          SectionTitle(tr('optTasks')),
          Practice(exercises: jsonList(e['optional_tasks']), optional: true),
        ],
      ]);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = resultKey.currentContext;
      if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 400));
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = exam;
    return Scaffold(
      appBar: AppBar(title: Text(tr('examTitle', {'l': widget.cefr}))),
      body: e == null
          ? (error != null ? LoadError(error!) : const Center(child: CircularProgressIndicator()))
          : PageList(children: [
              PageHeader(
                kicker: tr('levelX', {'l': widget.cefr, 'n': tr('lv_${widget.cefr}')}),
                title: tr('examTitle', {'l': widget.cefr}),
                lede: _instr(e),
              ),
              Practice(
                exercises: jsonList(e['exercises']),
                exam: true,
                onProgress: (s, a) {
                  if (a == 0 && result != null) setState(() => result = null); // reiniciado
                },
                onFinished: (sc, n, res) => _finish(e, sc, n, res),
              ),
              if (result != null) result!,
            ]),
    );
  }
}
