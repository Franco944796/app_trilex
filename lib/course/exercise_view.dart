import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';

/// Un ejercicio del curso (todos los tipos de la web). Llama a [onDone] con el puntaje (0–1)
/// cuando se responde.
///
/// [exam]: muestra el tema a repasar, nunca la respuesta · [optional]: autoevaluación sin nota ·
/// [quiet]: sin corrección visible (prueba de nivel) · [dontKnow]: agrega «No lo sé».
class ExerciseView extends StatefulWidget {
  const ExerciseView({
    super.key,
    required this.ex,
    required this.onDone,
    this.input,
    this.exam = false,
    this.optional = false,
    this.quiet = false,
    this.dontKnow = false,
  });
  final Json ex;
  final Json? input;
  final bool exam, optional, quiet, dontKnow;
  final void Function(double score) onDone;

  @override
  State<ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends State<ExerciseView> {
  Json get e => widget.ex;
  String get type => str(e['type']);
  List<String> get answers => [for (final a in (e['answer'] as List? ?? const [])) '$a'];

  bool done = false;
  String? head; // primera línea del comentario (en negrita)
  final extra = <Widget>[]; // líneas siguientes del comentario
  String fbKind = 'wait'; // ok | bad | half | self

  // estado de cada tipo
  late List<String> options; // opción múltiple / verdadero-falso
  int? picked;
  final input = TextEditingController();
  List<int> pool = [], tray = []; // ordenar palabras (índices de tokens)
  late List<String> rightSide; // unir pares
  int? selLeft;
  final matched = <int>{}; // índices de la izquierda ya unidos
  int? flashBad; // índice que parpadea en rojo
  int mistakes = 0;
  late List<Json> items; // clasificar
  int? selItem;
  final placed = <int, String>{};
  String? flashCat;
  String warn = ''; // escritura
  final checks = <int>{};
  final role = <int, int>{}; // rol: turno → opción elegida
  final roleOrder = <int, List<int>>{};
  int roleGood = 0;
  Timer? _flash;

  @override
  void initState() {
    super.initState();
    if (type == 'true_false') {
      options = [tr('trueW'), tr('falseW')];
    } else {
      final o = strList(e['options']);
      options = e['fixed'] == true ? o : shuffled(o);
    }
    if (widget.dontKnow && (type == 'multiple_choice' || type == 'listening' || type == 'true_false')) {
      options = [...options, ''];
    }
    if (type == 'word_order') pool = shuffled(List.generate(strList(e['tokens']).length, (i) => i));
    rightSide = shuffled([for (final p in jsonList(e['pairs'])) str(p['right'])]);
    items = shuffled(jsonList(e['items']));
  }

  @override
  void dispose() {
    input.dispose();
    _flash?.cancel();
    super.dispose();
  }

  String _fb(String x) => x.replaceFirst(RegExp(r'^¡Correcto!'), tr('correctEx')).replaceFirst(RegExp(r'^Revisa esto:'), tr('reviewThis'));

  /// Tema que hay que repasar para una pregunta del examen (sin la respuesta).
  String _reviewText() {
    final r = e['review'];
    if (r is! Map) return tr('reviewTheory');
    final lesson = str(r['lesson']);
    final o = lesson.isNotEmpty && !i18n.isEs ? course.ovLesson(lesson) : null;
    final topic = o != null ? str(o['topic'] ?? o['title']) : str(r['topic_es']);
    if (lesson.isEmpty) return topic;
    return '$topic · ${tr('unitLesson', {'u': r['unit'], 'l': r['order']})}: ${o != null ? str(o['title']) : str(r['lesson_es'])}';
  }

  void fin(double s, [List<Widget> more = const []]) {
    if (done) return;
    done = true;
    if (widget.quiet) {
      widget.onDone(s);
      return;
    }
    final selfCheck = widget.optional || type == 'writing' || type == 'pronunciation';
    final fb = e['feedback'] as Map?;
    final why = fb == null ? '' : str(fb['incorrect']).replaceFirst(RegExp(r'^Revisa esto:\s*'), '');
    setState(() {
      fbKind = selfCheck ? 'self' : (s >= 1 ? 'ok' : (s > 0 ? 'half' : 'bad'));
      extra.clear();
      if (widget.exam) {
        head = s >= 1 ? _fb(fb != null ? str(fb['correct']) : tr('correctEx')) : '${tr('reviewThis')} ${_reviewText()}';
      } else if (selfCheck) {
        head = why.isEmpty ? null : why;
        extra.addAll(more);
      } else {
        head = fb == null ? null : _fb(str(s >= 1 ? fb['correct'] : fb['incorrect']));
        extra.addAll(more);
      }
    });
    widget.onDone(s);
  }

  Widget _line(String label, String value, {bool italic = false}) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$label '),
          TextSpan(text: value, style: TextStyle(fontWeight: italic ? FontWeight.w400 : FontWeight.w600, fontStyle: italic ? FontStyle.italic : FontStyle.normal)),
        ])),
      );

  // ---------------------------------------------------------------- tipos de ejercicio
  Widget _choice() {
    final listening = type == 'listening';
    final good = type == 'true_false' ? [e['answer'] is List && (e['answer'] as List).first == true ? tr('trueW') : tr('falseW')] : answers;
    Color? bg(int i) {
      if (!done || widget.quiet) return null;
      final isGood = good.contains(options[i]);
      final pickedOk = picked != null && good.contains(options[picked!]);
      if (isGood && (pickedOk || !widget.exam)) return Tx.okSoft;
      if (i == picked && !isGood) return Tx.badSoft;
      return null;
    }

    Color fg(int i) => bg(i) == Tx.okSoft ? Tx.ok : (bg(i) == Tx.badSoft ? Tx.bad : Tx.ink);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (listening) _audio(str(e['audio_text'])),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < options.length; i++)
          OutlinedButton(
            onPressed: done
                ? null
                : () {
                    picked = i;
                    final ok = good.contains(options[i]);
                    fin(ok ? 1 : 0, [
                      if (listening) _line(tr('transcript'), str(e['audio_text']), italic: true),
                    ]);
                  },
            style: OutlinedButton.styleFrom(
              backgroundColor: bg(i),
              disabledForegroundColor: fg(i),
              side: BorderSide(color: bg(i) == null ? Tx.line2 : fg(i)),
            ),
            child: Text(options[i].isEmpty ? tr('dontKnow') : options[i]),
          ),
      ]),
    ]);
  }

  Widget _audio(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(spacing: 8, children: [
          SayButton(text, label: '🔊 ${tr('listen')}'),
          SayButton(text, slow: true, label: '🐢 ${tr('speedSlow')}'),
        ]),
      );

  void _checkTyped() {
    final v = input.text;
    if (v.trim().isEmpty) return;
    final cs = e['case_sensitive'] == true;
    final all = [...answers, ...strList(e['accepted_alternatives'])];
    final ok = all.any((a) => normAnswer(a, caseSensitive: cs) == normAnswer(v, caseSensitive: cs));
    final audio = str(e['audio_text']);
    fin(ok ? 1 : 0, [
      if (!ok) _line(tr('answerIs'), answers.isEmpty ? '' : answers.first),
      if (audio.isNotEmpty) _line(tr('transcript'), audio, italic: true),
    ]);
  }

  Widget _typed() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (type == 'error_correction')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border.all(color: Tx.bad), borderRadius: BorderRadius.circular(8)),
            child: Text(str(e['text']), style: TextStyle(color: Tx.bad)),
          ),
        if (str(e['audio_text']).isNotEmpty) _audio(str(e['audio_text'])),
        TextField(
          controller: input,
          enabled: !done,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(hintText: tr('yourAnswer')),
          onSubmitted: (_) => _checkTyped(),
        ),
      ]);

  Widget _chip(String label, VoidCallback? onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 11)),
        child: Text(label),
      );

  void _checkOrder() {
    if (tray.isEmpty) return;
    final tokens = strList(e['tokens']);
    final got = tray.map((i) => tokens[i]).join(' ');
    final ok = got == answers.join(' ');
    fin(ok ? 1 : 0, [if (!ok) _line(tr('correctOrder'), sentence(answers))]);
  }

  Widget _wordOrder() {
    final tokens = strList(e['tokens']);
    Widget box(List<int> list, bool isTray) => Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isTray ? Tx.surface : Tx.grey,
            border: Border.all(color: isTray ? Tx.line2 : Tx.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final i in list)
              _chip(
                tokens[i],
                done
                    ? null
                    : () => setState(() {
                          if (isTray) {
                            tray.remove(i);
                            pool.add(i);
                          } else {
                            pool.remove(i);
                            tray.add(i);
                          }
                        }),
              ),
          ]),
        );
    return Column(children: [box(tray, true), box(pool, false)]);
  }

  void _flashOff() {
    _flash?.cancel();
    _flash = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => flashBad = null);
    });
  }

  Widget _pairButton(String label, {bool sel = false, bool ok = false, bool bad = false, VoidCallback? onTap}) {
    final bg = ok ? Tx.okSoft : (bad ? Tx.badSoft : (sel ? Tx.blueSoft : null));
    final fg = ok ? Tx.ok : (bad ? Tx.bad : Tx.ink);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledForegroundColor: fg,
            side: BorderSide(color: ok ? Tx.ok : (bad ? Tx.bad : (sel ? Tx.blue : Tx.line2))),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _matching() {
    final pairs = jsonList(e['pairs']);
    final doneRight = {for (final i in matched) str(pairs[i]['right'])};
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(children: [
          for (var i = 0; i < pairs.length; i++)
            _pairButton(
              str(pairs[i]['left']),
              sel: selLeft == i,
              ok: matched.contains(i),
              onTap: matched.contains(i) || done ? null : () => setState(() => selLeft = i),
            ),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(children: [
          for (var j = 0; j < rightSide.length; j++)
            _pairButton(
              rightSide[j],
              ok: doneRight.contains(rightSide[j]),
              bad: flashBad == j,
              onTap: doneRight.contains(rightSide[j]) || done || selLeft == null
                  ? null
                  : () {
                      final l = selLeft!;
                      final ok = pairs.any((p) => p['left'] == pairs[l]['left'] && p['right'] == rightSide[j]);
                      setState(() {
                        if (ok) {
                          matched.add(l);
                          selLeft = null;
                        } else {
                          mistakes++;
                          flashBad = j;
                          _flashOff();
                        }
                      });
                      if (ok && matched.length == pairs.length) {
                        final n = pairs.length;
                        fin((1 - mistakes / n).clamp(0, 1).toDouble(), [if (mistakes > 0) _line(tr('mistakes'), '$mistakes')]);
                      }
                    },
            ),
        ]),
      ),
    ]);
  }

  Widget _categorize() {
    final cats = strList(e['categories']);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('tapCategory'), style: TextStyle(fontSize: 13, color: Tx.muted)),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(children: [
            for (var i = 0; i < items.length; i++)
              _pairButton(
                placed[i] != null ? '${str(items[i]['text'])} → ${placed[i]}' : str(items[i]['text']),
                sel: selItem == i,
                ok: placed[i] != null,
                onTap: placed[i] != null || done ? null : () => setState(() => selItem = i),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(children: [
            for (final c in cats)
              _pairButton(
                c,
                bad: flashCat == c,
                onTap: done || selItem == null
                    ? null
                    : () {
                        final i = selItem!;
                        final ok = items[i]['category'] == c;
                        setState(() {
                          if (ok) {
                            placed[i] = c;
                            selItem = null;
                          } else {
                            mistakes++;
                            flashCat = c;
                            _flash?.cancel();
                            _flash = Timer(const Duration(milliseconds: 450), () {
                              if (mounted) setState(() => flashCat = null);
                            });
                          }
                        });
                        if (ok && placed.length == items.length) {
                          fin((1 - mistakes / items.length).clamp(0, 1).toDouble(),
                              [if (mistakes > 0) _line(tr('mistakes'), '$mistakes')]);
                        }
                      },
              ),
          ]),
        ),
      ]),
    ]);
  }

  Widget _pronunciation() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('pronTipNoRec'), style: TextStyle(fontSize: 13, color: Tx.muted)),
        for (final i in jsonList(e['items']))
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Tx.line))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SayButton(str(i['text'])),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: str(i['text']), style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                    TextSpan(text: '  ${str(i['ipa'])}', style: TextStyle(fontFamily: Tx.mono, fontSize: 12.5, color: Tx.muted)),
                  ])),
                  Text(str(i['tip_es']), style: TextStyle(fontSize: 13, color: Tx.muted)),
                ]),
              ),
            ]),
          ),
      ]);

  void _checkWriting() {
    final need = (e['min_words'] as num?)?.toInt() ?? 8;
    final ws = input.text.split(RegExp(r'\s+')).where((w) => RegExp('[A-Za-z]').hasMatch(w)).toList();
    final uniq = ws.map((w) => w.toLowerCase().replaceAll(RegExp(r"[^a-z']"), '')).toSet().length;
    final minUniq = (need / 3).ceil() > 3 ? (need / 3).ceil() : 3;
    if (ws.length < need || uniq < minUniq) {
      setState(() => warn = tr('writeMore', {'n': need, 'w': ws.length, 'rep': ws.length >= need ? tr('tooRepeated') : ''}));
      return;
    }
    setState(() => warn = '');
    fin(1, [
      _line(tr('modelCompare'), str(e['model_answer']), italic: true),
      Padding(padding: const EdgeInsets.only(top: 8), child: Text(tr('checkText'))),
      _CheckList(items: strList(e['self_check_es'])),
    ]);
  }

  Widget _writing() {
    final need = (e['min_words'] as num?)?.toInt() ?? 8;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: input, enabled: !done, minLines: 4, maxLines: 8, decoration: InputDecoration(hintText: tr('yourText'))),
      const SizedBox(height: 4),
      Text(tr('minWords', {'n': need}), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
      if (warn.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(warn, style: TextStyle(color: Tx.bad))),
    ]);
  }

  Widget _roleplay() {
    final turns = jsonList(e['turns']);
    final out = <Widget>[
      Panel(padding: const EdgeInsets.all(12), child: Text(str(e['situation_es']))),
      const SizedBox(height: 8),
    ];
    final nChoices = turns.where((t) => t['choices'] is List).length;
    for (var i = 0; i < turns.length; i++) {
      final t = turns[i];
      if (t['choices'] is! List) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text.rich(TextSpan(children: [
              TextSpan(text: '${str(t['speaker'])}: ', style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
              TextSpan(text: str(t['text'])),
            ]))),
            SayButton(str(t['text'])),
          ]),
        ));
        continue;
      }
      final choices = strList(t['choices']);
      final best = (t['best'] as num?)?.toInt() ?? 0;
      final order = roleOrder.putIfAbsent(i, () => shuffled(List.generate(choices.length, (k) => k)));
      final chosen = role[i];
      out.add(Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Text(tr('you'), style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
      ));
      out.add(Wrap(spacing: 8, runSpacing: 8, children: [
        for (final k in order)
          OutlinedButton(
            onPressed: chosen != null
                ? null
                : () {
                    setState(() {
                      role[i] = k;
                      if (k == best) roleGood++;
                    });
                    if (role.length == nChoices) fin(nChoices == 0 ? 1 : roleGood / nChoices);
                  },
            style: OutlinedButton.styleFrom(
              backgroundColor: chosen == null ? null : (k == best ? Tx.okSoft : (k == chosen ? Tx.badSoft : null)),
              disabledForegroundColor: chosen == null ? null : (k == best ? Tx.ok : (k == chosen ? Tx.bad : Tx.muted)),
            ),
            child: Text(choices[k]),
          ),
      ]));
      if (chosen == null) break; // los turnos siguientes aparecen al responder
      out.add(Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.only(left: 10),
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: Tx.line2, width: 2))),
        child: Text(str(t['why_es']), style: TextStyle(fontSize: 13, color: Tx.muted)),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: out);
  }

  // ---------------------------------------------------------------- vista
  @override
  Widget build(BuildContext context) {
    Widget body;
    VoidCallback? check;
    String checkLabel = tr('check');
    switch (type) {
      case 'multiple_choice':
      case 'listening':
      case 'true_false':
        body = _choice();
      case 'fill_blank':
      case 'translation':
      case 'error_correction':
      case 'dictation':
        body = _typed();
        check = _checkTyped;
      case 'word_order':
        body = _wordOrder();
        check = _checkOrder;
      case 'matching':
        body = _matching();
      case 'categorize':
        body = _categorize();
      case 'pronunciation':
        body = _pronunciation();
        check = () => fin(1);
        checkLabel = tr('practised');
      case 'writing':
        body = _writing();
        check = _checkWriting;
        checkLabel = tr('compareModel');
      case 'roleplay':
        body = _roleplay();
      default:
        body = Text(type);
    }
    final inp = widget.input;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (str(e['passage']).isNotEmpty) ...[
        Panel(padding: const EdgeInsets.all(12), child: Text(str(e['passage']))),
        const SizedBox(height: 10),
      ],
      Text(str(e['prompt']), style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: Tx.ink, height: 1.4)),
      if (e['refers_to_input'] == true && inp != null)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            dense: true,
            title: Text(tr('seeText'), style: TextStyle(color: Tx.blue, fontWeight: FontWeight.w500, fontSize: 14)),
            children: [InputText(input: inp, plain: true)],
          ),
        ),
      const SizedBox(height: 10),
      body,
      if (check != null && !done) ...[
        const SizedBox(height: 12),
        FilledButton(onPressed: check, child: Text(checkLabel)),
      ],
      if (!widget.quiet) _feedback(),
    ]);
  }

  Widget _feedback() {
    final colors = {
      'wait': [Tx.grey, Tx.muted],
      'ok': [Tx.okSoft, Tx.ok],
      'bad': [Tx.badSoft, Tx.bad],
      'half': [Tx.halfSoft, Tx.half],
      'self': [Tx.grey, Tx.ink],
    }[fbKind]!;
    final children = <Widget>[
      if (!done) Text(tr('answerToSee'), style: TextStyle(color: colors[1], fontSize: 13.5)),
      if (done && head != null) Text(head!, style: TextStyle(fontWeight: FontWeight.w600, color: colors[1])),
      ...extra,
    ];
    if (children.isEmpty) return const SizedBox(height: 4);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(8)),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: 14, height: 1.4, color: Tx.text),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

/// Lista de control de la escritura (se marca, no se guarda).
class _CheckList extends StatefulWidget {
  const _CheckList({required this.items});
  final List<String> items;
  @override
  State<_CheckList> createState() => _CheckListState();
}

class _CheckListState extends State<_CheckList> {
  final on = <int>{};
  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < widget.items.length; i++)
          CheckboxListTile(
            value: on.contains(i),
            onChanged: (v) => setState(() => v == true ? on.add(i) : on.remove(i)),
            title: Text(widget.items[i], style: const TextStyle(fontSize: 14)),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ]);
}

/// Texto o diálogo de entrada de una lección (con audio, salvo en [plain]).
class InputText extends StatelessWidget {
  const InputText({super.key, required this.input, this.plain = false});
  final Json input;
  final bool plain;

  Widget _line(String speaker, String text, String es) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!plain) ...[SayButton(text), const SizedBox(width: 10)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                if (speaker.isNotEmpty) TextSpan(text: '$speaker: ', style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                TextSpan(text: text),
              ]), style: const TextStyle(fontSize: 15.5, height: 1.45)),
              if (es.isNotEmpty) Text(es, style: TextStyle(fontSize: 13, color: Tx.muted, height: 1.4)),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final type = str(input['type']);
    if (type == 'dialogue') {
      return Column(children: [for (final l in jsonList(input['lines'])) _line(str(l['speaker']), str(l['text']), str(l['es']))]);
    }
    if (type == 'text') return _line('', str(input['text']), str(input['es']));
    final recap = str(input['recap_es']);
    return recap.isEmpty ? const SizedBox.shrink() : Text(recap);
  }
}
