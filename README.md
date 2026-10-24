# Trilex (app para Android e iOS)

App en Flutter del curso de inglés de Trilex, con el mismo diseño y el mismo contenido que la web.

- **Curso:** mapa por niveles, lecciones en una página, prueba de nivel, repaso y exámenes finales.
- **Lectura:** textos por nivel y libros completos, con la traducción al tocar una palabra, subrayados con notas y PDF de los libros.
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
   Se puede ejecutar más de una vez sin problema.

## 3. Probarla

Con el emulador abierto o el teléfono conectado:

    flutter run

Qué conviene probar:

- **Curso:** abrir una lección y responder los ejercicios. El puntaje se actualiza en la barra de abajo y, al
  terminar, aparece el resultado y se desbloquea la lección siguiente.
- **Modo prueba:** al final del mapa hay un interruptor que abre todas las lecciones y los exámenes.
- **Lectura:** abrir un texto y tocar una palabra para ver su traducción y su definición. Desde esa misma
  ventana se puede subrayar la palabra o la oración con un color, o escribir una nota.
  El botón «Notas» de arriba muestra las burbujas.
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
- **Para incluir el contenido nuevo dentro de la app**, antes de compilar una versión nueva ejecutá desde la
  carpeta de trabajo:

      cd tools
      python3 build.py
      python3 app_sync.py <ruta a esta carpeta trilex> <ruta a la carpeta ingles/ de la web>

  `app_sync.py` copia los JSON del contenido a `assets/content/en`, genera `assets/i18n/ui.json` con los textos de
  la web y actualiza la lista de carpetas de `pubspec.yaml`.

La dirección de la web está en `lib/core/content.dart` (`Content.siteUrl`).

## Estructura

    lib/
      main.dart              arranque y navegación (Curso · Lectura · Ajustes)
      core/                  contenido y actualizaciones, idiomas, tema, progreso, audio, recordatorios
      ui/                    colores (tema claro y oscuro) y tipografía, piezas del diseño, markdown de las explicaciones
      course/                mapa, lección, ejercicios, práctica, examen, prueba de nivel, repaso, vocabulario
      reading/               lecturas, libros, lector (palabras, subrayados, notas, preguntas), palabras y notas
      settings_screen.dart   ajustes
    assets/
      content/en/            el contenido de la web (JSON)
      i18n/ui.json           textos de la interfaz de la web (generado)
      i18n/app.json          textos propios de la app
      fonts/                 IBM Plex (licencia SIL OFL, ver OFL.txt)
    tool/configurar_plataformas.py

**Diferencias con la web:**

- Los ejercicios de pronunciación no graban la voz: se escucha el modelo y se marca como practicado.
- Las hojas para imprimir quedan solo en la web.
