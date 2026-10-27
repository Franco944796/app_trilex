"""Genera el contenido intermedio nuevo y lo escribe en ../web-idiomas/content/en.

Uso (desde trilex/):
    python3 tool/contenido/generar.py   # escribe lecturas, libros, índice, extras, diccionario y temas
    python3 tool/contenido.py           # valida, rehace el manifest y copia a la app

Se puede repetir: cada vez reemplaza lo que generó antes y deja intacto el resto del contenido.
"""

import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import glosario_b1  # noqa: E402
import glosario_b2  # noqa: E402
import lecturas_b1  # noqa: E402
import lecturas_b2  # noqa: E402
import libros  # noqa: E402

APP = HERE.parent.parent
WEB = APP.parent / "web-idiomas"
CONTENT = WEB / "content" / "en"
READING = CONTENT / "reading"
DICT_LANGS = ["en", "fr", "de", "it", "pt", "ru", "zh"]  # orden de las tuplas de glosario_*.py

# temas nuevos: [en, es, fr, de, it, pt, ru, zh]
TOPICS = {
    "Aprender idiomas": ["Learning languages", "Aprender idiomas", "Apprendre les langues", "Sprachen lernen",
                         "Imparare le lingue", "Aprender idiomas", "Изучение языков", "学习语言"],
    "Deporte": ["Sport", "Deporte", "Sport", "Sport", "Sport", "Esporte", "Спорт", "体育"],
    "Consumo": ["Shopping and consumption", "Consumo", "Consommation", "Konsum", "Consumi", "Consumo",
                "Потребление", "消费"],
    "Ciencia": ["Science", "Ciencia", "Science", "Wissenschaft", "Scienza", "Ciência", "Наука", "科学"],
    "Arte": ["Art", "Arte", "Art", "Kunst", "Arte", "Arte", "Искусство", "艺术"],
}

# lectura recomendada por unidad del curso (reemplaza la elegida antes cuando hay una más afín)
UNIT_READINGS = {
    "en-b1-u02": "b1-library-of-things",
    "en-b1-u03": "b1-job-interview",
    "en-b1-u04": "b1-teen-sleep",
    "en-b1-u05": "b1-phone-free-school",
    "en-b1-u06": "b1-ghost-town",
    "en-b1-u07": "b1-second-hand",
    "en-b1-u08": "b1-language-exchange",
    "en-b1-u10": "b1-coffee",
    "en-b1-u12": "b1-marathon",
    "en-b2-u01": "b2-failure",
    "en-b2-u04": "b2-placebo",
    "en-b2-u06": "b2-overtourism",
    "en-b2-u07": "b2-remote-towns",
    "en-b2-u08": "b2-bilingual-brain",
    "en-b2-u10": "b2-art-forger",
    "en-b2-u11": "b2-local-news",
    "en-b2-u13": "b2-lighthouse-keeper",
    "en-b2-u14": "b2-urban-heat",
}

errors: list[str] = []


def norm(s: str) -> str:
    """Igual que norm() del lector y que tools/i18n_build.py."""
    s = s.lower().replace("’", "'").replace("‘", "'").replace("`", "'")
    s = re.sub(r"[^a-z' -]", "", s)
    return re.sub(r"\s+", " ", s).strip()


def minutes(words: int) -> int:
    return max(1, round(words / 130))


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def appears(term: str, text: str) -> bool:
    return re.search(r"\b" + re.escape(term) + r"\b", text, re.I) is not None


def build_texts() -> list[dict]:
    out = []
    for level, mod in (("B1", lecturas_b1), ("B2", lecturas_b2)):
        for t in mod.TEXTS:
            text = " ".join(t["paragraphs"])
            for en, _ in t["glossary"]:
                if not appears(en, text):
                    errors.append(f"{t['id']}: {en!r} no aparece tal cual en el texto")
            words = len(text.split())
            data = {
                "id": t["id"],
                "level": level,
                "title": t["title"],
                "title_es": t["title_es"],
                "topic": t["topic"],
                "glossary": [{"en": en, "es": es} for en, es in t["glossary"]],
                "questions": t["questions"],
                "task": t["task"],
                "words": words,
                "minutes": minutes(words),
                "paragraphs": t["paragraphs"],
            }
            write(READING / "texts" / f"{t['id']}.json", data)
            out.append({**data, "summary": t["summary"]})
    return out


def update_index(texts: list[dict], books: list[dict]) -> None:
    ix = load(READING / "index.json")
    new_ids = {t["id"] for t in texts}
    old = [t for t in ix["texts"] if t["id"] not in new_ids]
    entries = [
        {k: t[k] for k in ("id", "level", "title", "title_es", "topic", "words", "minutes")}
        | {"questions": len(t["questions"])}
        for t in texts
    ]
    order = {lv: i for i, lv in enumerate(ix["levels"])}
    ix["texts"] = sorted(old + entries, key=lambda t: order[t["level"]])  # sorted es estable: se mantiene el orden
    book_ids = {b["id"] for b in books}
    ix["books"] = [b for b in ix["books"] if b["id"] not in book_ids] + books
    write(READING / "index.json", ix)


def update_extras(texts: list[dict]) -> None:
    ex = load(CONTENT / "extras.json")
    for t in texts:
        ex["summaries"][t["id"]] = t["summary"]
    ex["unit_readings"].update(UNIT_READINGS)
    write(CONTENT / "extras.json", ex)


OWN = HERE / "diccionario_propio.json"  # palabras que agregó este generador (las demás no se tocan)


def update_dictionary(terms: list[str], table: dict) -> None:
    dicts = {lg: load(READING / "i18n" / f"{lg}.json") for lg in DICT_LANGS}
    own = set(load(OWN)) if OWN.exists() else set()
    added = 0
    for term in terms:
        k = norm(term)
        if k in dicts["fr"]["gloss"] and k not in own:
            continue  # estaba en el diccionario original: se respeta su traducción
        row = table.get(term) or next((v for t, v in table.items() if norm(t) == k), None)
        if row is None:
            errors.append(f"diccionario: falta la traducción de {term!r}")
            continue
        for lg, val in zip(DICT_LANGS, row):
            dicts[lg]["gloss"][k] = val
        own.add(k)
        added += 1
    OWN.write_text(json.dumps(sorted(own), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    for lg, d in dicts.items():
        write(READING / "i18n" / f"{lg}.json", d)
    print(f"diccionario: {added} palabras nuevas o actualizadas")


def update_topics() -> None:
    # web: se agregan con TXI.add(), que acepta temas como segundo argumento
    js = WEB / "ingles" / "trilex-i18n.js"
    s = js.read_text(encoding="utf-8")
    start, end = "\n// temas nuevos (tool/contenido/generar.py): inicio\n", "// temas nuevos: fin\n"
    if start in s:
        s = s[: s.index(start)] + s[s.index(end) + len(end):]
    body = "".join(f"    {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)},\n"
                   for k, v in TOPICS.items())
    s = s.rstrip("\n") + "\n" + start + "TXI.add({}, {\n" + body + "});\n" + end
    js.write_text(s, encoding="utf-8")
    # app: assets/i18n/ui.json (antes lo escribía tools/app_sync.py)
    ui_path = APP / "assets" / "i18n" / "ui.json"
    ui = load(ui_path)
    ui["topics"].update(TOPICS)
    ui_path.write_text(json.dumps(ui, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def main() -> int:
    texts = build_texts()
    books, book_terms = libros.build(READING, write, errors, minutes)
    update_index(texts, books)
    update_extras(texts)
    table = {**glosario_b1.G, **glosario_b2.G, **libros.GLOSARIO}
    terms = [g["en"] for t in texts for g in t["glossary"]] + book_terms
    update_dictionary(terms, table)
    update_topics()
    if errors:
        print("Errores:")
        for e in errors:
            print("  -", e)
        return 1
    print(f"OK: {len(texts)} lecturas y {len(books)} libros")
    return 0


if __name__ == "__main__":
    sys.exit(main())
