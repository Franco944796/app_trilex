import 'dart:math';

typedef Json = Map<String, dynamic>;

List<Json> jsonList(dynamic x) => x is List ? x.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList() : <Json>[];

List<String> strList(dynamic x) => x is List ? x.map((e) => '$e').toList() : <String>[];

String str(dynamic x) => x == null ? '' : '$x';

/// Campos que en el JSON son una lista de líneas (para que los archivos sean legibles) y que la
/// app vuelve a unir en un único texto, igual que la web.
const multilineKeys = {'md', 'md_es', 'text', 'es', 'model_answer'};

dynamic joinLines(dynamic v) {
  if (v is Map) {
    final out = <String, dynamic>{};
    v.forEach((k, x) {
      if (multilineKeys.contains(k) && x is List && x.every((e) => e is String)) {
        out['$k'] = x.join('\n');
      } else {
        out['$k'] = joinLines(x);
      }
    });
    return out;
  }
  if (v is List) return v.map(joinLines).toList();
  return v;
}

final _rand = Random();
List<T> shuffled<T>(List<T> a) {
  final b = List<T>.of(a);
  b.shuffle(_rand);
  return b;
}

String pad2(int n) => n.toString().padLeft(2, '0');
String pct(num x) => '${(x * 100).round()} %';

String fmtScore(num x) {
  final r = (x * 10).round() / 10;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
}

/// Normalización de las respuestas escritas (ver README del contenido): minúsculas, espacios,
/// apóstrofos tipográficos, puntuación final y apóstrofos fuera.
String normAnswer(String s, {bool caseSensitive = false}) {
  var t = s.replaceAll(RegExp('[’‘`]'), "'").replaceAll(RegExp(r'\s+'), ' ').trim();
  if (!caseSensitive) t = t.toLowerCase();
  return t.replaceAll(RegExp(r'[.?!]+$'), '').replaceAll("'", '').trim();
}

/// Normalización de una palabra del lector para buscarla en los diccionarios
/// (igual que tools/i18n_build.py y la web).
String normWord(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[’‘`]'), "'")
    .replaceAll(RegExp(r"[^a-z' -]"), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String sentence(List<String> tokens) => tokens.join(' ').replaceAllMapped(RegExp(r' ([.,?!;:])'), (m) => m[1]!);

int dayNumber([DateTime? d]) => (d ?? DateTime.now()).millisecondsSinceEpoch ~/ 86400000;

String dayKey(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';

/// Mismo orden que shuffled() en ingles/lector.js.
List<T> seededShuffle<T>(List<T> a, String seed) {
  var s = 0;
  for (final c in seed.codeUnits) {
    s = (s * 31 + c) & 0xFFFFFFFF;
  }
  final keyed = [
    for (final x in a) (x, s = (s * 1664525 + 1013904223) & 0xFFFFFFFF),
  ];
  keyed.sort((p, q) => p.$2.compareTo(q.$2));
  return [for (final k in keyed) k.$1];
}
