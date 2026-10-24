import '../core/services.dart';
import '../core/util.dart';

class WordInfo {
  WordInfo({required this.word, required this.base, this.tr, this.es = '', this.def, this.src = '', this.fallback = false});
  final String word, base, es, src; // src: 'glosario' | 'curso'
  final String? tr; // significado en el idioma elegido (null = no está)
  final String? def;
  final bool fallback;
}

/// Orden de búsqueda igual que la web: glosario del texto, luego vocabulario del curso; otros
/// idiomas desde reading/i18n/<idioma>.json y en.json como definición en inglés sencillo.
class Reading {
  Json? _index;
  Map<String, String>? _voc;
  final _dict = <String, Json>{};
  Map<String, String> gloss = {};

  Future<Json> index() async => _index ??= await content.obj('reading/index.json');

  Future<Map<String, String>> _vocab() async {
    if (_voc != null) return _voc!;
    final m = <String, String>{};
    for (final l in ['a1', 'a2', 'b1', 'b2']) {
      try {
        final v = await content.obj('vocab/$l.json');
        for (final x in jsonList(v['items'])) {
          final k = normWord(str(x['lemma']));
          if (k.isNotEmpty && !m.containsKey(k)) m[k] = str(x['translation_es'] ?? x['es']);
        }
      } catch (_) {}
    }
    return _voc = m;
  }

  Future<Json> dict(String lang) async {
    final hit = _dict[lang];
    if (hit != null) return hit;
    Json d;
    try {
      d = await content.obj('reading/i18n/$lang.json');
    } catch (_) {
      d = {'gloss': <String, dynamic>{}, 'vocab': <String, dynamic>{}};
    }
    return _dict[lang] = d;
  }

  void setGlossary(List<Json> g) {
    gloss = {};
    for (final e in g) {
      final k = normWord(str(e['en']));
      final first = k.split(' ').first;
      gloss[k] = str(e['es']);
      if (first != k) gloss.putIfAbsent(first, () => str(e['es']));
    }
  }

  static List<String> forms(String w) {
    final o = <String>[w];
    void add(String x) {
      if (x.length > 1 && !o.contains(x)) o.add(x);
    }

    String cut(int n) => w.substring(0, w.length - n);
    if (w.endsWith('ies')) add('${cut(3)}y');
    if (w.endsWith('es')) add(cut(2));
    if (w.endsWith('s')) add(cut(1));
    if (w.endsWith('ied')) add('${cut(3)}y');
    if (w.endsWith('ed')) {
      add(cut(2));
      add(cut(1));
      if (RegExp(r'(.)\1ed$').hasMatch(w)) add(cut(3));
    }
    if (w.endsWith('ing')) {
      add(cut(3));
      add('${cut(3)}e');
      if (RegExp(r'(.)\1ing$').hasMatch(w)) add(cut(4));
    }
    if (w.endsWith("'s")) add(cut(2));
    if (w.endsWith('ly')) add(cut(2));
    if (w.endsWith('er')) add(cut(2));
    if (w.endsWith('est')) add(cut(3));
    return o;
  }

  Future<WordInfo?> lookup(String word) async {
    final w = normWord(word).replaceAll(RegExp(r"^'+|'+$"), '');
    if (w.isEmpty) return null;
    final lg = i18n.lang;
    final d = await dict(lg == 'es' ? 'en' : lg);
    final en = await dict('en');
    final voc = await _vocab();
    WordInfo out(String base, String es, String src) {
      final kind = src == 'glosario' ? 'gloss' : 'vocab';
      final own = lg == 'es' ? es : (d[kind] as Map?)?[base] as String?;
      return WordInfo(
        word: w,
        base: base,
        es: es,
        tr: own ?? es,
        fallback: own == null && lg != 'es',
        def: lg == 'en' ? null : (en[kind] as Map?)?[base] as String?,
        src: src,
      );
    }

    for (final f in forms(w)) {
      final g = gloss[f];
      if (g != null) return out(f, g, 'glosario');
    }
    for (final f in forms(w)) {
      final v = voc[f];
      if (v != null) return out(f, v, 'curso');
    }
    return WordInfo(word: w, base: w);
  }

  Future<String> glossMeaning(Json g) async {
    if (i18n.isEs) return str(g['es']);
    final d = await dict(i18n.lang);
    return ((d['gloss'] as Map?)?[normWord(str(g['en']))] as String?) ?? str(g['es']);
  }
}

final reading = Reading();
