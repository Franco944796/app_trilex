import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';

/// Vocabulario del curso por temas, con filtro por nivel y búsqueda.
class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});
  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  // nombres de los temas en español (la web usa la misma tabla)
  static const topicEs = {
    'greetings': 'Saludos', 'alphabet': 'Alfabeto', 'numbers': 'Números', 'age': 'Edad',
    'countries': 'Países y nacionalidades', 'to-be': 'Verbo to be', 'jobs': 'Trabajos', 'family': 'Familia',
    'possessives': 'Posesivos', 'have-got': 'Have got', 'adjectives': 'Adjetivos', 'routine': 'Rutina diaria',
    'time': 'La hora', 'present-simple': 'Presente simple', 'days': 'Días de la semana', 'food': 'Comida y bebida',
    'plurals': 'Plurales', 'likes': 'Gustos', 'meals': 'Comidas del día', 'cafe': 'En el café', 'home': 'La casa',
    'there-is': 'There is / there are', 'prepositions': 'Preposiciones de lugar', 'colours': 'Colores',
    'town': 'La ciudad', 'directions': 'Direcciones', 'transport': 'Transporte', 'imperatives': 'Imperativos',
    'prices': 'Precios', 'clothes': 'Ropa', 'this-that': 'This / that', 'shop': 'De compras', 'hobbies': 'Aficiones',
    'can': 'Can (habilidad)', 'present-continuous': 'Presente continuo', 'invitations': 'Invitaciones',
    'weather': 'El clima', 'months': 'Meses', 'dates': 'Fechas', 'plans': 'Planes', 'objects': 'Objetos cotidianos',
    'past-simple': 'Pasado simple', 'travel': 'Viajes', 'comparing': 'Comparar', 'quantities': 'Comida y cantidades',
    'future': 'Futuro', 'health-rules': 'Salud y reglas', 'work-study': 'Trabajo y estudios', 'experiences': 'Experiencias',
    'technology': 'Tecnología', 'opinions': 'Opiniones y sentimientos', 'getting-around': 'Moverse por la ciudad',
    'leisure': 'Tiempo libre', 'life-stories': 'Historias de vida', 'places': 'Lugares', 'careers': 'Carreras',
    'lifestyle': 'Estilo de vida', 'media': 'Medios', 'tourism': 'Turismo', 'money': 'Dinero', 'education': 'Educación',
    'environment': 'Medio ambiente', 'culture': 'Cultura y tradiciones', 'relationships': 'Relaciones',
    'achievements': 'Retos y logros', 'identity': 'Identidad', 'workplace': 'Mundo laboral', 'news': 'Noticias y medios',
    'science': 'Ciencia', 'wellbeing': 'Bienestar', 'culture-travel': 'Viajes y culturas', 'economy': 'Economía',
    'society': 'Sociedad', 'planet': 'Planeta', 'arts': 'Arte y cultura', 'law': 'Ley y sociedad',
    'communication': 'Comunicación', 'adventure': 'Aventura y riesgo', 'global': 'Temas globales',
  };

  final all = <Json>[];
  String level = '', query = '';
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    () async {
      for (final lv in course.ready) {
        final v = await content.obj('vocab/${str(lv['cefr']).toLowerCase()}.json');
        all.addAll(jsonList(v['items']).map((w) => {...w, 'lv': lv['cefr']}));
      }
      if (mounted) setState(() => loaded = true);
    }();
  }

  String _name(String t) {
    if (i18n.isEs && topicEs[t] != null) return topicEs[t]!;
    if (t.isEmpty || t == 'otros') return tr('others');
    final s = t.replaceAll('-', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final by = <String, List<Json>>{};
    final q = query.trim().toLowerCase();
    for (final w in all) {
      if (level.isNotEmpty && w['lv'] != level) continue;
      if (q.isNotEmpty && !'${w['lemma']} ${course.meaning(w)}'.toLowerCase().contains(q)) continue;
      by.putIfAbsent(str(w['topic']).isEmpty ? 'otros' : str(w['topic']), () => []).add(w);
    }
    final topics = by.keys.toList()..sort((a, b) => _name(a).compareTo(_name(b)));
    return Scaffold(
      appBar: AppBar(title: Text(tr('vocabT'))),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : PageList(children: [
              PageHeader(kicker: tr('toolsH'), title: tr('vocabByTopic'), lede: tr('wordsCount', {'n': all.length})),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ChoiceChip(label: Text(tr('all')), selected: level.isEmpty, onSelected: (_) => setState(() => level = '')),
                for (final lv in course.ready)
                  ChoiceChip(
                    label: Text(str(lv['cefr'])),
                    selected: level == lv['cefr'],
                    onSelected: (_) => setState(() => level = str(lv['cefr'])),
                  ),
              ]),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(hintText: tr('searchPh'), prefixIcon: const Icon(Icons.search, size: 20)),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 10),
              if (topics.isEmpty) Text(tr('noResults')),
              for (final t in topics)
                ExpansionTile(
                  key: ValueKey('$t-${q.isNotEmpty}'),
                  initiallyExpanded: q.isNotEmpty,
                  tilePadding: EdgeInsets.zero,
                  title: Text.rich(TextSpan(children: [
                    TextSpan(text: _name(t), style: TextStyle(fontWeight: FontWeight.w500, color: Tx.ink)),
                    TextSpan(text: '  ${by[t]!.length}', style: TextStyle(fontFamily: Tx.mono, fontSize: 12, color: Tx.muted)),
                  ])),
                  children: [for (final w in by[t]!) _row(w)],
                ),
            ]),
    );
  }

  Widget _row(Json w) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Tx.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SayButton(str(w['lemma'])),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: str(w['lemma']), style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                TextSpan(text: '  ${str(w['pos'])} · ${w['lv']}  ', style: TextStyle(fontSize: 12, color: Tx.muted)),
                TextSpan(text: str(w['ipa']), style: TextStyle(fontFamily: Tx.mono, fontSize: 12, color: Tx.muted)),
              ])),
              Text(course.meaning(w)),
              Text(str(w['example']), style: TextStyle(fontSize: 13, color: Tx.muted, fontStyle: FontStyle.italic)),
            ]),
          ),
        ]),
      );
}
