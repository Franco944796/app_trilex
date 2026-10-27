# Trilex (app para Android e iOS)

App en Flutter de Trilex para **autoaprendizaje de inglés en nivel intermedio (B1–B2)**, con el mismo diseño y el
mismo contenido que la web. Los principiantes (A1–A2) usan la web.

- **Hoy:** plan diario de leer → repasar palabras → producir (dictogloss o volver a contarlo), progreso de lectura
  y autoevaluación «puedo…» de B1 y B2.
- **Leer:** lecturas B1–B2 y libros completos, con traducción al tocar una palabra o una frase corta, subrayados con
  notas, escuchar y repetir (con grabación), completar huecos, resumen guiado, lectura cronometrada y volver a
  contarlo.
- **Palabras:** repaso espaciado escrito de las palabras guardadas y del vocabulario de las lecciones.
- **Gramática:** las unidades B1–B2 como consulta, con lectura recomendada, dictogloss y exámenes de
  autoevaluación; prueba de nivel B1/B2. B2 se desbloquea al sacar B2 en la prueba o al aprobar el examen B1;
  si la prueba da menos de B1, los dos niveles quedan cerrados y se recomienda la web.
- **Recordatorio diario:** un aviso para cumplir la meta de estudio.
- **Idiomas:** la interfaz está en los 8 idiomas de la web.
- **Tema claro y oscuro:** automático (sigue al teléfono), claro u oscuro, igual que en la web.
- **Datos:** el progreso se guarda solo en el teléfono, sin cuentas.
- **Contenido:** viene dentro de la app y se actualiza solo desde la web cuando hay conexión.

> Este código no se pudo compilar en el entorno donde se escribió, porque no había acceso para descargar Flutter.
> Se revisó la sintaxis de todos los archivos. Si al compilar aparece algún error, copiá el mensaje completo y
> se corrige.

## 1. Lo que hace falta (una sola vez)

1. **Flutter** 3.24 o posterior. Guía de instalación: https://docs.flutter.dev/get-started/install
   Para comprobar que quedó bien, ejecutá en una terminal:

       flutter doctor

2. **Para Android:** Android Studio, con un emulador o un teléfono Android con la «depuración USB» activada.
3. **Para iOS:** una Mac con Xcode. Para instalarla en un iPhone propio alcanza con una cuenta de Apple gratuita.
   Para publicarla en la App Store hace falta la cuenta de Apple Developer (USD 99 por año).
4. **Python 3**, para el script del paso 2.3.

## 2. Preparar el proyecto (una sola vez)

En una terminal, dentro de esta carpeta (`trilex/`):

    flutter create --org com.trilex --project-name trilex --platforms android,ios .
    python3 tool/configurar_plataformas.py
    flutter pub get

1. `flutter create` agrega las carpetas `android/` e `ios/`, que esta entrega no trae. No toca `lib/` ni `pubspec.yaml`.
2. Si pregunta algo sobre archivos existentes, respondé que no los reemplace.
3. `configurar_plataformas.py` deja listos el nombre «Trilex», el identificador `com.trilex.app`, los permisos de
   internet y notificaciones, y lo que necesitan los recordatorios en Android e iOS.
   Se puede ejecutar más de una vez sin problema. También borra `test/widget_test.dart`, la prueba de la
   app de ejemplo que deja `flutter create` (busca un `MyApp` que no existe).

## 3. Probarla

Con el emulador abierto o el teléfono conectado:

    flutter run

`flutter run` arranca en modo de depuración, que es bastante más lento (sobre todo la primera vez que se abre
cada pantalla). Para ver la velocidad real:

    flutter run --profile

Pruebas automáticas de la lógica (corrección de respuestas, mezcla de opciones, formato):

    flutter test

Qué conviene probar:

- **Curso:** abrir una lección y responder los ejercicios. El puntaje se actualiza en la barra de abajo y, al
  terminar, aparece el resultado y se desbloquea la lección siguiente.
- **Modo prueba:** al final del mapa hay un interruptor que abre todas las lecciones y los exámenes.
- **Lectura:** abrir un texto y tocar una palabra para ver su traducción y su definición. Desde esa misma
  ventana se puede subrayar la palabra o la oración con un color, o escribir una nota.
  Para subrayar varias palabras o párrafos: mantener presionada una palabra y arrastrar (con mouse, hacer clic
  y arrastrar; cerca del borde, el texto se desplaza solo); al soltar aparece, junto al dedo o al mouse, una barra con los colores, «Nota», «Traducir» y «Copiar».
  El botón «Notas» de arriba muestra las burbujas.
- **Primer inicio:** la app pregunta el idioma de la interfaz; después se cambia en Ajustes.
- **Ajustes:** cambiar el idioma (toda la app cambia, incluido el significado de las palabras), elegir el
  tema (Automático / Claro / Oscuro), activar el recordatorio y buscar actualizaciones del contenido.

### Instalarla en un teléfono Android sin la tienda

    flutter build apk --release

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`. Pasalo al teléfono y abrilo; Android pide
permiso para instalar apps de origen desconocido.

### iPhone

Abrí `ios/Runner.xcworkspace` en Xcode, elegí tu equipo en *Signing & Capabilities* y ejecutala en el iPhone
conectado. Otra opción es usar `flutter run` con el iPhone conectado.

## 4. Publicar en las tiendas

- **Google Play:**
  1. Generá el paquete con `flutter build appbundle`.
  2. Antes, configurá la firma: https://docs.flutter.dev/deployment/android
- **App Store:**
  1. Generá el paquete con `flutter build ipa`.
  2. Subilo con Xcode o Transporter: https://docs.flutter.dev/deployment/ios

## 5. Actualizar el contenido

- **Sin publicar una versión nueva:** subí la carpeta `content/` de la web a GitHub Pages, como siempre. Ahí va
  `content/en/manifest.json`, que genera `build.py`. Al abrirse con conexión, la app compara ese índice con el
  suyo y descarga solo los archivos que cambiaron. También se puede forzar desde *Ajustes → Buscar
  actualizaciones*.
- **Para incluir el contenido nuevo dentro de la app**, antes de compilar una versión nueva ejecutá desde esta
  carpeta:

      python3 tool/contenido/generar.py   # lecturas y libros B1–B2 nuevos (fuentes en tool/contenido/)
      python3 tool/contenido.py           # valida, rehace manifest.json y copia a assets/content/en

  `tool/contenido.py` reemplaza a `app_sync.py` (el generador original no está en este equipo): copia el contenido
  de `../web-idiomas/content/en`, rehace el manifest y actualiza la lista de carpetas de `pubspec.yaml`. Los textos
  de la app que no vienen de la web están en `assets/i18n/app.json`.

La dirección de la web está en `lib/core/content.dart` (`Content.siteUrl`).

## Estructura

    lib/
      main.dart              arranque y navegación (Hoy · Leer · Palabras · Gramática · Ajustes)
      core/                  contenido y actualizaciones, idiomas, tema, progreso, audio, recordatorios
      ui/                    colores (tema claro y oscuro) y tipografía, piezas del diseño, markdown de las explicaciones
      today/                 «Hoy» (plan diario y progreso) y autoevaluación «puedo…»
      course/                gramática (consulta), lección, ejercicios, práctica, examen, prueba de nivel,
                             vocabulario y dictogloss
      reading/               lecturas, libros, lector y sus actividades (activities.dart), notas
      words/                 «Palabras» y su repaso espaciado escrito
      settings_screen.dart   ajustes
    assets/
      content/en/            el contenido de la web (JSON)
      i18n/ui.json           textos de la interfaz de la web (generado)
      i18n/app.json          textos propios de la app
      fonts/                 IBM Plex (licencia SIL OFL, ver OFL.txt)
    tool/configurar_plataformas.py
    tool/contenido.py        valida y sincroniza el contenido de la web
    tool/contenido/          fuentes del contenido B1–B2 nuevo (lecturas, libros, diccionario) y generar.py

**Diferencias con la web:**

- La app es solo para B1–B2 y la gramática es de consulta (todo abierto); la web tiene el curso completo A1–B2.
- Los ejercicios de pronunciación de las lecciones no graban la voz; la grabación está en «escuchar y repetir» y
  «volver a contarlo» del lector.
- Las hojas para imprimir, el repaso mixto y las preguntas frecuentes quedan solo en la web.
