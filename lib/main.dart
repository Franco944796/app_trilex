import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services.dart';
import 'course/course.dart';
import 'course/map_screen.dart';
import 'reading/reading_home.dart';
import 'settings_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await i18n.load(prefs);
  themePref.load(prefs);
  await progress.load(prefs);
  await content.init();
  await course.load();
  try {
    await speech.init();
  } catch (e) {
    debugPrint('audio no disponible: $e');
  }
  await reminders.init();
  runApp(const TrilexApp());
  // contenido nuevo en la web: se descarga en segundo plano (sin conexión, no pasa nada)
  content.update().then((n) async {
    if (n > 0) {
      await course.load();
      i18n.refresh();
    }
  }).catchError((Object _) {});
}

class TrilexApp extends StatefulWidget {
  const TrilexApp({super.key});
  @override
  State<TrilexApp> createState() => _TrilexAppState();
}

class _TrilexAppState extends State<TrilexApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    i18n.addListener(_relabel);
    themePref.addListener(_retheme);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    i18n.removeListener(_relabel);
    themePref.removeListener(_retheme);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// El sistema pasó a modo claro u oscuro: importa solo con el tema en «Automático».
  @override
  void didChangePlatformBrightness() {
    if (themePref.choice == 'auto') _retheme();
  }

  /// Cambió el tema: se vuelve a dibujar la app (build fija la paleta de Tx) y todas las
  /// pantallas abiertas, que leen sus colores de Tx.
  void _retheme() {
    setState(() {});
    _relabel();
  }

  /// Cambió el idioma (o el tema): se vuelven a dibujar todas las pantallas abiertas (también
  /// las que están debajo en la navegación) para que tomen los textos y colores nuevos.
  void _relabel() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    final system = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = switch (themePref.mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => system,
    };
    // la paleta de Tx se fija antes de dibujar las pantallas (los padres se dibujan primero)
    Tx.use(brightness);
    return MaterialApp(
      title: 'Trilex',
      debugShowCheckedModeBanner: false,
      theme: Tx.theme(),
      darkTheme: Tx.darkTheme(),
      themeMode: themePref.mode,
      // sin transición animada: los colores de Tx cambian de una vez
      themeAnimationDuration: Duration.zero,
      // el tiempo de estudio activo (toques en cualquier pantalla) suma a la meta diaria
      builder: (context, child) => Listener(
        onPointerDown: (_) => progress.tick(),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Shell(),
    );
  }
}

/// Pantalla principal con tres secciones: curso, lectura y ajustes.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const MapScreen(), const ReadingHome(), const SettingsScreen()];
    return Scaffold(
        body: SafeArea(child: pages[tab]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school), label: tr('navCourse')),
            NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: tr('navReading')),
            NavigationDestination(icon: const Icon(Icons.tune_outlined), selectedIcon: const Icon(Icons.tune), label: tr('navMore')),
          ],
        ),
    );
  }
}
