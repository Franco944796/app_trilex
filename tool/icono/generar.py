"""Genera los íconos de la app a partir de tool/icono/icono.svg (hace falta rsvg-convert).

Uso (desde trilex/):  python3 tool/icono/generar.py
- Android 8+: ícono adaptable (mipmap-anydpi-v26/ic_launcher.xml) con fondo, frente y versión monocroma, para
  que el launcher lo recorte en círculo o la forma que use sin dejar un borde blanco.
- Android viejo: android/app/src/main/res/mipmap-*/ic_launcher.png (esquinas redondeadas).
- iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset (cuadrado: iOS redondea solo y no acepta transparencia).
- Linux: assets/icon/app.png (ícono de la ventana, lo carga linux/runner/my_application.cc).
"""

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
SVG = (HERE / "icono.svg").read_text(encoding="utf-8")
ENTERO = "translate(0 0)"
# Capa de 108 dp de la que el launcher muestra solo el centro (72 dp) y recorta hasta 66 dp: el ∴ se achica
# y se centra (su centro está en y=566.7) para que quede del mismo tamaño que en el ícono viejo.
ADAPTABLE = "translate(512 512) scale(.66) translate(-512 -566.7)"
ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_fondo"/>
    <foreground android:drawable="@mipmap/ic_launcher_frente"/>
    <monochrome android:drawable="@mipmap/ic_launcher_mono"/>
</adaptive-icon>
"""


def capa(nombre: str) -> str:
    fondo_ini = SVG.index('<g id="fondo">')
    fondo_fin = SVG.index("</g>", fondo_ini) + len("</g>")
    motivo_ini = SVG.index('<g id="motivo"')
    motivo_fin = SVG.rindex("</svg>")
    if nombre == "fondo":
        return SVG[:motivo_ini] + SVG[motivo_fin:]
    sin_fondo = SVG[:fondo_ini] + SVG[fondo_fin:]
    if nombre == "frente":
        return sin_fondo.replace("ESCALA", ADAPTABLE)
    # Android 13 solo usa la opacidad de esta capa y la tiñe con el color del tema: sin brillos queda nítida.
    return (
        sin_fondo.replace("ESCALA", ADAPTABLE)
        .replace(' filter="url(#glow)"', "")
        .replace(' filter="url(#glowChico)"', "")
    )


def render(size: int, out: Path, radius: int, svg: str | None = None) -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write((svg or SVG.replace("ESCALA", ENTERO)).replace("RADIO", str(radius)))
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), "-o", str(out), f.name], check=True)
    Path(f.name).unlink()


def main() -> int:
    if not shutil.which("rsvg-convert"):
        print("Falta rsvg-convert (paquete librsvg); no se generaron íconos.")
        return 1
    hechos = []
    res = APP / "android/app/src/main/res"
    if res.exists():
        for carpeta, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
            render(size, res / f"mipmap-{carpeta}/ic_launcher.png", 220)
            for nombre in ("fondo", "frente", "mono"):
                render(size * 9 // 4, res / f"mipmap-{carpeta}/ic_launcher_{nombre}.png", 0, capa(nombre))
        (res / "mipmap-anydpi-v26").mkdir(exist_ok=True)
        (res / "mipmap-anydpi-v26/ic_launcher.xml").write_text(ADAPTIVE_XML, encoding="utf-8")
        hechos.append("Android")
    ios = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    if (ios / "Contents.json").exists():
        for img in json.loads((ios / "Contents.json").read_text())["images"]:
            if "filename" not in img:
                continue
            pts = float(img["size"].split("x")[0])
            render(round(pts * int(img["scale"][0])), ios / img["filename"], 0, SVG.replace("ESCALA", ENTERO))
        hechos.append("iOS")
    render(256, APP / "assets/icon/app.png", 220)
    hechos.append("Linux")
    print("Íconos generados:", ", ".join(hechos))
    return 0


if __name__ == "__main__":
    sys.exit(main())
