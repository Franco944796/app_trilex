import 'package:flutter/material.dart';

import '../core/services.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Preguntas frecuentes (las mismas de la web, en el idioma elegido).
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('helpT'))),
        body: PageList(children: [
          PageHeader(kicker: tr('toolsH'), title: tr('faqTitle')),
          for (final qa in i18n.faq)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Tx.line),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 14),
                expandedAlignment: Alignment.centerLeft,
                title: Text(qa[0], style: TextStyle(fontWeight: FontWeight.w500, color: Tx.ink)),
                children: [Text(qa.length > 1 ? qa[1] : '', style: const TextStyle(height: 1.45))],
              ),
            ),
        ]),
      );
}
