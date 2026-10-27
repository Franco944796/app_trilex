import '../core/services.dart';
import '../core/util.dart';

/// Repaso espaciado de las dos fuentes de palabras: las guardadas al leer (progress.words, con
/// box/due dentro de cada palabra) y el vocabulario de las lecciones (progress.srs, por id).
/// Mismos intervalos que la web y que el Repaso del curso.
const srsIntervals = [1, 3, 7, 14, 30, 60];

bool readingWordDue(Map w) => ((w['due'] as num?) ?? 0) <= dayNumber();

int get dueReadingWords => progress.words.whereType<Map>().where(readingWordDue).length;

int dueCourseWords(Set<String> known) {
  final today = dayNumber();
  return progress.srs.entries
      .where((e) => known.contains(e.key) && (((e.value as Map)['due'] as num?) ?? 0) <= today)
      .length;
}

/// Sube una caja si se acertó o vuelve a la 1; [before] es la caja antes de responder, así un
/// «La sabía (error de tipeo)» puede corregir la nota.
void grade(Map item, int before, bool good) {
  final box = good ? (before + 1).clamp(1, srsIntervals.length) : 1;
  item['box'] = box;
  item['due'] = dayNumber() + srsIntervals[box - 1];
}

/// Respuestas aceptadas para un lema del vocabulario: «how do you spell...?», «fall out (with)»,
/// «a / an»… (igual que la web).
List<String> cardAnswers(String lemma) {
  final base = lemma.replaceAll(RegExp(r'\.\.\.|…'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final bare = base.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  final full = base.replaceAll(RegExp('[()]'), '');
  return [base, bare, full, ...base.split(' / '), ...bare.split(' / ')];
}

String cardNorm(String x) => normAnswer(x).replaceAll(RegExp('[,;?]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

bool cardMatches(String lemma, String typed) => cardAnswers(lemma).any((a) => cardNorm(a) == cardNorm(typed));
