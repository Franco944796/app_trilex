import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/content.dart';
import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';
import 'exercise_view.dart';

/// Prueba de nivel de la app: solo los bloques B1 y B2 (la app es para nivel intermedio), una
/// pregunta por pantalla, sin corrección visible; se detiene en el primer bloque no superado.
/// Si no se supera B1, se recomienda la web, que tiene A1–A2.
class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key});
  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  Json? test;
  bool started = false, finished = false;
  int bi = 0, ii = 0;
  double ok = 0;
  final res = <String, ({double ok, int n})>{};

  @override
  void initState() {
    super.initState();
    content.obj('placement-test.json').then((v) {
      if (mounted) setState(() => test = v);
    });
  }

  List<Json> get blocks => jsonList(test!['blocks']).where((b) => Course.appLevels.contains(b['level'])).toList();
  double get passRatio => ((test!['algorithm'] as Map?)?['pass_ratio'] as num?)?.toDouble() ?? 0.75;

  void _answer(double v) {
    ok += v;
    ii++;
    final b = blocks[bi];
    final items = jsonList(b['items']);
    if (ii >= items.length) {
      res[str(b['level'])] = (ok: ok, n: items.length);
      if (ok / items.length < passRatio || bi == blocks.length - 1) {
        _end();
      } else {
        bi++;
        ii = 0;
        ok = 0;
      }
    }
    setState(() {});
  }

  int _pc(({double ok, int n}) r) => (r.ok / r.n * 100).round();

  void _end() {
    final done = blocks.where((b) => res.containsKey(b['level'])).toList();
    final passed = done.where((b) => res[b['level']]!.ok / res[b['level']]!.n >= passRatio).toList();
    final lv = passed.isEmpty ? 'A2' : str(passed.last['level']);
    progress.course['placement'] = {
      'level': lv,
      'passed': [for (final b in passed) b['level']],
      'scores': {for (final b in done) b['level']: _pc(res[b['level']]!)},
      'at': DateTime.now().millisecondsSinceEpoch,
    };
    progress.save();
    finished = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('placementT'))),
      body: test == null ? const Center(child: CircularProgressIndicator()) : (finished ? _result() : (started ? _question() : _intro())),
    );
  }

  Widget _intro() => PageList(children: [
        PageHeader(kicker: tr('toolsH'), title: tr('placementT'), lede: tr('plInstr')),
        Row(children: [
          FilledButton(onPressed: () => setState(() => started = true), child: Text(tr('start'))),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('cancel'))),
        ]),
      ]);

  Widget _question() {
    final b = blocks[bi];
    final items = jsonList(b['items']);
    return PageList(children: [
      Kicker('${tr('placementT')} · ${tr('plQuestion', {'l': b['level'], 'i': ii + 1, 'n': items.length})}', color: Tx.blue),
      const SizedBox(height: 10),
      ProgressLine(ii / items.length),
      const SizedBox(height: 18),
      CardBox(
        child: ExerciseView(
          key: ValueKey('$bi-$ii'),
          ex: course.localizeEx(items[ii]),
          quiet: true,
          dontKnow: true,
          onDone: _answer,
        ),
      ),
    ]);
  }

  Widget _result() {
    final done = blocks.where((b) => res.containsKey(b['level'])).toList();
    final passed = done.where((b) => res[b['level']]!.ok / res[b['level']]!.n >= passRatio).toList();
    final lv = passed.isEmpty ? 'A1–A2' : str(passed.last['level']);
    Json? failB;
    for (final b in done) {
      if (!passed.contains(b)) {
        failB = b;
        break;
      }
    }
    final need = (passRatio * 100).round();
    final msg = passed.isEmpty
        ? tr('plBelowB1', {'p': need})
        : failB == null
            ? tr('plTop', {'l': lv})
            : tr('plUpTo', {
                'l': lv,
                'f': failB['level'],
                'p': _pc(res[failB['level']]!),
                'near': _pc(res[failB['level']]!) >= 50 ? tr('plNear') : '',
              });
    return PageList(children: [
      PageHeader(
        kicker: tr('placementT'),
        title: lv,
        lede: passed.isEmpty ? msg : '${tr('plYourLevel', {'l': lv})} $msg',
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final b in done)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 40, child: Text(str(b['level']), style: const TextStyle(fontFamily: Tx.mono, fontWeight: FontWeight.w500))),
                Expanded(child: Text('${fmtScore(res[b['level']]!.ok)}/${res[b['level']]!.n} (${_pc(res[b['level']]!)} %)')),
                Text(tr(passed.contains(b) ? 'plPassed' : 'plFailed')),
              ]),
            ),
          const SizedBox(height: 8),
          Text(
            tr('plRule', {'p': need}),
            style: TextStyle(fontSize: 13, color: Tx.muted),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 8, children: [
        if (passed.isEmpty)
          FilledButton(
            onPressed: () => launchUrl(Uri.parse(Content.siteUrl), mode: LaunchMode.externalApplication),
            child: Text(tr('openWeb')),
          ),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('back'))),
        OutlinedButton(
          onPressed: () => setState(() {
            res.clear();
            bi = 0;
            ii = 0;
            ok = 0;
            finished = false;
            started = true;
          }),
          child: Text(tr('repeatTest')),
        ),
      ]),
    ]);
  }
}
