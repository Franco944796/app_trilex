import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'course.dart';

/// Repaso espaciado (Leitner): tarjetas de las palabras que tocan hoy.
/// Acierto → sube una caja; error → vuelve a la caja 1. Intervalos: 1, 3, 7, 14, 30 y 60 días.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  static const intervals = [1, 3, 7, 14, 30, 60];
  final words = <String, Json>{};
  List<String> queue = [];
  int i = 0, ok = 0;
  bool shown = false, loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final lv in course.ready) {
      final v = await content.obj('vocab/${str(lv['cefr']).toLowerCase()}.json');
      for (final w in jsonList(v['items'])) {
        words[str(w['id'])] = w;
      }
    }
    if (!mounted) return;
    setState(() {
      queue = shuffled(course.dueItems.where(words.containsKey).toList());
      loaded = true;
    });
  }

  void _grade(bool good) {
    final it = progress.srs[queue[i]] as Map;
    var box = (it['box'] as num?)?.toInt() ?? 1;
    if (good) {
      ok++;
      box = box < 6 ? box + 1 : 6;
    } else {
      box = 1;
      it['lapses'] = ((it['lapses'] as num?) ?? 0) + 1;
    }
    it['box'] = box;
    it['due'] = dayNumber() + intervals[box - 1];
    progress.save();
    setState(() {
      i++;
      shown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (i >= queue.length) {
      body = PageList(children: [
        PageHeader(kicker: tr('reviewT'), title: tr('reviewDone'), lede: tr('gotNofM', {'o': ok, 'n': queue.length})),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('mapBack'))),
        ),
      ]);
    } else {
      final w = words[queue[i]]!;
      body = PageList(children: [
        Kicker('${tr('reviewT')} · ${i + 1}/${queue.length}', color: Tx.blue),
        const SizedBox(height: 10),
        ProgressLine(i / queue.length),
        const SizedBox(height: 18),
        CardBox(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(str(w['lemma']), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Tx.ink)),
            const SizedBox(height: 6),
            Row(children: [
              SayButton(str(w['lemma'])),
              const SizedBox(width: 10),
              Text(str(w['ipa']), style: TextStyle(fontFamily: Tx.mono, color: Tx.muted)),
            ]),
            if (shown) ...[
              const Divider(height: 28),
              Text(course.meaning(w), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Tx.ink)),
              Text(str(w['example']), style: TextStyle(color: Tx.muted, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 18),
            if (!shown)
              FilledButton(onPressed: () => setState(() => shown = true), child: Text(tr('showAnswer')))
            else
              Wrap(spacing: 8, children: [
                OutlinedButton(onPressed: () => _grade(false), child: Text(tr('didntKnow'))),
                FilledButton(onPressed: () => _grade(true), child: Text(tr('knewIt'))),
              ]),
          ]),
        ),
      ]);
    }
    return Scaffold(appBar: AppBar(title: Text(tr('reviewT'))), body: body);
  }
}
