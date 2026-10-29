import 'package:flutter/material.dart';

import 'space.dart';

class TxPalette {
  const TxPalette({
    required this.ink,
    required this.text,
    required this.muted,
    required this.faint,
    required this.line,
    required this.line2,
    required this.bg,
    required this.grey,
    required this.surface,
    required this.blue,
    required this.blueSoft,
    required this.rust,
    required this.rustSoft,
    required this.ok,
    required this.okSoft,
    required this.bad,
    required this.badSoft,
    required this.half,
    required this.halfSoft,
    required this.onInk,
    required this.onInkMuted,
    required this.onAccent,
    required this.feature,
    required this.featureLine,
    required this.onFeature,
    required this.onFeatureStrong,
    required this.onFeatureMuted,
    required this.featureAccent,
    required this.lightBtn,
    required this.lightBtnText,
    required this.track,
    required this.doneLine,
    required this.readerText,
    required this.noteBg,
    required this.selection,
    required this.marks,
  });

  final Color ink, text, muted, faint, line, line2, bg, grey, surface;
  final Color blue, blueSoft, rust, rustSoft, ok, okSoft, bad, badSoft, half, halfSoft;

  /// Texto sobre fondo [ink] (botón principal, número de ejercicio, pestaña activa).
  final Color onInk, onInkMuted;

  final Color onAccent;

  /// Tarjeta destacada oscura («Siguiente lección», barra de selección del lector).
  final Color feature, featureLine, onFeature, onFeatureStrong, onFeatureMuted, featureAccent;

  final Color lightBtn, lightBtnText;

  final Color track, doneLine, readerText, noteBg, selection;

  /// Colores de los subrayados del lector: [fondo, borde].
  final Map<String, List<Color>> marks;
}

const _light = TxPalette(
  ink: Color(0xFF1D2025),
  text: Color(0xFF2F333B),
  muted: Color(0xFF646B78),
  faint: Color(0xFF8B919C),
  line: Color(0xFFE1E4EA),
  line2: Color(0xFFC9CED8),
  bg: Color(0xFFFFFFFF),
  grey: Color(0xFFF4F5F8),
  surface: Color(0xFFFFFFFF),
  blue: Color(0xFF2E55C7),
  blueSoft: Color(0xFFE9EFFB),
  rust: Color(0xFFB5461F),
  rustSoft: Color(0xFFFBECE6),
  ok: Color(0xFF1D7A4C),
  okSoft: Color(0xFFE5F3EB),
  bad: Color(0xFFB3261E),
  badSoft: Color(0xFFFCEBEA),
  half: Color(0xFF9A6700),
  halfSoft: Color(0xFFFDF3DC),
  onInk: Color(0xFFFFFFFF),
  onInkMuted: Color(0xFFC3C8D1),
  onAccent: Color(0xFFFFFFFF),
  feature: Color(0xFF1D2025),
  featureLine: Color(0xFF1D2025),
  onFeature: Color(0xFFD9DCE2),
  onFeatureStrong: Color(0xFFFFFFFF),
  onFeatureMuted: Color(0xFFC3C8D1),
  featureAccent: Color(0xFF9DB4F2),
  lightBtn: Color(0xFFFFFFFF),
  lightBtnText: Color(0xFF1D2025),
  track: Color(0x1A1D2025),
  doneLine: Color(0xFFB9D8C6),
  readerText: Color(0xFF22252B),
  noteBg: Color(0xBFFFFFFF),
  selection: Color(0x382E55C7),
  marks: {
    'yellow': [Color(0xFFFFF1B0), Color(0xFFE0B400)],
    'green': [Color(0xFFD6F0DC), Color(0xFF2F9A55)],
    'blue': [Color(0xFFDBE6FB), Color(0xFF2E55C7)],
    'pink': [Color(0xFFFBDBE6), Color(0xFFC23D6C)],
  },
);

const _dark = TxPalette(
  ink: Color(0xFFE6E8EC),
  text: Color(0xFFCFD3DA),
  muted: Color(0xFF9AA1AD),
  faint: Color(0xFF737A86),
  line: Color(0xFF2C3038),
  line2: Color(0xFF3B404A),
  bg: Color(0xFF16181C),
  grey: Color(0xFF1E2127),
  surface: Color(0xFF1E2127),
  blue: Color(0xFF8FA9F0),
  blueSoft: Color(0xFF1C2640),
  rust: Color(0xFFE58A63),
  rustSoft: Color(0xFF3A2219),
  ok: Color(0xFF5CC58F),
  okSoft: Color(0xFF16301F),
  bad: Color(0xFFF07A72),
  badSoft: Color(0xFF3A1C1B),
  half: Color(0xFFE0B44A),
  halfSoft: Color(0xFF352A12),
  onInk: Color(0xFF16181C),
  onInkMuted: Color(0xFF4B515C),
  onAccent: Color(0xFF16181C),
  feature: Color(0xFF262A32),
  featureLine: Color(0xFF3B404A),
  onFeature: Color(0xFFCFD3DA),
  onFeatureStrong: Color(0xFFFFFFFF),
  onFeatureMuted: Color(0xFFA3A9B4),
  featureAccent: Color(0xFF8FA9F0),
  lightBtn: Color(0xFFE6E8EC),
  lightBtnText: Color(0xFF16181C),
  track: Color(0x1FE6E8EC),
  doneLine: Color(0xFF2F5A43),
  readerText: Color(0xFFDFE2E7),
  noteBg: Color(0x38000000),
  selection: Color(0x478FA9F0),
  marks: {
    'yellow': [Color(0xFF4A3E10), Color(0xFFE0B400)],
    'green': [Color(0xFF1D3A28), Color(0xFF4CBF75)],
    'blue': [Color(0xFF1F2D4F), Color(0xFF8FA9F0)],
    'pink': [Color(0xFF47202F), Color(0xFFE06A94)],
  },
);

/// Los colores son getters de la paleta activa, que main.dart fija con [use] antes de dibujar.
/// Por eso no pueden ir en expresiones `const`.
class Tx {
  static TxPalette _p = _light;

  static bool get isDark => identical(_p, _dark);

  static void use(Brightness b) => _p = b == Brightness.dark ? _dark : _light;

  static Color get ink => _p.ink;
  static Color get text => _p.text;
  static Color get muted => _p.muted;
  static Color get faint => _p.faint;
  static Color get line => _p.line;
  static Color get line2 => _p.line2;
  static Color get bg => _p.bg;
  static Color get grey => _p.grey;
  static Color get surface => _p.surface;
  static Color get blue => _p.blue;
  static Color get blueSoft => _p.blueSoft;
  static Color get rust => _p.rust;
  static Color get rustSoft => _p.rustSoft;
  static Color get ok => _p.ok;
  static Color get okSoft => _p.okSoft;
  static Color get bad => _p.bad;
  static Color get badSoft => _p.badSoft;
  static Color get half => _p.half;
  static Color get halfSoft => _p.halfSoft;
  static Color get onInk => _p.onInk;
  static Color get onInkMuted => _p.onInkMuted;
  static Color get onAccent => _p.onAccent;
  static Color get feature => _p.feature;
  static Color get featureLine => _p.featureLine;
  static Color get onFeature => _p.onFeature;
  static Color get onFeatureStrong => _p.onFeatureStrong;
  static Color get onFeatureMuted => _p.onFeatureMuted;
  static Color get featureAccent => _p.featureAccent;
  static Color get lightBtn => _p.lightBtn;
  static Color get lightBtnText => _p.lightBtnText;
  static Color get track => _p.track;
  static Color get doneLine => _p.doneLine;
  static Color get readerText => _p.readerText;
  static Color get noteBg => _p.noteBg;
  static Color get selection => _p.selection;
  static Map<String, List<Color>> get marks => _p.marks;

  static const sans = 'Plex Sans', serif = 'Plex Serif', mono = 'Plex Mono';

  static TextStyle get kicker => TextStyle(
        fontFamily: mono,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.4,
        color: muted,
      );

  static ThemeData theme() => _build(_light, Brightness.light);

  static ThemeData darkTheme() => _build(_dark, Brightness.dark);

  static ThemeData _build(TxPalette c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: sans,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.blue,
        brightness: brightness,
        primary: c.ink,
        onPrimary: c.onInk,
        secondary: c.blue,
        surface: c.bg,
        onSurface: c.text,
        surfaceContainerLow: c.surface,
        surfaceContainer: c.surface,
        surfaceContainerHigh: c.surface,
        surfaceContainerHighest: c.grey,
        outline: c.line2,
        outlineVariant: c.line,
        error: c.bad,
      ),
      // las pantallas son transparentes: el fondo «aurora» lo pinta cada página en su transición
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: c.bg,
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        for (final p in TargetPlatform.values)
          p: AuroraTransitions(const PageTransitionsTheme().builders[p] ?? const ZoomPageTransitionsBuilder()),
      }),
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontFamily: sans, fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.onInk,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: shape,
          textStyle: const TextStyle(fontFamily: sans, fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(color: c.line2),
          shape: shape,
          textStyle: const TextStyle(fontFamily: sans, fontWeight: FontWeight.w400, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.blue,
          textStyle: const TextStyle(fontFamily: sans, fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        fillColor: c.surface,
        border: border(c.line2),
        enabledBorder: border(c.line2),
        focusedBorder: border(c.blue, 1.5),
      ),
      dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.bg,
        indicatorColor: c.blueSoft,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: sans, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.feature,
        contentTextStyle: TextStyle(fontFamily: sans, color: c.onFeature),
        actionTextColor: c.featureAccent,
      ),
    );
  }
}
