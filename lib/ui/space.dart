import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Colores del estilo «espacial», los mismos que la web (ingles/shared-topic.css).
class Space {
  static const sky = Color(0xFF8FA9F0);
  static const violet = Color(0xFFB48CFF);

  /// Color del brillo: azul en claro, celeste en oscuro.
  static Color get glow => Tx.isDark ? sky : const Color(0xFF2E55C7);
  static Color get glowHot => Tx.isDark ? Colors.white : sky;

  /// «Trilex» en celeste: en claro, un celeste más oscuro para que se lea sobre el fondo blanco.
  static Color get brand => Tx.isDark ? sky : const Color(0xFF4A6FD8);
}

/// Fondo «aurora»: halos celeste y violeta en las esquinas sobre el fondo de siempre.
class Aurora extends StatelessWidget {
  const Aurora({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _AuroraPainter(Tx.bg, Tx.isDark), child: child);
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.bg, this.dark);
  final Color bg;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = bg);
    // centro relativo, radio relativo al lado mayor, opacidad (en claro / en oscuro)
    final halos = [
      (const Offset(0.10, 0.06), 0.40, Space.sky, dark ? 0.16 : 0.38),
      (const Offset(0.90, 0.18), 0.38, Space.violet, dark ? 0.12 : 0.26),
      (const Offset(0.50, 1.15), 0.45, Space.sky, dark ? 0.10 : 0.25),
    ];
    final side = math.max(size.width, size.height);
    for (final (at, r, color, alpha) in halos) {
      final center = Offset(at.dx * size.width, at.dy * size.height);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: r * side)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.bg != bg || old.dark != dark;
}

/// Pone la aurora detrás de cada pantalla. Va en las transiciones de página (y no detrás del
/// Navigator) para que cada pantalla siga siendo opaca y no se transparente la anterior al pasar.
class AuroraTransitions extends PageTransitionsBuilder {
  const AuroraTransitions(this.inner);
  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      inner.buildTransitions(route, context, animation, secondaryAnimation, Aurora(child: child));
}

/// Borde de luz que gira alrededor de [child], como en la web: marca lo que toca hacer ahora.
/// Queda quieto si el sistema pide menos animaciones.
class GlowBorder extends StatefulWidget {
  const GlowBorder({super.key, required this.child, this.radius = 12, this.on = true});
  final Widget child;
  final double radius;
  final bool on;
  @override
  State<GlowBorder> createState() => _GlowBorderState();
}

class _GlowBorderState extends State<GlowBorder> with SingleTickerProviderStateMixin {
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(GlowBorder old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.on && !still) {
      if (!spin.isAnimating) spin.repeat();
    } else {
      spin.stop();
    }
  }

  @override
  void dispose() {
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.on) return widget.child;
    final r = BorderRadius.circular(widget.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [BoxShadow(color: Space.glow.withValues(alpha: 0.28), blurRadius: 22)],
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          foregroundPainter: _RingPainter(spin, widget.radius, Space.glow, Space.glowHot),
          child: widget.child,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.spin, this.radius, this.glow, this.hot) : super(repaint: spin);
  final Animation<double> spin;
  final double radius;
  final Color glow, hot;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.75);
    final faint = glow.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = SweepGradient(
          colors: [faint, glow, hot, Space.violet, faint, faint],
          stops: const [0, 50 / 360, 80 / 360, 110 / 360, 170 / 360, 1],
          transform: GradientRotation(spin.value * 2 * math.pi),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.glow != glow || old.hot != hot || old.radius != radius;
}

/// Marca de la app: ∴ («por lo tanto») y el nombre en celeste, como en la portada de la web.
class Brand extends StatelessWidget {
  const Brand({super.key, this.size = 30});
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = Space.brand;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      CustomPaint(size: Size.square(size * 0.5), painter: _DotsPainter(c)),
      SizedBox(width: size * 0.22),
      Text(
        'Trilex',
        style: TextStyle(
          fontFamily: Tx.sans,
          fontSize: size,
          fontWeight: FontWeight.w600,
          height: 1.05,
          color: c,
          shadows: [Shadow(color: Space.sky.withValues(alpha: 0.45), blurRadius: 14)],
        ),
      ),
    ]);
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final r = size.width * 0.125;
    // mismas proporciones que imgs/favicon.svg de la web (64 × 64)
    for (final (x, y) in const [(32.0, 15.0), (15.0, 45.0), (49.0, 45.0)]) {
      canvas.drawCircle(Offset(x / 64 * size.width, y / 64 * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}
