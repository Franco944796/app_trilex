"""Genera los íconos de la app a partir de tool/icono/icono.svg (hace falta rsvg-convert).

Uso (desde trilex/):  python3 tool/icono/generar.py
- Android: android/app/src/main/res/mipmap-*/ic_launcher.png (esquinas redondeadas).
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


def render(size: int, out: Path, radius: int) -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(SVG.replace("RADIO", str(radius)))
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
        hechos.append("Android")
    ios = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    if (ios / "Contents.json").exists():
        for img in json.loads((ios / "Contents.json").read_text())["images"]:
            if "filename" not in img:
                continue
            pts = float(img["size"].split("x")[0])
            render(round(pts * int(img["scale"][0])), ios / img["filename"], 0)
        hechos.append("iOS")
    render(256, APP / "assets/icon/app.png", 220)
    hechos.append("Linux")
    print("Íconos generados:", ", ".join(hechos))
    return 0


if __name__ == "__main__":
    sys.exit(main())
