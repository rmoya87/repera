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
ART = ROOT / "Apps/Repera/Resources/ExerciseArt"
THUMBS = ART / "thumbs"
SWIFT = ROOT / "Apps/Repera/Sources/ExerciseArt.swift"
SPANISH = ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/CatalogSpanish.swift"
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
    "art_aperturas": ("6f3c577c0897f4c34f131000cad142067fefbece", "FAIL", "Aperturas con lime en abdominales en lugar de músculos pectorales"),
    "art_curl_femoral": ("e1ade6987a022db4d1fd504b61d37f898178743a", "FAIL", "Resaltado rojo no permitido; solo se admite lime"),
    "art_curl_mancuernas": ("677123b052ab024298f49db56a57e3e9b4766b33", "FAIL", "Curl mostrado con manos altas en postura de press de hombros"),
    "art_curl_martillo": ("dd9faefd1f7479fe6f2b5d7ca5cfaf722388ce60", "FAIL", "Curl martillo dibujado en postura de press de hombros"),
    "art_elevaciones_laterales": ("50cd963d911439c404f3fd87d254ee6d67e94473", "FAIL", "Elevación lateral dibujada como press de hombros"),
    "art_fondos": ("8b35bf8a15720d4e6e4d41f334acb42a0ae82f35", "FAIL", "Fondos sustituidos por jalón de tríceps en polea"),
    "art_hip_thrust": ("b4914ad84248ef2778f4d5bc93f6ec109bd2dad7", "FAIL", "Figura tumbada sobre banco como press, barra sobre pecho y no pelvis"),
    "art_jalon": ("f6de48afdde6dcd943f96386cb74232631566e16", "FAIL", "Polea unida a barra olímpica cargada de discos, equipo imposible"),
    "art_pajaros": ("11b7f70867b327977d68cfd031b6c2ebf4a8055e", "FAIL", "Pájaros representados como press con barra y mancuernas simultáneas"),
    "art_plancha": ("9d57e12b747ef995de44c434b1691b748aa285ba", "FAIL", "Plancha representada como apoyo en paralelas con cuerpo suspendido y cara hacia arriba"),
    "art_press_declinado": ("ecbc4eb603f67a3404f7f2f03bb1f646e345c5af", "FAIL", "Press declinado representado sobre banco inclinado hacia arriba"),
    "art_press_frances": ("d1f3625a639b5885ac6ed7ca652c2ebea25b994c", "FAIL", "Barra olímpica y cable de polea mezclados en press francés"),
    "art_remo_erg": ("7a606852ddd7b0cfce8011cb1e9ea6e7d7f35029", "FAIL", "Remo ergómetro mezclado con barra olímpica cargada sobre la cabeza"),
    "art_remo_invertido": ("538ace9da31ac43de9a2213eda68270b75229956", "FAIL", "Remo invertido mostrado como dominada vertical"),
    "art_remo_sentado": ("2d55af3f6d1cab267d0406ade358c03eddc596c1", "FAIL", "Remo sentado mostrado como press de banca con barra suspendida"),
    "art_gemelos": ("af843a7e9eb2795989f69f51c9e24fcae8cdb3b4", "WARN", "Resaltado lime excesivo en espalda/brazos para elevación de gemelos"),
    "art_extension_cuad": ("fe18f1b3fc15ffc1147dc1850416bf3d35d5c903", "WARN", "Resaltado lime alcanza abdomen además de cuádriceps"),
    "art_sentadilla_frontal": ("a639ba2ceefb494a26303c8fa0f75da701f53bb7", "WARN", "Codos demasiado bajos en posición frontal de barra"),
    "art_pullover": ("adbfd39f5e426a5e62e065cf83d5b73401972570", "WARN", "Activación abdominal demasiado dominante en pullover"),
    "art_cf_ctb": ("0509972625ddd9142bac5017fdc60ed35bff6b86", "FAIL", "Chest-to-bar con torso vestido y pies apoyados en vez de suspendidos"),
    "art_cf_hpc": ("0de554c9d4126c336a33fd440ce249d176348112", "FAIL", "Hang power clean mostrado con barra detrás del cuello"),
    "art_cf_hps": ("f153f05438ebea11f2d486163bc720a7cd49b6db", "FAIL", "Hang power snatch con barra tras la cabeza y pies despegados"),
    "art_cf_kb_clean": ("214ef78b99ecc30810170a0f664ee64ecbaa707f", "FAIL", "Clean de kettlebell mostrado con dos manos en balanceo"),
    "art_cf_kte": ("89478483639caacbbff5e483abea54fc310306b3", "FAIL", "Knees-to-elbows en suspensión con óvalo de suelo"),
    "art_cf_ring_dip": ("f34241cb0c65ea00de950a73617d9c1ff5443334", "FAIL", "Fondo en anillas en el aire con óvalo de suelo"),
    "art_cf_push_jerk": ("1ef6e7f55a9740ae2a4f970f72fd44e9d550856c", "FAIL", "Push jerk representado como split jerk con piernas alternadas"),
    "art_cf_sb_os": ("32d73c6a00ec8147baeeae43757618063e4880b0", "FAIL", "Sandbag over shoulder dibujado como saco en hombros sin fase de lanzamiento"),
    "art_cf_sled_pull": ("799b5dbdb529140c32b9004075640217af5f523b", "FAIL", "Sled pull mostrado como empuje de trineo con las manos"),
    "art_cf_su": ("6632c70119f95d9333c9e1417532a2a27f19358a", "FAIL", "Salto a la comba con óvalo/sombra mientras está suspendido"),
    "art_cf_tu": ("f903e93cc8c0002a6ef383a9526fb3b5eae7b5e3", "FAIL", "Triple under con sombra de suelo mientras salta"),
    "art_cf_sumo_hp": ("8dd2e7be106a3115553486f432c6e1f0717297e3", "FAIL", "Sumo deadlift high pull representado como sentadilla overhead"),
    "art_cf_yoke": ("8ef75a4f74060e42662e13d001866a1cf4059c02", "FAIL", "Yoke carry representado con barra de pesas ordinaria sin yoke"),
    "art_cf_broad": ("e0f31e98a6d9d7a0cb0a1aa3e3f40c24dd293718", "WARN", "Broad jump muestra zancada lateral muy abierta en vuelo"),
    "art_cf_skierg": ("0d0a39407f246f112aa20102e8caa1912c49b631", "WARN", "Equipo SkiErg representado con plataforma y rueda de aspecto confuso"),
    "art_gy_arch": ("5fac92f91cdaae907433aaa6bde05d8af69eba39", "FAIL", "Arch hold de suelo sustituido por elevación de piernas colgado"),
    "art_gy_archer": ("00e7f9dd4dbce7455f505a9d9a2df9583c916700", "FAIL", "Archer pull-up con ambos codos flexionados; falta brazo recto"),
    "art_gy_candle": ("36975a1bc5bc07373108c33baee1985fa845fe86", "FAIL", "Candlestick sobre suelo mostrado como parada de manos"),
    "art_gy_front_lev": ("e3cbf97b21a16e243fc587ae16102701e18b5508", "FAIL", "Front lever en suspensión con óvalo de sombra de suelo"),
    "art_gy_ghd_back": ("7a6e3591e78a3ce0b9556965a73d5dc0bd35c459", "FAIL", "Extensión GHD representada con barra de pesas elevada y banco equivocado"),
    "art_gy_pegboard": ("05abe5a360ea0471b70ba2ee7fa03fd582b958ce", "FAIL", "Pegboard mostrado como dominada en barra sin tablero"),
    "art_gy_press_hs": ("33b5ec3bc0f995ac8d748d2b3cad30ccb5aba377", "FAIL", "Press to handstand dibujado con barra olímpica en los pies"),
    "art_gy_ring_sup": ("eb15cd7b75d79faa298d6dc3247154b3ca47d23c", "FAIL", "Soporte en anillas con óvalo de suelo bajo pies suspendidos"),
    "art_gy_strict_ttb": ("abf43083cda78525eb44129d1295c97acf983c2d", "FAIL", "Toes-to-bar en suspensión con óvalo de suelo"),
    "art_gy_vsit": ("f51c7497a5f0dd98609f12a7b17cffb8f9bf47f0", "FAIL", "V-sit sin apoyo de manos, parece V-up sobre suelo"),
    "art_gy_false_grip": ("92fbf0cb4f32b8a950d817dd4731b09e14c06bd6", "WARN", "Anillas doradas en vez de grises canónicos"),
    "art_gy_strict_mubar": ("a1322f3c6806628afd9932e0529ce58a97ae642f", "WARN", "Muscle-up estricto dibujado como dominada con barbilla en barra"),
    "art_gy_skin_cat": ("a85896c6fde4180ba7c0cd2440bdd51b31e12898", "WARN", "Skin-the-cat representado como simple hang sin rotación"),
    "art_gy_hollow_hold": ("3600e179b5260703aeb9df5a959d7be6345451b8", "WARN", "Piernas parecen apoyadas en hollow hold, revisar"),
    "art_gy_jump_lunge": ("8180f5dcdd7a8d6fa575d5819e4c1974267aba67", "WARN", "Revisar sombra y postura de salto en jump lunge"),
    "art_aperturas_1": ("6212edb3fb6133715f2d3e5894235f9b86a62ac2", "FAIL", "Pectorales no iluminados; lime en abdominales durante apertura"),
    "art_aperturas_2": ("256d1687b2bf69cf6b8752c1bb876db03a168a46", "FAIL", "Pectorales no iluminados; lime en abdominales durante apertura"),
    "art_peso_muerto_2": ("7b3a94cb797dab0bf693da967b9a09d410e48995", "FAIL", "Barra y discos discontinuos respecto al paso 1"),
    "art_bulgara_3": ("8cd20006fc462879c840e1933f8f41f586fc071d", "FAIL", "Se invierte la dirección del ejercicio y cambia el lado del banco"),
    "art_zancadas_3": ("1da6f04789a00a9b2e198c3b28e4b88cd037fb63", "WARN", "La cámara se desplaza de tres cuartos a lateral"),
    "art_hip_thrust_1": ("eab838f6b1c16e203b1869ce96044da9ffb9bba2", "FAIL", "El atleta yace en banco en vez de apoyar escápulas; barra sobre pecho"),
    "art_hip_thrust_2": ("84981e75b241f84f4e5066844790aa3a1b760962", "FAIL", "Misma postura incorrecta sobre banco, casi idéntica al frame 1"),
    "art_cf_cargada_1": ("4ae7454a3bae9aa06c5163c89feca73e6059e7d4", "FAIL", "Atleta vestido con camiseta en fase inicial frente a frames sin camiseta"),
    "art_cf_arrancada_2": ("95dd5b300e5afccb8754e70e39d0bdf9098e6d30", "FAIL", "Fase de recepción casi igual al paso 3; falta tirón intermedio"),
    "art_cf_arrancada_3": ("8b46c4ffe4fc5c14a14e9a11c81ac77997606e1b", "FAIL", "Segundo frame en sentadilla overhead prácticamente igual al paso 2"),
    "art_cf_cj_1": ("33cdbc30081538fb7d0c21b54555981a392c0ba4", "FAIL", "Disco/maneral corto en lugar de misma barra olímpica del movimiento"),
    "art_cf_cj_2": ("574d4cd22f693799984078eaa26ada438abd1444", "FAIL", "Back rack de sentadilla con soporte de rack, en vez de front rack de cargada"),
    "art_cf_split_jerk_2": ("9bb509f33ca94f570cb45dd935cdc3f4fa130545", "FAIL", "Fase final split overhead casi idéntica al paso 3"),
    "art_cf_split_jerk_3": ("1e5511e69fc5a38311a97dfabc99fa259ca60c8e", "FAIL", "Repetición de split overhead del paso 2; falta fase diferenciada"),
    "art_cf_ohs_2": ("733c2651388098818cc5a391d19b25f8a9cd9fc2", "FAIL", "Sentadilla overhead profunda casi idéntica a paso 3"),
    "art_cf_ohs_3": ("752a306a76e30649cf968a04ca18632c14b8837e", "FAIL", "Repetición de posición final profunda en lugar de cambio articular claro"),
    "art_cf_cluster_3": ("bdd3d6ef7db9391e3e07e784a97dd73b6fdaf0ff", "FAIL", "Termina con mancuernas tras iniciar y bajar con barra olímpica"),
    "art_cf_ctb_3": ("0509972625ddd9142bac5017fdc60ed35bff6b86", "FAIL", "Chest to bar con piernas apoyadas; no está suspendido"),
    "art_cf_hspu_1": ("be247d7814fa9a14826ca4fed0e755dac9aaca5f", "FAIL", "Bloqueo de handstand duplicado en paso 3, sin pared estable"),
    "art_cf_hspu_3": ("19fb6e4cba17bd90e834749b401e58ab4d8a2390", "FAIL", "Fotograma prácticamente idéntico al paso 1, sin pared estable"),
    "art_cf_ring_dip_1": ("f34241cb0c65ea00de950a73617d9c1ff5443334", "FAIL", "Sombra debajo de anillas en aire y pose duplicada con paso 3"),
    "art_cf_ring_dip_2": ("843e69cb5c9e5a5f491c6e17dffe722f7423f46e", "FAIL", "Óvalo de suelo bajo cuerpo suspendido de anillas"),
    "art_cf_ring_dip_3": ("f34241cb0c65ea00de950a73617d9c1ff5443334", "FAIL", "Sombra debajo de anillas en aire y pose duplicada con paso 1"),
    "art_cf_rope_1": ("5a22519cd40a710189a8976470cd4e21958c29cd", "FAIL", "Sombra/óvalo bajo el escalador suspendido"),
    "art_cf_rope_2": ("a1d323ab86f8ae764dd7505bbcb697101011dafc", "FAIL", "Óvalo de suelo bajo la fase de escalada en aire"),
    "art_cf_kb_snatch_2": ("2a2a5c996327b8881816243131172fb8c494e0cc", "FAIL", "Bloqueo OH casi idéntico al paso 3; falta tirón"),
    "art_cf_kb_snatch_3": ("aa3f05a60b6521709082bd6f02771d7247ad75c3", "FAIL", "Misma postura OH del paso 2, solo cambia el brazo libre"),
    "art_cf_burpee_pu_3": ("628c787f0b0a0c9cf3fc64106647c84bcf4c9dce", "FAIL", "Barra final distinta a la estructura de barra de los pasos anteriores"),
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
