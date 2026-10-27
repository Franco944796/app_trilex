import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/voice_clip.dart';
import '../ui/widgets.dart';

/// Actividades de después de leer (las mismas que la web, en ingles/lector.js).

/// Corta solo antes de mayúscula: «10 p.m. until» queda en una sola oración.
List<String> sentencesOf(String text) => text
    .replaceAll(RegExp(r'\s+'), ' ')
    .split(RegExp(r'''(?<=[.!?]["'”’)]?)\s+(?=["'“‘(]?[A-Z])'''))
    .map((x) => x.trim())
    .where((x) => RegExp('[A-Za-z]').hasMatch(x))
    .toList();

int wordCount(String v) => RegExp(r"[A-Za-z’']+").allMatches(v).length;

String clock(num sec) {
  final t = sec < 0 ? 0 : sec.floor();
  return '${t ~/ 60}:${pad2(t % 60)}';
}

/// Escuchar y repetir (shadowing), una oración por vez, con grabación para compararse.
class ShadowSection extends StatefulWidget {
  const ShadowSection({super.key, required this.sentences});
  final List<String> sentences;
  @override
  State<ShadowSection> createState() => _ShadowSectionState();
}

class _ShadowSectionState extends State<ShadowSection> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.sentences;
    if (s.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(tr('shH'), lede: tr('shLede')),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('shOf', {'i': i + 1, 'n': s.length}), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
          const SizedBox(height: 8),
          Text(s[i], style: TextStyle(fontFamily: Tx.serif, fontSize: 18, height: 1.6, color: Tx.ink)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: () => speech.say(s[i], rate: progress.rate), child: Text('🔊 ${tr('shListen')}')),
            OutlinedButton(onPressed: () => speech.say(s[i], rate: 0.6), child: Text('🐢 ${tr('shSlow')}')),
          ]),
          const SizedBox(height: 8),
          // una grabación por oración: la clave hace que se reinicie al cambiar de oración
          VoiceClip(key: ValueKey(i)),
          const SizedBox(height: 12),
          Row(children: [
            OutlinedButton(onPressed: i == 0 ? null : () => setState(() => i--), child: Text(tr('shPrev'))),
            const Spacer(),
            OutlinedButton(onPressed: i >= s.length - 1 ? null : () => setState(() => i++), child: Text(tr('shNext'))),
          ]),
        ]),
      ),
    ]);
  }
}

typedef ClozeItem = ({String before, String answer, String after, String base, String hint});

/// Oraciones del propio texto sin las palabras del glosario (como mucho 6, en orden).
List<ClozeItem> clozeItems(List<Json> glossary, List<String> sentences, Map<String, String> meanings) {
  final used = <int>{};
  final found = <(int, ClozeItem)>[];
  for (final g in glossary) {
    if (found.length >= 6) break;
    final en = str(g['en']);
    final re = RegExp('\\b${RegExp.escape(en)}\\b', caseSensitive: false);
    for (var k = 0; k < sentences.length; k++) {
      if (used.contains(k)) continue;
      final m = re.firstMatch(sentences[k]);
      if (m == null) continue;
      used.add(k);
      found.add((
        k,
        (
          before: sentences[k].substring(0, m.start),
          answer: m[0]!,
          after: sentences[k].substring(m.end),
          base: en,
          hint: meanings[en] ?? str(g['es']),
        ),
      ));
      break;
    }
  }
  found.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final f in found) f.$2];
}

class ClozeSection extends StatefulWidget {
  const ClozeSection({super.key, required this.items});
  final List<ClozeItem> items;
  @override
  State<ClozeSection> createState() => _ClozeSectionState();
}

class _ClozeSectionState extends State<ClozeSection> {
  late List<bool?> res;
  late List<TextEditingController> ctl;
  int round = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    res = List<bool?>.filled(widget.items.length, null);
    ctl = [for (final _ in widget.items) TextEditingController()];
    round++;
  }

  @override
  void dispose() {
    for (final c in ctl) {
      c.dispose();
    }
    super.dispose();
  }

  void _check(int n) {
    final v = normWord(ctl[n].text);
    if (v.isEmpty || res[n] != null) return;
    final it = widget.items[n];
    setState(() => res[n] = v == normWord(it.answer) || v == normWord(it.base));
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.length < 2) return const SizedBox.shrink();
    final done = res.every((r) => r != null);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(tr('czH'), lede: tr('czLede')),
      for (var n = 0; n < items.length; n++)
        Padding(
          key: ValueKey('$round-$n'),
          padding: const EdgeInsets.only(bottom: 12),
          child: CardBox(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              NumberDot(n + 1),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: items[n].before),
                    TextSpan(text: '_____', style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
                    TextSpan(text: items[n].after),
                  ])),
                  Text(items[n].hint, style: TextStyle(fontSize: 12.5, color: Tx.muted)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: ctl[n],
                        enabled: res[n] == null,
                        autocorrect: false,
                        enableSuggestions: false,
                        onSubmitted: (_) => _check(n),
                        decoration: InputDecoration(hintText: tr('answerLabel'), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: res[n] == null ? () => _check(n) : null, child: Text(tr('check'))),
                  ]),
                  if (res[n] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        res[n]! ? tr('correct') : '${tr('answerIs')} ${items[n].answer}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: res[n]! ? Tx.ok : Tx.bad),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      if (done)
        Row(children: [
          Text('${res.where((r) => r == true).length}/${items.length}',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Tx.ink)),
          const SizedBox(width: 14),
          OutlinedButton(onPressed: () => setState(_reset), child: Text(tr('restart'))),
        ]),
    ]);
  }
}

/// Resumen guiado (solo lecturas graduadas: los modelos están en extras.json).
class SummarySection extends StatefulWidget {
  const SummarySection({super.key, required this.docId, required this.level, required this.model});
  final String docId, level, model;
  @override
  State<SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends State<SummarySection> {
  static const need = {'A1': ('2–3', 15), 'A2': ('3–4', 25), 'B1': ('4–5', 35), 'B2': ('5–6', 45)};
  final ta = TextEditingController();
  String warn = '';
  bool shown = false;

  Map get _sums => (progress.reading['sums'] as Map?) ?? (progress.reading['sums'] = <String, dynamic>{});

  @override
  void initState() {
    super.initState();
    ta.text = str(_sums[widget.docId]);
  }

  @override
  void dispose() {
    ta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (sn, min) = need[widget.level] ?? ('3–5', 25);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(tr('smH'), lede: tr('smLede', {'s': sn})),
      TextField(
        controller: ta,
        minLines: 4,
        maxLines: 10,
        decoration: InputDecoration(hintText: tr('writeHere')),
        onChanged: (v) {
          _sums[widget.docId] = v;
          progress.save();
          setState(() {});
        },
      ),
      const SizedBox(height: 4),
      Text(tr('wordCount', {'n': wordCount(ta.text)}), style: TextStyle(fontSize: 12.5, color: Tx.muted)),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () {
          final w = wordCount(ta.text);
          setState(() {
            warn = w < min ? tr('smNeed', {'n': min, 'w': w}) : '';
            shown = w >= min;
          });
        },
        child: Text(tr('smCompare')),
      ),
      if (warn.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(warn, style: TextStyle(color: Tx.bad))),
      if (shown) ...[
        const SizedBox(height: 12),
        Panel(
          color: Tx.blueSoft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Kicker(tr('smModel'), color: Tx.blue)), SayButton(widget.model)]),
            const SizedBox(height: 6),
            Text(widget.model, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 10),
            Text(tr('smCheckH'), style: const TextStyle(fontWeight: FontWeight.w600)),
            for (final k in ['smC1', 'smC2', 'smC3', 'smC4']) _Check(text: tr(k)),
          ]),
        ),
      ],
    ]);
  }
}

class _Check extends StatefulWidget {
  const _Check({required this.text});
  final String text;
  @override
  State<_Check> createState() => _CheckState();
}

class _CheckState extends State<_Check> {
  bool on = false;
  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: CheckboxListTile(
          value: on,
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(widget.text),
          onChanged: (v) => setState(() => on = v ?? false),
        ),
      );
}

/// Lectura cronometrada: la barra con el tiempo y «Terminé» la muestra el lector abajo.
class TimedReadingCard extends StatelessWidget {
  const TimedReadingCard({super.key, required this.history, required this.running, required this.onStart, this.message = ''});
  final List<int> history;
  final bool running;
  final VoidCallback onStart;
  final String message;

  @override
  Widget build(BuildContext context) {
    final last = history.isEmpty ? null : history.last, first = history.isEmpty ? null : history.first;
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('tmH'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
        const SizedBox(height: 4),
        Text(tr('tmLede'), style: TextStyle(color: Tx.muted, height: 1.4)),
        const SizedBox(height: 10),
        FilledButton(onPressed: running ? null : onStart, child: Text(tr('tmStart'))),
        if (message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(message, style: TextStyle(color: Tx.bad))),
        if (last != null) ...[
          const SizedBox(height: 10),
          Text(tr('tmRes', {'w': last}), style: TextStyle(fontWeight: FontWeight.w600, color: Tx.ink)),
          if (history.length > 1 && first! > 0)
            Text(
              '${tr('tmFirst', {'w': first})} (${last >= first ? '+' : ''}${((last - first) / first * 100).round()} %)',
              style: TextStyle(color: Tx.muted),
            ),
        ],
      ]),
    );
  }
}

/// Volver a contarlo tres veces en 2:00, 1:30 y 1:00, grabando cada vuelta.
class RetellCard extends StatefulWidget {
  const RetellCard({super.key, this.onDone});
  final VoidCallback? onDone;
  @override
  State<RetellCard> createState() => _RetellCardState();
}

class _RetellCardState extends State<RetellCard> {
  static const rounds = [120, 90, 60];
  final clips = <String>[];
  int r = 0, left = 0;
  bool running = false, recording = false, noMic = false;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    if (recording) voice.cancel();
    voice.stopPlaying();
    super.dispose();
  }

  Future<void> _start() async {
    await speech.stop();
    recording = false;
    if (!noMic && await voice.allowed()) {
      try {
        await voice.start();
        recording = true;
      } catch (_) {
        noMic = true;
      }
    } else {
      noMic = true;
    }
    left = rounds[r];
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => left--);
      if (left <= 0) _finish();
    });
    if (mounted) setState(() => running = true);
  }

  Future<void> _finish() async {
    _tick?.cancel();
    if (!running) return;
    running = false;
    if (recording) {
      final p = await voice.stop();
      recording = false;
      if (p != null) clips.add(p);
    }
    if (mounted) setState(() => r++);
    if (r >= rounds.length) {
      progress.markToday('produce');
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) => CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('rtH'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Tx.ink)),
          const SizedBox(height: 4),
          Text(tr('rtLede'), style: TextStyle(color: Tx.muted, height: 1.4)),
          if (noMic) Padding(padding: const EdgeInsets.only(top: 6), child: Text(tr('rtNoMic'), style: TextStyle(fontSize: 12.5, color: Tx.muted))),
          const SizedBox(height: 10),
          for (var k = 0; k < clips.length; k++)
            OutlinedButton(onPressed: () => voice.play(clips[k]), child: Text('▶ ${tr('rtRec', {'n': k + 1})}')),
          if (running) ...[
            Text(clock(left), style: TextStyle(fontFamily: Tx.mono, fontSize: 40, fontWeight: FontWeight.w500, color: Tx.ink)),
            Text(tr('roundN', {'n': r + 1}), style: TextStyle(color: Tx.muted)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _finish, child: Text('■ ${tr('rtStop')}')),
          ] else if (r < rounds.length)
            FilledButton(onPressed: _start, child: Text(tr('rtGo', {'n': r + 1, 't': clock(rounds[r])})))
          else ...[
            Text(tr(clips.isEmpty ? 'rtDoneNoMic' : 'rtDone'), style: TextStyle(color: Tx.ok, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() {
                clips.clear();
                r = 0;
              }),
              child: Text(tr('restart')),
            ),
          ],
        ]),
      );
}
