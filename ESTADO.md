# Estado — trilex (app Flutter)

## Objetivo
App de autoaprendizaje de inglés para nivel intermedio (B1–B2). Los principiantes (A1–A2) usan la web
(`../web-idiomas`). Trabajo en curso: rediseñar la app para B1–B2 y sumar contenido intermedio.

## Decisiones tomadas
- Reglas de trabajo: `../web-idiomas/reglas-de-trabajo.md`.
- Se sacan A1–A2 de la app. La prueba de nivel solo distingue B1/B2; si da menos, recomienda la web.
- Curso = consulta, por tema; exámenes como autoevaluación. Niveles (2026-10-27): B1 abierto salvo que la
  prueba de nivel dé menos de B1 (entonces B1 y B2 cerrados y se recomienda la web); B2 se abre al sacar B2
  en la prueba o al aprobar el examen B1; sin prueba hecha, B2 cerrado.
- Pestaña «Hoy» como inicio: lectura + repaso de palabras + una actividad para producir, según la meta.
- Lector con las actividades de la web: escuchar y repetir, completar huecos, resumen guiado,
  lectura cronometrada, volver a contarlo, repaso espaciado escrito de las palabras guardadas.
- Corrección solo con modelo + lista de control (sin IA, nada sale del teléfono).
- Contenido nuevo (aparece también en la web):
  - 24 lecturas graduadas nuevas: 12 B1 + 12 B2 (glosario, preguntas, tarea, resumen modelo).
  - 4 libros de dominio público: A Christmas Carol, The Call of the Wild, The Time Machine,
    The Picture of Dorian Gray (glosario y preguntas por capítulo).
  - Se escribe como JSON directo en `../web-idiomas/content/en` + un script propio que valida,
    actualiza `reading/index.json` y `manifest.json` y copia a `assets/content`. El generador
    original (tools/build.py) no está en esta computadora: si se regenera, conservar esos archivos.
- Textos de interfaz en los 8 idiomas de la app.
- Grabación de voz en «escuchar y repetir» y «volver a contarlo» (librerías nuevas + permiso de
  micrófono; la grabación queda en el teléfono).
- Navegación de 5 pestañas: Hoy · Leer · Palabras · Gramática · Ajustes.
- Lector: selección propia (mantener presionado y arrastrar) sobre una lista perezosa; un único texto
  seleccionable con todo el capítulo se descartó por lento.

## Plan
1. Etapa 1 (código de la app): navegación nueva, «Hoy», quitar A1–A2, curso como consulta,
   actividades del lector, repaso escrito, progreso B1–B2, corregir los 3 errores del lector
   (diccionario por primera palabra de frases, glosario viejo en «Mis palabras», mejor puntaje al
   reiniciar). Verificar con `flutter analyze`, `flutter test` y `flutter run -d linux`.
2. Etapa 2 (contenido): script de validación/manifest, 24 lecturas, 4 libros.

## Hecho
- 2026-10-26 Etapa 1 (código), verificada con `flutter analyze`, `flutter test` (14 pruebas),
  `flutter build linux --debug` y capturas de pantalla generadas con una prueba de widgets:
  - Navegación: Hoy · Leer · Palabras · Gramática · Ajustes (`lib/main.dart`).
  - Hoy (`lib/today/`): plan leer → repasar → producir (dictogloss o volver a contarlo, día por
    medio), gramática de la última lectura, progreso (palabras leídas, libros, ppm, palabras
    aprendidas) y autoevaluación «puedo…» B1/B2.
  - Solo B1–B2 (`Course.appLevels`); curso como consulta, sin bloqueos (`grammar_screen.dart`);
    prueba de nivel B1/B2 que recomienda la web si no se llega a B1.
  - Lector: escuchar y repetir con grabación, completar huecos, resumen guiado, lectura
    cronometrada, volver a contarlo con grabación (`lib/reading/activities.dart`), traducir frases
    de hasta 4 palabras, y los 3 errores corregidos.
  - Palabras (`lib/words/`): repaso escrito que junta palabras guardadas y vocabulario de lecciones.
  - Dictogloss por unidad (`lib/course/dicto_screen.dart`) con los textos de `extras.json`.
  - Grabación: librerías `record` y `audioplayers` (`lib/core/voice.dart`, `lib/ui/voice_clip.dart`).
  - `tool/contenido.py`: valida el contenido, rehace manifest.json y copia a assets.

- 2026-10-26 Etapa 2 (contenido), verificada en la web (Firefox) y en la app (analyze, test, build, captura):
  - 24 lecturas nuevas (12 B1 + 12 B2) con glosario, preguntas, tarea y resumen modelo.
  - 4 libros: A Christmas Carol (5 cap.), The Call of the Wild (7), The Time Machine (16, el epílogo va
    con el 16), The Picture of Dorian Gray (20, títulos de capítulo descriptivos). 48 capítulos, 288
    preguntas; cada dato de las preguntas se comprobó contra el texto.
  - Diccionario del lector: 558 palabras nuevas en 7 idiomas (las originales no se tocan;
    `tool/contenido/diccionario_propio.json` lista las agregadas).
  - Temas nuevos (Aprender idiomas, Deporte, Consumo, Ciencia, Arte) en la web y en la app.
  - Lecturas recomendadas por unidad actualizadas con las nuevas.

- 2026-10-26 Lector: selección de varias palabras o párrafos y optimización, verificada con `flutter analyze`,
  `flutter test` (18 pruebas, 4 nuevas en `test/reader_test.dart`), `flutter build linux --debug` y capturas
  en tema claro y oscuro:
  - Mantener presionada una palabra y arrastrar, también entre párrafos y con desplazamiento automático en los
    bordes; al soltar, barra con 4 colores, Nota, Traducir (≤ 4 palabras de un párrafo), Copiar y ✕. Un toque
    con la selección abierta solo la quita. Se quitó el modo «Elegir un fragmento…».
  - Lista perezosa (`CustomScrollView`): solo se arman los párrafos cercanos a la pantalla; las secciones de
    abajo también, y se conservan una vez armadas. Los párrafos que no cambian no se vuelven a armar.
  - Cronómetro en su propio widget (antes redibujaba todo el lector cada segundo).
  - La posición del libro se guarda como número de párrafo (las guardadas como fracción se convierten).
  - JSON grandes decodificados en otro hilo (`compute`) y diccionario precargado al iniciar.
  - Medido en pruebas (modo depuración, capítulo de ~10 000 palabras): carga 1030 → 550 ms, primer cuadro
    700 → 270 ms (46 ms al abrir otro capítulo), desplazamiento 23 → 11 ms por cuadro, redibujado 300 → 50 ms.

- 2026-10-27 Lector: con mouse (computadora) se selecciona haciendo clic y arrastrando, como en la web; con el
  dedo sigue siendo mantener presionado y arrastrar. Prueba nueva en `test/reader_test.dart` (19 en total).

- 2026-10-27 Al abrir la app por primera vez se elige el idioma de la interfaz (`lib/welcome_screen.dart`);
  se aplica al tocarlo y después se cambia en Ajustes. Si ya había un idioma guardado, no se pregunta.
  3 pruebas nuevas en `test/welcome_test.dart` (22 en total) y captura revisada.

- 2026-10-27 Gramática: candado por nivel (`Course.unlocked`), aviso con cómo desbloquear, y la lección
  siguiente y la sugerencia de «Hoy» respetan el bloqueo. 6 pruebas nuevas en `test/levels_test.dart` (28 en total).

- 2026-10-27 Lector: la barra de colores de la selección flota junto a donde se suelta (arriba si hay lugar,
  si no abajo) y acompaña al texto al desplazar; ya no muestra la frase entre comillas.

- 2026-10-28 Android: plataforma agregada (`android/`, paquete `com.franco.trilex`, nombre «Trilex»).
  Permisos de internet, micrófono, notificaciones y arranque; receptores de `flutter_local_notifications`;
  desugaring. `flutter build apk --release` genera un APK universal firmado con la clave de depuración
  (sirve para probar, no para Play Store). SDK en `~/Android/Sdk`.

- 2026-10-29 Notas del lector: botón «Listo» (`noteDone` en `app.json`) debajo de cada nota mientras se escribe
  (`_NoteField` en `reader_screen.dart`). Ícono: ∴ con conexiones y paquetes de luz; en Android 8+ es adaptable
  (fondo, frente y monocromo, `mipmap-anydpi-v26`) y llena el círculo o la forma del launcher. Lo genera
  `tool/icono/generar.py`. El favicon de la web sigue siendo el ∴ solo (mismas proporciones).

- 2026-10-28 Contenido sincronizado con la web: opciones de opción múltiple reescritas (exámenes, prueba de nivel y
  lecciones) para que la correcta no se note por el largo; `flutter analyze` y `flutter test` (28) sin errores.

- 2026-10-29 Estilo «espacial» como la web (`lib/ui/space.dart`), revisado en capturas (claro y oscuro) y con
  `flutter analyze`, `flutter test` (28) y `flutter build linux --debug`:
  - Fondo «aurora» (halos celeste y violeta) en todas las pantallas; se pinta en la transición de cada página
    para que la anterior no se transparente.
  - Borde de luz que gira (`GlowBorder`, quieto si el sistema pide menos animaciones): próximo paso de «Hoy»,
    lectura recomendada (primera sin leer del nivel), libro que se está leyendo, examen listo en Gramática
    (lecciones del nivel terminadas y examen sin aprobar) e idioma elegido en la bienvenida.
  - Marca ∴ Trilex en celeste en la bienvenida y en «Hoy».
  - Ícono de la app (Android y ventana de Linux; iOS al crear la carpeta): `tool/icono/icono.svg` →
    `python3 tool/icono/generar.py` (también lo corre `tool/configurar_plataformas.py`). Título de la ventana «Trilex».

## En curso
- Nada.

## Pendiente
- Probar en un teléfono real: grabación, permisos de micrófono, el plan «Hoy», y la selección y velocidad del
  lector con `flutter run --profile`.
- PDF de los 4 libros nuevos: no se generaron (hace falta Chromium/Playwright); la app y la web no muestran
  el botón de PDF para esos libros.
- Publicar la web (incluye `content/en/extras.json`, los libros y lecturas nuevos y el `manifest.json`) para
  que la app instalada descargue el contenido nuevo.

## Archivos clave
- `lib/main.dart` (navegación), `lib/course/*`, `lib/reading/*`, `lib/core/*`, `assets/i18n`.
- Contenido: `assets/content/en` (copia del de la web; se sincroniza con `manifest.json`).

## Problemas conocidos
- (ver al terminar la etapa 1)
- `flutter_timezone` 3.0.1 mezcla JVM 1.8 (Kotlin) y 11 (Java); se toleró con
  `kotlin.jvm.target.validation.mode=warning` en `android/gradle.properties`. Flutter avisa que una versión
  futura dejará de compilar `flutter_timezone` y `flutter_tts` si no se actualizan a «Built-in Kotlin».
