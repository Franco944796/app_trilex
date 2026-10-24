import '../core/services.dart';
import '../core/util.dart';

/// Datos del curso (content/en/path.json), reglas de desbloqueo y traducciones del contenido
/// (content/en/i18n/<idioma>/<nivel>.json). Es la misma lógica que la web (ingles/trilex.js).
class Course {
  List<Json> levels = []; // todos los niveles de path.json
  List<Json> ready = []; // niveles con lecciones publicadas
  List<Json> flat = []; // lecciones publicadas en orden, con 'cefr'

  Future<void> load() async {
    final p = await content.obj('path.json');
    levels = jsonList(p['levels']);
    ready = levels.where((l) => units(l).any((u) => lessonsOf(u).isNotEmpty)).toList();
    flat = [
      for (final lv in ready)
        for (final u in units(lv))
          for (final l in lessonsOf(u)) {...l, 'cefr': lv['cefr']},
    ];
    await loadPacks();
  }

  static List<Json> units(Json lv) => jsonList(lv['units']);
  static List<Json> lessonsOf(Json u) => jsonList(u['lessons']).where((l) => l['status'] == 'ready').toList();
  int levelTotal(Json lv) => units(lv).fold(0, (a, u) => a + jsonList(u['lessons']).length);
  Json levelOf(String cefr) => ready.firstWhere((l) => l['cefr'] == cefr);
  Json unitOf(Json lesson) => units(levelOf(lesson['cefr'])).firstWhere((u) => jsonList(u['lessons']).any((x) => x['id'] == lesson['id']));
  Json? lessonById(String id) {
    for (final l in flat) {
      if (l['id'] == id) return l;
    }
    return null;
  }

  // ---------- desbloqueo ----------
  bool free(String cefr) => strList(progress.placement?['passed']).contains(cefr);
  bool isDone(String id) => progress.done[id] != null;
  double scoreOf(String id) => ((progress.done[id] as Map?)?['score'] as num?)?.toDouble() ?? 0;

  bool unlocked(Json l) {
    final k = flat.indexWhere((x) => x['id'] == l['id']);
    if (progress.testMode || k <= 0 || free(l['cefr'])) return true;
    final p = flat[k - 1];
    return isDone(p['id']) || (p['cefr'] != l['cefr'] && free(p['cefr']));
  }

  Json? get nextLesson {
    for (final l in flat) {
      if (!isDone(l['id']) && unlocked(l)) return l;
    }
    return null;
  }

  bool examOpen(Json lv) {
    final exam = lv['exam'] as Map?;
    if (exam == null || exam['status'] != 'ready') return false;
    if (progress.testMode || free(lv['cefr'])) return true;
    final ls = flat.where((l) => l['cefr'] == lv['cefr']).toList();
    return ls.length == levelTotal(lv) && ls.every((l) => isDone(l['id']));
  }

  List<String> get dueItems {
    final today = dayNumber();
    return [
      for (final e in progress.srs.entries)
        if (((e.value as Map)['due'] as num? ?? 0) <= today) e.key,
    ];
  }

  // ---------- traducciones del contenido ----------
  final _packs = <String, Json>{}; // nivel → pack del idioma actual
  String _packLang = '';

  Future<void> loadPacks() async {
    final lg = i18n.lang;
    if (lg == _packLang) return;
    _packLang = lg;
    _packs.clear();
    if (lg == 'es') return;
    try {
      final ix = await content.obj('i18n/index.json');
      for (final lvl in strList((ix['langs'] as Map?)?[lg])) {
        try {
          _packs[lvl] = await content.obj('i18n/$lg/$lvl.json');
        } catch (_) {}
      }
    } catch (_) {}
  }

  Json? _pack(String id) {
    final m = RegExp(r'^en-(a1|a2|b1|b2)').firstMatch(id);
    return m == null ? null : _packs[m[1]];
  }

  Json? ovLesson(String id) {
    final l = (_pack(id)?['lessons'] as Map?)?[id];
    return l is Map ? l.cast<String, dynamic>() : null;
  }

  String? ovUnit(String id) => (_pack(id)?['units'] as Map?)?[id] as String?;
  String? ovVocab(String id) => (_pack(id)?['vocab'] as Map?)?[id] as String?;

  /// Título traducido de una unidad o lección ('' si no hay o si es igual al inglés).
  String subTitle(String id, String es, String target) {
    if (i18n.isEs) return es;
    final t = id.contains('-l') ? str(ovLesson(id)?['title']) : (ovUnit(id) ?? '');
    return t.isNotEmpty && t != target ? t : '';
  }

  /// Textos en español de los ejercicios → traducción ("ex" de los packs).
  String exTr(String s) {
    if (s.isEmpty) return s;
    for (final p in _packs.values) {
      final d = p['ex'];
      if (d is Map && d.containsKey(s)) return '${d[s]}';
    }
    return s;
  }

  String _fbTr(String x) {
    final m = RegExp(r'^(¡Correcto!|Revisa esto:)\s*').firstMatch(x);
    return m != null ? '${m[1]} ${exTr(x.substring(m.end))}' : exTr(x);
  }

  /// Copia traducida de un ejercicio: las respuestas en inglés no cambian; las opciones en
  /// español se traducen igual en "options" y en "answer".
  Json localizeEx(Json e) {
    if (i18n.isEs) return e;
    final x = (joinLines(e) as Map).cast<String, dynamic>();
    List<String>? tl(dynamic a) => a is List ? a.map((v) => v is String ? exTr(v) : '$v').toList() : null;
    if (x['prompt'] is String) x['prompt'] = exTr(x['prompt']);
    if (x['situation_es'] is String) x['situation_es'] = exTr(x['situation_es']);
    final fb = x['feedback'];
    if (fb is Map) {
      x['feedback'] = {'correct': _fbTr(str(fb['correct'])), 'incorrect': _fbTr(str(fb['incorrect']))};
    }
    if (x['self_check_es'] is List) x['self_check_es'] = tl(x['self_check_es']);
    if (x['options'] is List) x['options'] = tl(x['options']);
    if (x['answer'] is List) x['answer'] = (x['answer'] as List).map((v) => v is String ? exTr(v) : v).toList();
    for (final i in jsonList(x['items'])) {
      if (i['tip_es'] is String) i['tip_es'] = exTr(i['tip_es']);
    }
    if (x['turns'] is List) {
      x['turns'] = [
        for (final t in jsonList(x['turns'])) {...t, if (t['why_es'] is String) 'why_es': exTr(t['why_es'])},
      ];
    }
    if (x['pairs'] is List) {
      x['pairs'] = [for (final p in jsonList(x['pairs'])) {...p, 'right': exTr(str(p['right']))}];
    }
    return x;
  }

  /// Significado de una palabra del vocabulario en el idioma elegido.
  String meaning(Json w) {
    final es = str(w['translation_es'] ?? w['es']);
    if (i18n.isEs) return es;
    return ovVocab(str(w['id'])) ?? es;
  }

  bool allTranslated(List<Json> g) => i18n.isEs || g.every((w) => ovVocab(str(w['id'])) != null);

  /// Copia de la lección con los textos traducidos (si existen).
  Json localize(Json lesson) {
    if (i18n.isEs) return lesson;
    final o = ovLesson(str(lesson['id']));
    final c = (joinLines(lesson) as Map).cast<String, dynamic>();
    final en = i18n.lang == 'en';
    final n = (c['input'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    c['input'] = n;
    n['glossary'] = [for (final g in jsonList(n['glossary'])) {...g, 'es': meaning(g)}];
    if (n['lines'] is List) {
      final tr = o?['lines'] is List ? o!['lines'] as List : null;
      final lines = jsonList(n['lines']);
      n['lines'] = [
        for (var i = 0; i < lines.length; i++) {...lines[i], 'es': en ? '' : (tr != null && i < tr.length ? tr[i] : lines[i]['es'])},
      ];
    }
    if (n['text'] != null) n['es'] = en ? '' : (o?['text'] ?? n['es']);
    final title = (c['title'] as Map).cast<String, dynamic>();
    c['title'] = title;
    final ex = (c['explanation'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    c['explanation'] = ex;
    if (o != null) {
      title['es'] = o['title'] != null && o['title'] != title['target'] ? o['title'] : '';
      if (o['objective'] != null) c['objective'] = o['objective'];
      if (o['warmup'] != null && c['warmup'] is Map) c['warmup'] = {...(c['warmup'] as Map).cast<String, dynamic>(), 'prompt_es': o['warmup']};
      if (o['recap'] != null) n['recap_es'] = o['recap'];
      if (o['md'] != null) ex['md_es'] = o['md'];
      final mist = o['mist'] is List ? o['mist'] as List : null;
      final cm = jsonList(ex['common_mistakes_es']);
      ex['common_mistakes_es'] = [
        for (var i = 0; i < cm.length; i++) {...cm[i], 'note': mist != null && i < mist.length ? mist[i] : cm[i]['note']},
      ];
      ex['false_friends'] = <dynamic>[]; // los falsos amigos son específicos del español
    } else {
      title['es'] = '';
    }
    ex['common_mistakes_es'] = [
      for (final m in jsonList(ex['common_mistakes_es'])) {...m, 'wrong': exTr(str(m['wrong'])), 'right': exTr(str(m['right']))},
    ];
    c['exercises'] = [for (final e in jsonList(c['exercises'])) localizeEx(e)];
    final sum = c['summary'];
    if (sum is Map && sum['key_phrases'] is List) {
      c['summary'] = {...sum.cast<String, dynamic>(), 'key_phrases': strList(sum['key_phrases']).map(exTr).toList()};
    }
    return c;
  }

  Json localizeExam(Json e) => i18n.isEs
      ? e
      : {
          ...e,
          'exercises': [for (final x in jsonList(e['exercises'])) localizeEx(x)],
          'optional_tasks': [for (final x in jsonList(e['optional_tasks'])) localizeEx(x)],
        };
}

/// Instancia única del curso (se carga al abrir la app).
final course = Course();
