#!/usr/bin/env python3
"""Auditoría estructural reproducible de ExerciseArt. No sustituye QA visual humana.

Uso desde la raíz:
  .venv-art/bin/python scripts/audit_exercise_art.py
  .venv-art/bin/python scripts/audit_exercise_art.py --strict

Genera docs/EXERCISE_ART_AUDIT.csv por stem e imprime un resumen.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Apps/Gymbro/Resources/ExerciseArt"
THUMBS = ART / "thumbs"
SWIFT = ROOT / "Apps/Gymbro/Sources/ExerciseArt.swift"
SPANISH = ROOT / "Packages/GymbroDomain/Sources/GymbroDomain/CatalogSpanish.swift"
OUTPUT = ROOT / "docs/EXERCISE_ART_AUDIT.csv"
SEQ_RE = re.compile(r"^(art_.+)_([1-8])$")

# Defectos localizados mediante revisión humana de JPG. Se asocian al blob original:
# cuando se cambie el archivo, pasará a REVISAR en lugar de seguir llamándolo FAIL.
VISUAL_FINDINGS = {
    "art_cf_thruster_3": ("2785fb8b76ef1592198b85d2826a29f9efbeb1b5", "FAIL", "Mancuernas en el bloqueo de un thruster con barra"),
    "art_cf_tgu_1": ("b495ad90d4d32ff5c5eac8a0c51b740826041570", "FAIL", "Mancuerna en vez de la kettlebell de los pasos siguientes"),
    "art_cf_hang_clean_1": ("a3729ec34348e5138db48c15aa233533bab4ceb2", "FAIL", "Torso vestido, contra la referencia canónica"),
    "art_cf_hang_clean_2": ("105d86b22b93a752c7ea0bd6eafd506342af2279", "FAIL", "Torso vestido y sombra de suelo en fase aérea"),
    "art_cf_hang_clean_3": ("c9a687633e9c1eef0e00db0fe373a6ee04424666", "FAIL", "Torso vestido, contra la referencia canónica"),
    "art_cf_mu_rings_1": ("9fd815982fa0c38265f49e60e2d8efae810f622f", "FAIL", "Óvalo bajo el deportista colgado; anillas fuera de paleta"),
    "art_cf_mu_rings_2": ("64a5ce98359e777d76bf46823e4965dbd6f340b7", "FAIL", "Óvalo en suspensión; cambio de ángulo y lateralidad"),
    "art_cf_mu_rings_3": ("4cbd0ca85d8e03541f549a899c9316ae77555ec9", "FAIL", "Óvalo bajo el soporte en anillas; equipo inconsistente"),
    "art_cf_ghd_1": ("08bf0faeab62f0e877a2e5ccd8dcd92310736e04", "FAIL", "Torso vestido y posición del aparato poco clara"),
    "art_cf_ghd_2": ("5b03d783bad35e3f3fb5fcbd4ee0f45f7768e937", "FAIL", "Torso vestido y movimiento poco diferenciado"),
    "art_cf_ghd_3": ("792369a58fdc93100e136e65d5913e49761e0271", "FAIL", "Torso vestido y fase muy similar a la anterior"),
    "art_rdl_1": ("1620d2bab3e5d94fd3d9341c0ce720a7f6783647", "FAIL", "Cámara frontal, incompatible con el frame lateral"),
    "art_rdl_2": ("ad7edd437a5a65d97944ed3a312d886cd23d6228", "FAIL", "Cámara lateral y discos diferentes frente al primer frame"),
    "art_gy_pb_dip_1": ("6fb07a2663d46a5db725af38ad798088ab42bc5d", "WARN", "Cámara y barras no consistentes con el paso 2"),
    "art_gy_pb_dip_2": ("277dddcc0ee16577ca474ba5768053ecb46efb99", "WARN", "Cámara y barras no consistentes con el paso 1"),
    "art_cf_mu_bar_1": ("ac688e87f695f1779819b954ba147cd9ff745252", "WARN", "Cámara posterior frente a cámaras laterales"),
    "art_cf_mu_bar_2": ("ba2323dbdaf69af34d1c3c84dc4a005e4eba013b", "WARN", "La cámara cambia durante la transición"),
    "art_cf_mu_bar_3": ("90951f4b1bdb42950b7ebc186c28805705c55636", "WARN", "Soporte final desde otro ángulo"),
    "art_cf_wall_ball_3": ("530a67d89a230dc1799ab3f9a7a1bcff8d380054", "WARN", "Cambio de plano y balón alto; revisar fase de recepción"),
    "art_cf_hang_clean": ("c9a687633e9c1eef0e00db0fe373a6ee04424666", "FAIL", "Hero con camiseta"),
    "art_cf_ghd": ("792369a58fdc93100e136e65d5913e49761e0271", "FAIL", "Hero con camiseta"),
    "art_cf_mu_rings": ("cdbc24c344d1aae2fc1d911e95378cb6177f0664", "FAIL", "Anillas beige en vez de grises"),
    "art_cf_wall_ball": ("5fb0584f0b017cc5a8729c4928e41cee612814f7", "WARN", "Falta muro y diana en el hero"),
    "art_hl_block_clean": ("81bc461bb4024bf4fb5b81fb27b81435a9ff8272", "FAIL", "El atleta sube a los bloques en lugar de empezar con la barra sobre ellos"),
    "art_hl_block_snatch": ("7b3e322e775b84d4530909e8e591dacabe34a286", "FAIL", "El atleta está sobre los bloques y no representa la salida"),
    "art_hl_clean_pull": ("5eec11a81811ca2199a574f60d50c2adf919e47d", "FAIL", "Barra detrás del cuello en vez de tirón de cargada"),
    "art_hl_snatch_pull": ("fcc6f62f5f8f88289706be1508174827c86380e5", "FAIL", "Barra detrás del cuello en vez de tirón de arrancada"),
    "art_hl_pause_fs": ("e779790f26164bfd93e57f42bb1b040dbfd7b9dd", "FAIL", "Barra sobre la espalda en vez de rack frontal"),
    "art_hl_pause_clean": ("074f4d3e222ec1142e04a1b1f1435dce20963609", "FAIL", "Barra overhead en vez de cargada con pausa"),
    "art_hl_hang_sq_clean": ("c78d6861117dbe689fe3b4800a92f1057cdb4a94", "FAIL", "Barra detrás del cuello en vez de rack frontal"),
    "art_hl_tall_clean": ("c32ad2ab1669669a37bf2fdc23e17926ad0a7018", "FAIL", "Torso vestido"),
    "art_hl_snatch_bal": ("b8d295d153737586ebe67152626e05af120e374f", "WARN", "Cinturón extra distinto del outfit canónico"),
}


def get_mapping() -> dict[str, str]:
    text = SWIFT.read_text(encoding="utf-8")
    match = re.search(r"private static let nameMap:[\s\S]*?\n    \]", text)
    if not match:
        raise RuntimeError("No se ha encontrado nameMap en ExerciseArt.swift")
    return dict(re.findall(r'"([^"]+)": "(art_[^"]+)"', match.group()))


def get_caption_counts() -> dict[str, int]:
    text = SPANISH.read_text(encoding="utf-8")
    match = re.search(r"private static let spanishInstructions:[\s\S]*?\n    \]", text)
    if not match:
        raise RuntimeError("No se encuentra spanishInstructions")
    block = match.group()
    result = {}
    for entry in re.finditer(r'^\s*"([^"]+)": \[([\s\S]*?)^\s*\],', block, re.MULTILINE):
        result[entry.group(1)] = len(re.findall(r'^\s*"', entry.group(2), re.MULTILINE))
    return result


def git_blob_sha(path: Path) -> str:
    content = path.read_bytes()
    prefix = f"blob {len(content)}\0".encode("ascii")
    return hashlib.sha1(prefix + content).hexdigest()


def image_health(path: Path, expected: int) -> list[str]:
    issues: list[str] = []
    try:
        with Image.open(path) as img:
            img.verify()
        with Image.open(path) as img:
            if img.format != "JPEG":
                issues.append("Formato distinto de JPEG")
            if img.size != (expected, expected):
                issues.append(f"Dimensiones {img.size}; deberían ser {expected}x{expected}")
    except Exception as exc:
        issues.append(f"Imagen corrupta: {exc}")
    return issues


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true", help="Retorna código 1 si quedan defectos")
    args = parser.parse_args()
    mapping = get_mapping()
    captions = get_caption_counts()
    by_base = {stem: exercise for exercise, stem in mapping.items()}
    full = sorted(p for p in ART.glob("art_*.jpg") if p.is_file())
    thumbs = {p.stem: p for p in THUMBS.glob("art_*.jpg") if p.is_file()}
    rows: list[dict[str, str]] = []
    errors = 0
    warnings = 0
    frames = {p.stem for p in full}

    for image_path in full:
        stem = image_path.stem
        matched = SEQ_RE.match(stem)
        base = matched.group(1) if matched else stem
        exercise = by_base.get(base, "")
        problems = image_health(image_path, 1024)
        thumb = thumbs.get(stem)
        if thumb is None:
            problems.append("Falta miniatura JPG")
        else:
            problems.extend(image_health(thumb, 192))
        if not exercise:
            problems.append("Stem sin hero mapeado en nameMap")

        if not matched and stem not in by_base:
            problems.append("Hero no referenciado")
        if matched and base not in frames:
            problems.append("Paso sin hero")

        if matched and exercise and matched.group(2) == "1":
            count = 0
            while base + "_" + str(count + 1) in frames:
                count += 1
            actual = captions.get(exercise)
            if count >= 2 and actual is not None and actual != count:
                problems.append(f"Carrusel: {count} frames y {actual} captions")
            if count == 1:
                problems.append("Paso aislado, sin carrusel completo")

        finding = VISUAL_FINDINGS.get(stem)
        status = "PENDING_VISUAL_QA"
        if finding:
            sha, original_status, detail = finding
            if git_blob_sha(image_path) == sha:
                problems.append(detail)
                status = original_status
            else:
                problems.append("Archivo modificado; repetir revisión visual del defecto anterior")
                status = "WARN"

        severe = ("Falta miniatura", "Imagen corrupta", "Dimensiones", "Formato", "Stem sin", "Hero no", "Paso sin", "Carrusel:", "Paso aislado")
        if any(problem.startswith(severe) for problem in problems):
            status = "FAIL"
        if status == "FAIL":
            errors += 1
        elif status == "WARN":
            warnings += 1

        action = {
            "FAIL": "Regenerar o reparar; exportar full + thumb; volver a revisar",
            "WARN": "Revisar las poses y reexportar si es necesario",
            "PENDING_VISUAL_QA": "Verificar persona, torso, equipo, fases, lime y sombra",
        }[status]
        rows.append({
            "exercise": exercise,
            "stem": stem,
            "verdict": status,
            "problem": " | ".join(problems),
            "action": action,
            "full": str(image_path.relative_to(ROOT)),
            "thumb": str(thumb.relative_to(ROOT)) if thumb else "",
        })

    # Miniaturas huérfanas, aun cuando el full no exista.
    full_stems = {p.stem for p in full}
    for stem, thumb in thumbs.items():
        if stem not in full_stems:
            rows.append({
                "exercise": "", "stem": stem, "verdict": "FAIL",
                "problem": "Miniatura sin full", "action": "Restaurar o regenerar full",
                "full": "", "thumb": str(thumb.relative_to(ROOT)),
            })
            errors += 1

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", newline="", encoding="utf-8") as fp:
        writer = csv.DictWriter(fp, fieldnames=["exercise", "stem", "verdict", "problem", "action", "full", "thumb"])
        writer.writeheader()
        writer.writerows(rows)
    own_carousels = sum(
        1 for stem in by_base
        if stem + "_1" in frames and stem + "_2" in frames
    )
    print(f"Exercises: {len(mapping)} | Full: {len(full)} | Thumbs: {len(thumbs)}")
    print(f"Own carousels: {own_carousels} | FAIL stems: {errors} | WARN stems: {warnings}")
    print(f"CSV: {OUTPUT.relative_to(ROOT)}")
    print("NOTA: PENDING_VISUAL_QA no equivale a OK. La inspección anatómica debe ser humana.")
    return int(args.strict and errors > 0)


if __name__ == "__main__":
    raise SystemExit(main())
