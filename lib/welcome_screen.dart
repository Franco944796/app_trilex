import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/i18n.dart';
import 'core/services.dart';
import 'course/course.dart';
import 'ui/markdown.dart';
import 'ui/space.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// Primera pantalla de la app: elegir el idioma de la interfaz (después se cambia en Ajustes) y aceptar el acuerdo
/// de licencia. Si el idioma ya estaba elegido, se muestra solo el acuerdo.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool busy = false;
  bool license = i18n.chosen;

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
    if (agreement.accepted) {
      widget.onDone();
    } else {
      setState(() => license = true);
    }
  }

  Future<void> _accept() async {
    await agreement.accept();
    widget.onDone();
  }

  Widget _license() => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: PageList(children: [
                const Padding(padding: EdgeInsets.only(bottom: 18), child: Brand(size: 34)),
                PageHeader(kicker: '', title: tr('licenseH'), lede: tr('licenseLede')),
                MiniMarkdown(tr('licenseBody')),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(children: [
                Expanded(child: OutlinedButton(onPressed: SystemNavigator.pop, child: Text(tr('licenseDecline')))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: _accept, child: Text(tr('licenseAccept')))),
              ]),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => license ? _license() : _languages();

  Widget _languages() => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: PageList(children: [
                const Padding(padding: EdgeInsets.only(bottom: 18), child: Brand(size: 34)),
                PageHeader(kicker: '', title: tr('chooseLang'), lede: tr('chooseLangSub')),
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
  Widget build(BuildContext context) => GlowBorder(
        on: selected,
        radius: 10,
        child: Material(
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
        ),
      );
}
