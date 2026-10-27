import 'package:flutter/material.dart';

import 'core/i18n.dart';
import 'core/services.dart';
import 'course/course.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// Primera pantalla de la app: elegir el idioma de la interfaz. Después se cambia en Ajustes.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool busy = false;

  // se aplica al tocar, así la pantalla misma ya se ve en el idioma elegido
  Future<void> _pick(String l) async {
    if (busy) return;
    setState(() => busy = true);
    await i18n.setLang(l);
    await course.loadPacks();
    i18n.refresh();
    if (mounted) setState(() => busy = false);
  }

  Future<void> _start() async {
    await i18n.setLang(i18n.lang);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: PageList(children: [
                PageHeader(kicker: 'Trilex', title: tr('chooseLang'), lede: tr('chooseLangSub')),
                for (final e in I18n.names.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _Option(label: e.value, selected: i18n.lang == e.key, onTap: () => _pick(e.key)),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: busy ? null : _start, child: Text(tr('start'))),
              ),
            ),
          ]),
        ),
      );
}

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: selected ? Tx.blueSoft : Tx.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? Tx.blue : Tx.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Tx.ink))),
              if (selected) Icon(Icons.check_circle, color: Tx.blue, size: 22),
            ]),
          ),
        ),
      );
}
