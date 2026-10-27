import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import '../reading/reading_home.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Autoevaluación con las descripciones «puedo…» de B1 y B2 (basadas en el MCER, en primera
/// persona). Sirve para fijarse metas propias y ver el avance, no para calificar.
class CanDoScreen extends StatefulWidget {
  const CanDoScreen({super.key});
  @override
  State<CanDoScreen> createState() => _CanDoScreenState();
}

class _CanDoScreenState extends State<CanDoScreen> {
  static const perLevel = 8;
  String level = myLevel;

  List<int> _marked(String lv) => [for (final x in (progress.canDo[lv] as List?) ?? const []) (x as num).toInt()];

  @override
  Widget build(BuildContext context) {
    final marked = _marked(level);
    return Scaffold(
      appBar: AppBar(title: Text(tr('cdBtn'))),
      body: PageList(children: [
        PageHeader(kicker: tr('cdK'), title: tr('cdTitle'), lede: tr('cdLede')),
        Wrap(spacing: 8, children: [
          for (final lv in const ['B1', 'B2'])
            ChoiceChip(
              label: Text('$lv  ${_marked(lv).length}/$perLevel'),
              selected: level == lv,
              onSelected: (_) => setState(() => level = lv),
            ),
        ]),
        const SizedBox(height: 12),
        ProgressLine(marked.length / perLevel),
        const SizedBox(height: 8),
        for (var i = 1; i <= perLevel; i++)
          CheckboxListTile(
            value: marked.contains(i),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(tr('cd${level}_$i'), style: const TextStyle(height: 1.4)),
            onChanged: (v) {
              final l = _marked(level);
              v == true ? l.add(i) : l.remove(i);
              progress.canDo[level] = l..sort();
              progress.save();
              setState(() {});
            },
          ),
        const SizedBox(height: 8),
        Text(tr('cdSource'), style: TextStyle(fontSize: 12, color: Tx.muted)),
        if (str(level) == 'B1' && marked.length == perLevel)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(tr('cdNext'), style: TextStyle(color: Tx.ok))),
      ]),
    );
  }
}
