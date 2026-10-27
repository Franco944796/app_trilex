"""Sincroniza el contenido de la web con la app.

Uso (desde trilex/):  python3 tool/contenido.py

1. Valida el contenido de ../web-idiomas/content/en (JSON legible, lecturas y libros coherentes).
2. Rehace manifest.json, que la app usa para descargar las actualizaciones desde la web.
3. Copia el contenido a assets/content/en y actualiza la lista de carpetas de pubspec.yaml.

Reemplaza a tools/app_sync.py y a la parte de manifest de tools/build.py, que no están en esta
computadora. Formato del manifest (el que espera lib/core/content.dart):
  files   = {ruta: sha1(bytes)[:16]} de todos los .json salvo el propio manifest (los PDF no van)
  version = sha1(json.dumps(files, sort_keys=True))[:12]
"""

import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

APP = Path(__file__).resolve().parent.parent
WEB = APP.parent / "web-idiomas" / "content" / "en"
DEST = APP / "assets" / "content" / "en"
PUBSPEC = APP / "pubspec.yaml"

errors: list[str] = []
warnings: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def load(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        err(f"{path.relative_to(WEB)}: JSON inválido ({e})")
        return None


def joined(v) -> str:
    return "\n".join(v) if isinstance(v, list) else str(v or "")


def norm(s: str) -> str:
    """Igual que norm() del lector: minúsculas, apóstrofos y solo letras."""
    s = s.lower().replace("’", "'").replace("‘", "'").replace("`", "'")
    s = re.sub(r"[^a-z' -]", "", s)
    return re.sub(r"\s+", " ", s).strip()


def check_questions(where: str, qs: list, text: str) -> None:
    low = text.lower()
    for i, q in enumerate(qs, 1):
        t = q.get("type")
        if t == "mc":
            if q.get("answer") not in q.get("options", []):
                err(f"{where} pregunta {i}: la respuesta no está entre las opciones")
            if len(set(q.get("options", []))) != len(q.get("options", [])):
                err(f"{where} pregunta {i}: opciones repetidas")
        elif t == "tf":
            if not isinstance(q.get("answer"), bool):
                err(f"{where} pregunta {i}: verdadero/falso sin respuesta booleana")
        elif t == "fill":
            ans = q.get("answer") or []
            if not ans or not all(norm(a) for a in ans):
                err(f"{where} pregunta {i}: completar sin respuesta válida (solo letras)")
            elif not any(a.lower() in low for a in ans):
                err(f"{where} pregunta {i}: la respuesta de completar no aparece en el texto")
        else:
            err(f"{where} pregunta {i}: tipo desconocido {t!r}")
        if not q.get("q") or not q.get("why"):
            err(f"{where} pregunta {i}: falta el enunciado o la explicación")


def check_glossary(where: str, gl: list, text: str) -> None:
    for g in gl:
        en = g.get("en", "")
        if not en or not g.get("es"):
            err(f"{where}: entrada de glosario incompleta {g}")
        elif not re.search(r"\b" + re.escape(en) + r"\b", text, re.I):
            # el glosario usa la forma base: «waiter» para «waiters» es correcto, solo se avisa
            warn(f"{where}: {en!r} no aparece tal cual en el texto")


def validate() -> None:
    ix = load(WEB / "reading" / "index.json")
    if not ix:
        return
    for t in ix["texts"]:
        d = load(WEB / "reading" / "texts" / f"{t['id']}.json")
        if not d:
            continue
        text = " ".join(d["paragraphs"])
        check_glossary(t["id"], d.get("glossary", []), text)
        check_questions(t["id"], d.get("questions", []), text)
        words = len(text.split())
        if abs(words - t["words"]) > max(5, words // 20):
            err(f"{t['id']}: index.json dice {t['words']} palabras y el texto tiene {words}")
        if t["questions"] != len(d.get("questions", [])):
            err(f"{t['id']}: index.json dice {t['questions']} preguntas y hay {len(d.get('questions', []))}")
    for b in ix["books"]:
        bd = WEB / "reading" / "books" / b["id"]
        book = load(bd / "book.json")
        if not book:
            continue
        chs = book.get("chapters", [])
        if len(chs) != b["chapters"]:
            err(f"{b['id']}: index.json dice {b['chapters']} capítulos y book.json tiene {len(chs)}")
        for c in chs:
            ch = load(bd / f"ch-{c['n']:02d}.json")
            if not ch:
                continue
            text = " ".join(joined(x.get("text")) for x in ch.get("blocks", []))
            where = f"{b['id']} cap. {c['n']}"
            check_glossary(where, ch.get("glossary", []), text)
            check_questions(where, ch.get("questions", []), text)
    ex = load(WEB / "extras.json") or {}
    texts = {t["id"] for t in ix["texts"]}
    for k in ex.get("summaries", {}):
        if k not in texts:
            err(f"extras.json: resumen de una lectura que no existe ({k})")
    for u, t in ex.get("unit_readings", {}).items():
        if t not in texts:
            err(f"extras.json: la unidad {u} apunta a una lectura que no existe ({t})")


def manifest() -> dict:
    files = {}
    for p in sorted(WEB.rglob("*.json")):
        rel = p.relative_to(WEB).as_posix()
        if rel == "manifest.json":
            continue
        files[rel] = hashlib.sha1(p.read_bytes()).hexdigest()[:16]
    version = hashlib.sha1(json.dumps(files, sort_keys=True).encode()).hexdigest()[:12]
    return {"version": version, "files": files}


def copy_to_app(files: dict) -> list[str]:
    keep = set(files) | {"manifest.json"}
    for p in DEST.rglob("*"):
        if p.is_file() and p.relative_to(DEST).as_posix() not in keep:
            p.unlink()
    for rel in keep:
        dst = DEST / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(WEB / rel, dst)
    for d in sorted(DEST.rglob("*"), reverse=True):
        if d.is_dir() and not any(d.iterdir()):
            d.rmdir()
    return sorted({(DEST / r).parent.relative_to(APP).as_posix() + "/" for r in keep})


def update_pubspec(dirs: list[str]) -> None:
    s = PUBSPEC.read_text(encoding="utf-8")
    start, end = "    # contenido: inicio\n", "    # contenido: fin\n"
    a, b = s.index(start) + len(start), s.index(end)
    s = s[:a] + "".join(f"    - {d}\n" for d in dirs) + s[b:]
    PUBSPEC.write_text(s, encoding="utf-8")


def main() -> int:
    validate()
    if errors:
        print("Errores en el contenido (no se sincronizó nada):")
        for e in errors:
            print("  -", e)
        return 1
    if warnings:
        print(f"{len(warnings)} avisos (glosario en forma base; revisar solo si el contenido es nuevo):")
        for w in warnings:
            print("  -", w)
    m = manifest()
    (WEB / "manifest.json").write_text(json.dumps(m, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    dirs = copy_to_app(m["files"])
    update_pubspec(dirs)
    print(f"OK: {len(m['files'])} archivos, versión {m['version']}, {len(dirs)} carpetas en pubspec.yaml")
    return 0


if __name__ == "__main__":
    sys.exit(main())
