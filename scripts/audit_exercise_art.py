#!/usr/bin/env python3
"""Gymbro: inventario, validación técnica y hojas visuales del arte de ejercicios.

Uso desde la raíz del repositorio:
    .venv-art/bin/python scripts/audit_exercise_art.py
    .venv-art/bin/python scripts/audit_exercise_art.py --contact-sheets

La inspección automática NO sustituye la validación humana de personaje,
equipamiento, cámara, fase muscular, sombra y relación imagen-caption.
"""
from __future__ import annotations

import argparse
import csv
import re
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Apps/Gymbro/Resources/ExerciseArt"
SWIFT = ROOT / "Apps/Gymbro/Sources/ExerciseArt.swift"
CATALOG = ROOT / "Packages/GymbroDomain/Sources/GymbroDomain/CatalogSpanish.swift"
HERO_RE = re.compile(r'^\s*"([^"]+)": "(art_[^"]+)"', re.MULTILINE)

# Inspeccionadas visualmente y pendientes de redibujar / reexportar.
KNOWN_ISSUES = {
    "art_cf_thruster_3": ("WARN", "Sustituido por el hero con barra overhead; comprobar uniformidad de cámara", "Revisión final de la pose reutilizada"),
    "art_cf_mu_bar_3": ("FAIL", "No muestra soporte sobre barra; fase aérea incorrecta", "Regenerar soporte bloqueado, sin sombra"),
    "art_cf_ring_dip_3": ("FAIL", "Mismo contenido binario que el paso _1", "Regenerar fase final distinta del soporte inicial"),
    "art_cf_hang_clean": ("FAIL", "Torso vestido", "Regenerar hero con torso descubierto"),
    "art_cf_hang_clean_1": ("FAIL", "Torso vestido", "Regenerar setup desde hang"),
    "art_cf_hang_clean_2": ("FAIL", "Torso vestido y sombra bajo fase aérea", "Regenerar extensión sin sombra"),
    "art_cf_hang_clean_3": ("FAIL", "Torso vestido", "Regenerar catch en rack frontal"),
    "art_cf_mu_rings_1": ("FAIL", "Sombra de suelo bajo atleta suspendido", "Regenerar hang sin sombra"),
    "art_cf_mu_rings_2": ("FAIL", "Pies al nivel del suelo; transición de MU incoherente", "Regenerar transición aérea"),
    "art_cf_mu_rings_3": ("FAIL", "Óvalo/sombra en soporte sobre anillas", "Regenerar soporte sin sombra"),
    "art_cf_ring_dip_2": ("FAIL", "Camiseta y sombra bajo el atleta suspendido", "Regenerar sin camiseta ni sombra"),
    "art_gy_ring_sup": ("FAIL", "Óvalo de suelo en soporte sobre anillas", "Regenerar hero sin sombra"),
    "art_gy_strict_pu": ("FAIL", "Sombra de suelo en dominada suspendida", "Regenerar hero sin sombra"),
    "art_cf_ghd": ("WARN", "Parece llevar prenda de tirantes", "Verificar torso y regenerar si se confirma"),
    "art_gy_pb_dip_2": ("WARN", "Cambia el ángulo respecto a _1", "Unificar la cámara al regenerar"),
    "art_rdl_2": ("WARN", "Cámara distinta respecto a _1", "Alinear vista lateral o 3/4"),
    "art_cf_wall_ball_3": ("WARN", "Imagen de recepción alta, no de vuelta a sentadilla", "Comprobar encaje del nuevo caption"),
    "art_cf_tgu_3": ("WARN", "Cambia encuadre respecto a los pasos previos", "Alinear perspectiva con _1 y _2"),
}

def swift_dictionary_block(text: str, name: str) -> str:
    match = re.search(
        r"private static let " + re.escape(name) + r":[\s\S]*?\n    \]",
        text,
    )
    if not match:
        raise RuntimeError(f"No se encontró el bloque Swift {name}")
    return match.group(0)

def entries(text: str) -> list[tuple[str, str]]:
    return HERO_RE.findall(swift_dictionary_block(text, "nameMap"))

def instruction_counts(text: str) -> dict[str, int]:
    segment = swift_dictionary_block(text, "spanishInstructions")
    result: dict[str, int] = {}
    for match in re.finditer(r'^\s*"([^"]+)": \[([\s\S]*?)^\s*\],', segment, re.MULTILINE):
        result[match.group(1)] = len(re.findall(r'^\s*"', match.group(2), re.MULTILINE))
    return result

def known_sets(text: str, field: str) -> set[str]:
    match = re.search(r"private static let " + re.escape(field) + r":[\s\S]*?\n    \]", text)
    if not match:
        return set()
    return set(re.findall(r'"([^"]+)"', re.sub(r"//[^\n]*", "", match.group(0))))

def dimensions(path: Path) -> tuple[int, int] | None:
    try:
        with Image.open(path) as im:
            if im.format != "JPEG":
                return None
            im.verify()
        with Image.open(path) as im:
            return im.size
    except (OSError, ValueError):
        return None

def validate_pair(stem: str) -> list[str]:
    errors = []
    for path, size, label in (
        (ART / f"{stem}.jpg", (1024, 1024), "full"),
        (ART / "thumbs" / f"{stem}.jpg", (192, 192), "thumb"),
    ):
        if not path.is_file():
            errors.append(f"{label} no existe")
        else:
            actual = dimensions(path)
            if actual != size:
                errors.append(f"{label} tamaño/formato incorrecto: {actual}; esperado {size}")
    return errors

def numbered_for(base: str, names: set[str]) -> list[str]:
    prefix = re.compile(r"^" + re.escape(base) + r"_(\d+)$")
    hits = []
    for name in names:
        match = prefix.fullmatch(name)
        if match:
            hits.append((int(match.group(1)), name))
    return [stem for _, stem in sorted(hits)]

def contact_sheet(exercise: str, stems: list[str], captions: list[str], out: Path) -> None:
    # 1 hero y 1…N en el mismo informe. No toca ExerciseArt ni exporta assets.
    width = 280
    height = 370
    sheet = Image.new("RGB", (width * len(stems), height), "#151515")
    draw = ImageDraw.Draw(sheet)
    for ix, stem in enumerate(stems):
        with Image.open(ART / f"{stem}.jpg") as im:
            tile = ImageOps.fit(im.convert("RGB"), (256, 256), method=Image.Resampling.LANCZOS)
        sheet.paste(tile, (ix * width + 12, 12))
        draw.text((ix * width + 12, 278), stem, fill="white")
        caption = captions[ix] if ix < len(captions) else ""
        for j, line in enumerate(textwrap.wrap(caption, 37)[:4]):
            draw.text((ix * width + 12, 298 + j * 16), line, fill="#c9c9c9")
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=90)

def run() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report-dir", default="art-audit", help="Carpeta externa a ExerciseArt/")
    parser.add_argument("--contact-sheets", action="store_true")
    parser.add_argument("--strict", action="store_true", help="Devolver error si existe algún FAIL")
    args = parser.parse_args()
    report = ROOT / args.report_dir
    report.mkdir(parents=True, exist_ok=True)

    swift = SWIFT.read_text(encoding="utf-8")
    spanish = CATALOG.read_text(encoding="utf-8")
    mapped = entries(swift)
    counts = instruction_counts(spanish)
    quarantined = known_sets(swift, "quarantinedSequences")
    holds = known_sets(swift, "staticHolds")

    all_full = {f.stem for f in ART.glob("art_*.jpg")}
    all_thumbs = {f.stem for f in (ART / "thumbs").glob("art_*.jpg")}
    reported_stems: set[str] = set()
    rows: list[dict[str, str]] = []

    for exercise, base in mapped:
        numbered = numbered_for(base, all_full)
        for stem in [base, *numbered]:
            reported_stems.add(stem)
            problems = validate_pair(stem)
            if stem in KNOWN_ISSUES:
                judgment, note, action = KNOWN_ISSUES[stem]
            else:
                judgment, note, action = "WARN", "Verificación anatómica/visual pendiente", "Inspeccionar hero y pasos"
            if problems:
                judgment = "FAIL"
                note += "; " + "; ".join(problems)
                action = "Exportar de nuevo usando export_generated_art.py"

            rows.append(dict(ejercicio=exercise, stem=stem, veredicto=judgment,
                             problema=note, accion=action))

        if numbered:
            indices = [int(stem.rsplit("_", 1)[-1]) for stem in numbered]
            if indices != list(range(1, len(indices) + 1)) or len(indices) > 8:
                rows.append(dict(ejercicio=exercise, stem=base, veredicto="FAIL",
                                 problema="Numeración no consecutiva o más de 8 pasos",
                                 accion="Revisar _1…N y ExerciseArt.imageNames"))
        if exercise not in holds and exercise not in quarantined and len(numbered) >= 2:
            if exercise in counts and len(numbered) != counts[exercise]:
                rows.append(dict(ejercicio=exercise, stem=base, veredicto="FAIL",
                                 problema=f"{len(numbered)} imágenes y {counts[exercise]} instrucciones",
                                 accion="Ajustar spanishInstructions a las poses numeradas"))
            if exercise not in counts:
                rows.append(dict(ejercicio=exercise, stem=base, veredicto="WARN",
                                 problema="Instructions vienen de seed; verificar N e idioma",
                                 accion="Comprobar exercise.instructions del catálogo seed"))
        if args.contact_sheets and numbered:
            contact_sheet(exercise, [base, *numbered], [], report / "sheets" / f"{base}.jpg")

    # Incluye posibles recursos olvidados fuera del mapeo.
    for stem in sorted((all_full | all_thumbs) - reported_stems):
        rows.append(dict(ejercicio="SIN MAPEO", stem=stem, veredicto="FAIL",
                         problema="JPG fuera de nameMap o paso huérfano",
                         accion="Añadir referencia válida o eliminar recurso después de revisar"))

    out = report / "exercise-art-audit.csv"
    with out.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["ejercicio", "stem", "veredicto", "problema", "accion"])
        writer.writeheader()
        writer.writerows(rows)

    full_missing_thumbs = sorted(all_full - all_thumbs)
    orphan_thumbs = sorted(all_thumbs - all_full)
    if full_missing_thumbs or orphan_thumbs:
        print("ERROR: full sin thumb", full_missing_thumbs, "thumb sin full", orphan_thumbs)

    issues = [r for r in rows if r["veredicto"] == "FAIL"]
    print(f"Ejercicios mapeados: {len(mapped)}")
    print(f"Full: {len(all_full)}  Thumbs: {len(all_thumbs)}")
    print(f"Filas: {len(rows)}  FAIL conocidos/técnicos: {len(issues)}")
    print(f"CSV: {out}")
    print("WARN no es aprobado: exige inspección visual de cada imagen.")
    return 1 if args.strict and (issues or full_missing_thumbs or orphan_thumbs) else 0

if __name__ == "__main__":
    raise SystemExit(run())
