# Trilex (app para Android e iOS)

App en Flutter de Trilex para **autoaprendizaje de inglés en nivel intermedio (B1–B2)**, con el mismo diseño y el
mismo contenido que la web. Para los niveles principiantes (A1–A2) está la web.

- **Hoy:** plan diario (leer → repasar palabras → producir con dictogloss o volver a contarlo), progreso de lectura
  y autoevaluación «puedo…» de B1 y B2.
- **Leer:** lecturas B1–B2 y libros completos. Incluye traducción al tocar una palabra o una frase corta,
  subrayados con notas, escuchar y repetir (con grabación), completar huecos, resumen guiado, lectura cronometrada
  y volver a contarlo.
- **Palabras:** repaso espaciado escrito de las palabras guardadas y del vocabulario de las lecciones.
- **Gramática:** las unidades B1–B2 como material de consulta, con lectura recomendada, dictogloss y exámenes de
  autoevaluación, más una prueba de nivel B1/B2. El nivel B2 se desbloquea al obtener B2 en la prueba o al aprobar
  el examen B1. Si la prueba da un nivel inferior a B1, los dos niveles quedan cerrados y la app recomienda la web.
- **Recordatorio diario:** un aviso para cumplir la meta de estudio.
- **Idiomas:** la interfaz está disponible en los 8 idiomas de la web.
- **Tema:** automático (sigue la configuración del teléfono), claro u oscuro, igual que en la web.
- **Datos:** el progreso se guarda solo en el teléfono. No hace falta crear una cuenta.
- **Contenido:** viene incluido en la app y se actualiza automáticamente desde la web cuando hay conexión.

## 1. Requisitos

1. **Flutter** 3.24 o posterior. Guía de instalación: https://docs.flutter.dev/get-started/install
   Para comprobar que la instalación está bien, ejecutá en una terminal:

       flutter doctor

2. **Para Android:** Android Studio, con un emulador o un teléfono Android con la «depuración USB» activada.
3. **Para iOS:** una Mac con Xcode. Para instalar la app en un iPhone propio alcanza con una cuenta de Apple
   gratuita. Para publicarla en la App Store hace falta una cuenta de Apple Developer (USD 99 por año).
4. **Python 3**, para los scripts de la carpeta `tool/`.

## 2. Preparar el proyecto

Esto se hace una sola vez. En una terminal, dentro de la carpeta del proyecto (`trilex/`):

    flutter create --org com.trilex --project-name trilex --platforms android,ios .
    python3 tool/configurar_plataformas.py
    flutter pub get

1. `flutter create` genera las carpetas `android/` e `ios/`, que no se incluyen en el repositorio. No modifica
   `lib/` ni `pubspec.yaml`.
2. Si pregunta si querés reemplazar archivos existentes, respondé que no.
3. `configurar_plataformas.py` configura el nombre «Trilex», el identificador `com.trilex.app`, los permisos de
   internet y notificaciones, y lo necesario para los recordatorios en Android e iOS. Se puede ejecutar más de una
   vez sin problema. También borra `test/widget_test.dart`, la prueba de ejemplo que crea `flutter create`, que
   no funciona con este proyecto.

## 3. Ejecutar la app

Con el emulador abierto o el teléfono conectado:

    flutter run

`flutter run` arranca en modo de depuración, que es bastante más lento (sobre todo la primera vez que se abre
cada pantalla). Para ver la velocidad real:

    flutter run --profile

Para correr las pruebas automáticas de la lógica (corrección de respuestas, mezcla de opciones y formato):

    flutter test

### Cómo se usa

- **Primer inicio:** la app pregunta el idioma de la interfaz. Después se puede cambiar en Ajustes.
- **Lectura:** al tocar una palabra de un texto se ven su traducción y su definición. Desde esa misma ventana se
  puede subrayar la palabra o la oración con un color, o escribir una nota.
  - **Subrayar varias palabras o párrafos:** mantené presionada una palabra y arrastrá. Con mouse, hacé clic y
    arrastrá. Cerca del borde, el texto se desplaza solo.
  - **Al soltar** aparece, junto al dedo o al mouse, una barra con los colores, «Nota», «Traducir» y «Copiar».
  - **El botón «Notas»** de arriba muestra las notas guardadas.
- **Ajustes:**
  - **Idioma:** cambia toda la app, incluido el significado de las palabras.
  - **Tema:** Automático / Claro / Oscuro.
  - **Recordatorio:** activa el aviso diario.
  - **Contenido:** permite buscar actualizaciones.

### Instalar en un teléfono Android sin la tienda

    flutter build apk --release

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`. Pasalo al teléfono y abrilo. Android va a
pedir permiso para instalar apps de origen desconocido.

### Instalar en un iPhone

Abrí `ios/Runner.xcworkspace` en Xcode, elegí tu equipo en *Signing & Capabilities* y ejecutá la app en el iPhone
conectado. También se puede usar `flutter run` con el iPhone conectado.

## 4. Publicar en las tiendas

- **Google Play:**
  1. Configurá la firma de la app: https://docs.flutter.dev/deployment/android
  2. Generá el paquete con `flutter build appbundle`.
- **App Store:**
  1. Generá el paquete con `flutter build ipa`.
  2. Subilo con Xcode o Transporter: https://docs.flutter.dev/deployment/ios

## 5. Actualizar el contenido

- **Sin publicar una versión nueva de la app:** publicá la carpeta `content/` de la web en GitHub Pages. Esa
  carpeta incluye `content/en/manifest.json`, que genera `build.py`. Cuando la app se abre con conexión, compara
  ese índice con el suyo y descarga solo los archivos que cambiaron. También se puede forzar desde
  *Ajustes → Buscar actualizaciones*.
- **Para incluir el contenido nuevo dentro de la app**, ejecutá desde la carpeta del proyecto antes de compilar una
  versión nueva:

      python3 tool/contenido/generar.py   # genera las lecturas y los libros B1–B2 nuevos (fuentes en tool/contenido/)
      python3 tool/contenido.py           # valida, rehace manifest.json y copia a assets/content/en

  `tool/contenido.py` copia el contenido de `../web-idiomas/content/en`, así que el repositorio de la web tiene que
  estar en una carpeta `web-idiomas` junto a esta. Además rehace el manifest y actualiza la lista de carpetas de
  `pubspec.yaml`.

Los textos propios de la app, que no vienen de la web, están en `assets/i18n/app.json`. La dirección de la web
está en `lib/core/content.dart` (`Content.siteUrl`).

## Estructura

    lib/
      main.dart              arranque y navegación (Hoy · Leer · Palabras · Gramática · Ajustes)
      core/                  contenido y actualizaciones, idiomas, tema, progreso, audio, recordatorios
      ui/                    colores (tema claro y oscuro), tipografía, piezas del diseño, markdown de las explicaciones
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
    tool/configurar_plataformas.py   configura Android e iOS después de flutter create
    tool/contenido.py                valida y sincroniza el contenido de la web
    tool/contenido/                  fuentes del contenido B1–B2 nuevo (lecturas, libros, diccionario) y generar.py
    tool/icono/                      ícono de la app (icono.svg) y generar.py

## Diferencias con la web

- La app es solo para B1–B2 y la gramática es de consulta (todo abierto). La web tiene el curso completo A1–B2.
- Los ejercicios de pronunciación de las lecciones no graban la voz. La grabación está en «escuchar y repetir» y
  «volver a contarlo» del lector.
- Las hojas para imprimir, el repaso mixto y las preguntas frecuentes están solo en la web.

## Ícono de la app

El ícono se genera a partir de `tool/icono/icono.svg`. Para regenerarlo hace falta tener `rsvg-convert` instalado:

    python3 tool/icono/generar.py

Genera los íconos de Android y, si existen sus carpetas, también los de iOS y Linux.
