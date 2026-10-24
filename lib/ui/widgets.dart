import 'package:flutter/material.dart';

import '../core/services.dart';
import '../core/util.dart';
import 'theme.dart';

/// Piezas del diseño editorial (las mismas de la web).

/// Rótulo en mayúsculas monoespaciadas.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: Tx.kicker.copyWith(color: color ?? Tx.muted));
}

/// Cabecera de pantalla: rótulo, título grande, texto breve y una raya gruesa debajo.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.kicker, required this.title, this.lede = '', this.sub = ''});
  final String kicker, title, lede, sub;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(bottom: 18),
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Tx.ink, width: 2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Kicker(kicker, color: Tx.blue),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 30, height: 1.12, fontWeight: FontWeight.w600, color: Tx.ink)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontWeight: FontWeight.w500, color: Tx.muted)),
          ],
          if (lede.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(lede, style: TextStyle(fontSize: 16, color: Tx.muted, height: 1.45)),
          ],
        ]),
      );
}

/// Panel de color suave con bordes redondeados.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.color, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: color ?? Tx.grey, borderRadius: BorderRadius.circular(14)),
        child: child,
      );
}

/// Tarjeta (blanca en el tema claro) con borde fino.
class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.borderColor});
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Tx.surface,
          border: Border.all(color: borderColor ?? Tx.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );
}

/// Barra de avance fina.
class ProgressLine extends StatelessWidget {
  const ProgressLine(this.value, {super.key, this.color});
  final double value;
  final Color? color;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          minHeight: 6,
          backgroundColor: Tx.track,
          color: color ?? Tx.ink,
        ),
      );
}

/// Bloque con un rótulo y un texto (como «PUNTO DE PARTIDA» en el diseño).
class NoteBlock extends StatelessWidget {
  const NoteBlock({super.key, required this.label, required this.text});
  final String label, text;
  @override
  Widget build(BuildContext context) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Kicker(label),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(height: 1.45)),
        ]),
      );
}

/// Título de una sección: «01 · TEXTO Y VOCABULARIO».
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.title = '', this.lede = ''});
  final String text, title, lede;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Kicker(text, color: Tx.blue),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Tx.ink)),
          ],
          if (lede.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(lede, style: TextStyle(color: Tx.muted, height: 1.4)),
          ],
        ]),
      );
}

/// Panel de puntaje de la práctica: «PUNTAJE 7 / 29 · Respondidas: 9 de 29 · Reiniciar».
class ScorePanel extends StatelessWidget {
  const ScorePanel({super.key, required this.score, required this.total, required this.answered, this.onRestart});
  final double score;
  final int total, answered;
  final VoidCallback? onRestart;
  @override
  Widget build(BuildContext context) => Panel(
        color: Tx.blueSoft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Kicker(tr('scoreH'), color: Tx.blue),
            Text('${fmtScore(score)} / $total',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Tx.ink)),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(tr('answeredNofM', {'a': answered, 'n': total}),
                  style: TextStyle(fontSize: 12.5, color: Tx.muted)),
              const SizedBox(height: 6),
              ProgressLine(total == 0 ? 0 : answered / total),
            ]),
          ),
          if (onRestart != null) ...[
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onRestart,
              style: OutlinedButton.styleFrom(backgroundColor: Tx.surface, minimumSize: const Size(0, 36)),
              child: Text(tr('restart')),
            ),
          ],
        ]),
      );
}

/// Botón pequeño para escuchar un texto en inglés.
class SayButton extends StatelessWidget {
  const SayButton(this.text, {super.key, this.slow = false, this.label});
  final String text;
  final bool slow;
  final String? label;
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: () => speech.say(text, rate: slow ? 0.6 : 0.9),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(38, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label ?? '🔊', style: const TextStyle(fontSize: 13.5)),
      );
}

/// Número de ejercicio en un círculo negro.
class NumberDot extends StatelessWidget {
  const NumberDot(this.n, {super.key});
  final int n;
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Tx.ink, shape: BoxShape.circle),
        child: Text('$n', style: TextStyle(color: Tx.onInk, fontSize: 11.5, fontWeight: FontWeight.w600)),
      );
}

/// Pantalla con margen y desplazamiento, para el contenido de cada vista. Construye todo el
/// contenido de una vez (no como ListView), así los ejercicios no pierden las respuestas al
/// salir de la pantalla.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children, this.controller});
  final List<Widget> children;
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

/// Burbuja de color de un subrayado: fondo suave y barra a la izquierda.
class MarkBubble extends StatelessWidget {
  const MarkBubble({super.key, required this.color, required this.child, this.padding = const EdgeInsets.all(12)});
  final String color;
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final c = Tx.marks[color] ?? Tx.marks['yellow']!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(color: c[0], border: Border(left: BorderSide(color: c[1], width: 3))),
          child: child,
        ),
      ),
    );
  }
}

/// Muestra un error de carga con un botón para reintentar.
class LoadError extends StatelessWidget {
  const LoadError(this.error, {super.key});
  final Object error;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(tr('loadError', {'e': '$error'})),
      );
}
