"""Libros de dominio público B1–B2: divide el texto original en capítulos y les suma el glosario,
las preguntas y el resumen de libro_<id>.py.

Los textos vienen de Project Gutenberg (libros_fuente/, sin el encabezado ni el pie de Gutenberg).
Todos los autores murieron hace más de 70 años: son de dominio público también en Argentina y la UE.
"""

import importlib
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE / "libros_fuente"

ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI",
         "XVII", "XVIII", "XIX", "XX"]

# id del libro → módulo con META y CHAPTERS, y cómo se reconocen sus títulos de capítulo
BOOKS = {
    "christmas-carol": ("libro_christmas_carol", r"^STAVE [IVX]+:.*$"),
    "call-of-the-wild": ("libro_call_of_the_wild", r"^Chapter [IVX]+\..*$"),
    "time-machine": ("libro_time_machine", r"^ ?(?:[IVX]+\.|Epilogue)$"),
    "dorian-gray": ("libro_dorian_gray", r"^CHAPTER [IVX]+\.$"),
}

GLOSARIO: dict = {}


def clean(par: str) -> str:
    par = re.sub(r"\[Footnote:[^\]]*\]", "", par)
    par = re.sub(r"_([^_]+)_", r"\1", par)  # cursivas de Gutenberg
    par = par.replace("_", "")
    return re.sub(r"\s+", " ", par).strip()


def split_chapters(book_id: str, pattern: str) -> list[list[str]]:
    """Párrafos de cada capítulo, en orden. Lo anterior al primer capítulo (prefacio, índice) se descarta."""
    lines = (SRC / f"{book_id}.txt").read_text(encoding="utf-8").split("\n")
    heads = [i for i, line in enumerate(lines) if re.match(pattern, line)]
    if book_id == "time-machine":
        # el índice del principio termina en «Epilogue»: los capítulos empiezan después
        first = next(i for i, line in enumerate(lines) if line.strip() == "Epilogue")
        heads = [i for i in heads if i > first]
    chapters = []
    for k, start in enumerate(heads):
        end = heads[k + 1] if k + 1 < len(heads) else len(lines)
        body = "\n".join(lines[start + 1:end])
        blocks = []
        for raw in re.split(r"\n\s*\n", body):
            rows = [r.strip() for r in raw.strip().split("\n") if r.strip()]
            if not rows or not re.search("[A-Za-z]", raw) or raw.strip() == "THE END":
                continue
            # poemas (líneas cortas): se guardan como verso, con sus saltos de línea
            if len(rows) >= 3 and all(len(r) <= 45 for r in rows):
                blocks.append({"t": "v", "text": "\n".join(clean(r) for r in rows)})
            else:
                blocks.append({"t": "p", "text": clean(raw)})
        if book_id == "time-machine" and blocks and lines[start].strip() != "Epilogue":
            blocks.pop(0)  # la línea con el título del capítulo (el epílogo no tiene)
        chapters.append(blocks)
    if book_id == "time-machine":
        chapters[-2].extend(chapters.pop())  # el epílogo es corto: va con el último capítulo
    return chapters


def appears(term: str, text: str) -> bool:
    return re.search(r"\b" + re.escape(term) + r"\b", text, re.I) is not None


def build(reading: Path, write, errors: list, minutes) -> tuple[list[dict], list[str]]:
    index_entries, terms = [], []
    for book_id, (module, pattern) in BOOKS.items():
        mod = importlib.import_module(module)
        GLOSARIO.update(mod.GLOSARIO)
        chapters = split_chapters(book_id, pattern)
        if len(chapters) != len(mod.CHAPTERS):
            errors.append(f"{book_id}: el texto tiene {len(chapters)} capítulos y hay datos de {len(mod.CHAPTERS)}")
            continue
        listing, total = [], 0
        for n, (blocks, ch) in enumerate(zip(chapters, mod.CHAPTERS), 1):
            text = " ".join(b["text"] for b in blocks)
            words = len(text.split())
            total += words
            for en, _ in ch["glossary"]:
                terms.append(en)
                if not appears(en, text):
                    errors.append(f"{book_id} cap. {n}: {en!r} no aparece tal cual en el texto")
            for q in ch["questions"]:
                if q["type"] == "fill" and not any(a.lower() in text.lower() for a in q["answer"]):
                    errors.append(f"{book_id} cap. {n}: la respuesta {q['answer']} no aparece en el texto")
            write(reading / "books" / book_id / f"ch-{n:02d}.json", {
                "book": book_id,
                "n": n,
                "title": ch["title"],
                "words": words,
                "summary_es": ch["summary_es"],
                "blocks": blocks,
                "glossary": [{"en": en, "es": es} for en, es in ch["glossary"]],
                "questions": ch["questions"],
            })
            listing.append({"n": n, "title": ch["title"], "words": words, "minutes": round(words / 150),
                            "questions": len(ch["questions"])})
        meta = {**mod.META, "id": book_id, "words": total, "hours": round(total / 150 / 60, 1)}
        write(reading / "books" / book_id / "book.json", {
            k: meta[k] for k in ("id", "title", "author", "year", "level", "cover", "blurb", "words", "hours")
        } | {"chapters": listing})
        index_entries.append({k: meta[k] for k in ("id", "title", "author", "year", "level", "cover", "blurb",
                                                   "words", "hours")} | {"chapters": len(listing)})
    return index_entries, terms
