import '../core/services.dart';
import '../core/util.dart';

/// Misma lógica que ingles/trilex.js, salvo que la app es para B1–B2 y el curso es de consulta:
/// solo esos niveles, todas las lecciones abiertas y los exámenes siempre disponibles.
class Course {
  static const appLevels = {'B1', 'B2'};
  List<Json> levels = [];
  List<Json> ready = [];
  List<Json> flat = [];

  Future<void> load() async {
    final p = await content.obj('path.json');
    levels = jsonList(p['levels']);
    ready = levels.where((l) => appLevels.contains(l['cefr']) && units(l).any((u) => lessonsOf(u).isNotEmpty)).toList();
    flat = [
      for (final lv in ready)
        for (final u in units(lv))
          for (final l in lessonsOf(u)) {...l, 'cefr': lv['cefr']},
    ];
    try {
      extras = await content.obj('extras.json');
    } catch (_) {
      extras = {};
    }
    await loadPacks();
  }

  /// content/en/extras.json: resumen modelo por lectura, lectura y texto de dictogloss por unidad.
  Json extras = {};
  String? readingOfUnit(String unitId) => (extras['unit_readings'] as Map?)?[unitId] as String?;
  String? dictoglossOf(String unitId) => (extras['dictogloss'] as Map?)?[unitId] as String?;
  String? summaryOf(String textId) => (extras['summaries'] as Map?)?[textId] as String?;

  /// Unidad cuya lectura recomendada es este texto (para sugerir la gramática relacionada).
  Json? unitForReading(String textId) {
    final m = extras['unit_readings'] as Map?;
    if (m == null) return null;
    for (final lv in ready) {
      for (final u in units(lv)) {
        if (m[u['id']] == textId) return {...u, 'cefr': lv['cefr']};
      }
    }
    return null;
  }

  Json? unitById(String id) {
    for (final lv in ready) {
      for (final u in units(lv)) {
        if (u['id'] == id) return {...u, 'cefr': lv['cefr']};
      }
    }
    return null;
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

  /// B1 está abierto salvo que la prueba de nivel diera menos de B1. B2 se abre al sacar B2 en la prueba
  /// o al aprobar el examen B1; sin prueba hecha queda cerrado.
  bool unlocked(String cefr) {
    if (progress.testMode) return true;
    final pl = progress.placement;
    final passed = strList(pl?['passed']);
    final b1 = pl == null || passed.contains('B1');
    if (cefr == 'B1') return b1;
    return b1 && (passed.contains(cefr) || (progress.exams['B1'] as Map?)?['passed'] == true);
  }
  bool isDone(String id) => progress.done[id] != null;
  double scoreOf(String id) => ((progress.done[id] as Map?)?['score'] as num?)?.toDouble() ?? 0;

  bool examOpen(Json lv) {
    final exam = lv['exam'] as Map?;
    return exam != null && exam['status'] == 'ready';
  }

  List<String> get dueItems {
    final today = dayNumber();
    return [
      for (final e in progress.srs.entries)
        if (((e.value as Map)['due'] as num? ?? 0) <= today) e.key,
    ];
  }

  final _packs = <String, Json>{};
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

  String subTitle(String id, String es, String target) {
    if (i18n.isEs) return es;
    final t = id.contains('-l') ? str(ovLesson(id)?['title']) : (ovUnit(id) ?? '');
    return t.isNotEmpty && t != target ? t : '';
  }

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

  String meaning(Json w) {
    final es = str(w['translation_es'] ?? w['es']);
    if (i18n.isEs) return es;
    return ovVocab(str(w['id'])) ?? es;
  }

  bool allTranslated(List<Json> g) => i18n.isEs || g.every((w) => ovVocab(str(w['id'])) != null);

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

final course = Course();
