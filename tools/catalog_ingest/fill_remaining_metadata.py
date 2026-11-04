#!/usr/bin/env python3
"""Fill remaining catalog metadata (aliases, movement_pattern, alternatives). No art."""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/catalog_ingest/out"
ROWS = json.loads(Path("/tmp/catalog_meta_rows.json").read_text())
BY = {r["name"]: r for r in ROWS}
NAMES = set(BY)

# Canonical movement patterns already used remotely.
VALID_PATTERNS = {
    "squat", "hinge", "lunge", "push", "pull", "carry", "core", "olympic",
    "conditioning", "monostructural", "mobility", "step_up",
}


def esc(s: str) -> str:
    return s.replace("'", "''")


def arr(xs: list[str]) -> str:
    return "ARRAY[" + ",".join("'" + esc(x) + "'" for x in xs) + "]::text[]"


# --- 1) OWOD alias map remapped to real catalog names ---
OWOD_ALIAS: dict[str, list[str]] = {
    "Alternating Dumbbell Snatch": ["Alternating Dumbbell Power Snatch", "alt db power snatch"],
    "American Kettlebell Swing": ["American Kettlebell Swing", "swing americano", "american swing"],
    "Press Arnold": ["Arnold Press", "arnold press"],
    "Air bike": ["Assault Bike", "assault bike", "Bike", "bike"],
    "GHD back extension": ["Back Extension", "back extension", "Ghd Hip Extension", "Hip Extension", "hip extension"],
    "Sentadilla": ["Back Squat", "back squat"],
    "Fondos en paralelas": ["Bar Dip", "bar dip", "Strict Dip", "strict dip"],
    "Muscle-up barra": ["Bar Muscle Up", "bar muscle up", "Muscle Up", "muscle up"],
    "Overhead Lunge": ["Barbell Overhead Lunge", "Overhead Walking Lunge", "overhead walking lunge"],
    "Press banca": ["Bench Press", "bench press"],
    "Remo con barra": ["Bent Over Row", "bent over row"],
    "Curl mancuernas": ["Bicep Curl", "bicep curl", "biceps curl"],
    "Box Jump": ["Box Jump", "salto al cajón", "box jump"],
    "Box Step-Up": ["Box Step Up", "box step up", "step-up al cajón", "Step-up al cajón"],
    "Sentadilla búlgara": ["Bulgarian Split Squat", "bulgarian split squat", "Split Squat", "split squat"],
    "Burpee Box Jump": ["Burpee Box Jump", "burpee al cajón", "Burpee al cajón"],
    "Dominadas butterfly": ["Butterfly Pull Up", "butterfly pull-up", "butterfly pull up"],
    "Elevación de gemelos": ["Calf Raise", "calf raise"],
    "Chest to bar": ["Chest To Bar Pull Up", "chest to bar pull up", "CTB"],
    "Dominadas supinas": ["Chin Up", "chin up", "chin-up"],
    "Press cerrado": ["Close Grip Bench Press", "close grip bench"],
    "Peso muerto": ["Deadlift", "deadlift"],
    "HSPU deficit": ["Deficit Handstand Push Up", "deficit HSPU"],
    "Devil press": ["Devils Press", "Devil's Press", "devil's press"],
    "Double-Under": ["Double Under", "double under", "dobles de comba", "Dobles de comba", "DU"],
    "Dumbbell Clean": ["Dumbbell Clean", "clean mancuerna", "Clean mancuerna", "db clean"],
    "Dumbbell Clean and Jerk": ["Dumbbell Clean And Jerk", "cargada y envión con mancuerna", "Cargada y envión con mancuerna"],
    "Dumbbell Front Squat": ["Dumbbell Front Rack Squat", "db front rack squat"],
    "Goblet squat": ["Dumbbell Goblet Squat", "db goblet squat"],
    "Remo mancuerna": ["Dumbbell Row", "dumbbell row", "db row"],
    "Dumbbell Snatch": ["Dumbbell Snatch", "snatch mancuerna", "Snatch mancuerna", "db snatch"],
    "Dumbbell Thruster": ["Dumbbell Thruster", "thruster mancuernas", "Thruster mancuernas", "db thruster"],
    "Farmer carry": ["Farmers Carry", "farmer's carry", "farmers carry", "paseo del granjero"],
    "HSPU libre": ["Freestanding Handstand Push Up", "freestanding HSPU"],
    "Elevaciones frontales": ["Front Raise", "front raise"],
    "Sentadilla frontal": ["Front Squat", "front squat"],
    "Buenos días": ["Good Morning", "good morning"],
    "Curl martillo": ["Hammer Curl", "hammer curl"],
    "Handstand hold": ["Handstand", "handstand"],
    "HSPU": ["Handstand Push Up", "handstand push-up", "Strict Handstand Push Up", "Wall Facing Handstand Push Up"],
    "Run": ["High Knees", "high knees", "Run Backward", "run backward", "Sprint", "sprint", "Stair Climb", "stair climb", "carrera", "Carrera"],
    "Press banca inclinada": ["Incline Bench Press", "incline bench"],
    "Push jerk": ["Jerk", "jerk"],
    "Kettlebell Clean": ["Kettlebell Clean", "clean kettlebell", "Clean kettlebell"],
    "Kettlebell Snatch": ["Kettlebell Snatch", "snatch kettlebell", "Snatch kettlebell"],
    "Kettlebell Swing": ["Kettlebell Swing", "Russian Kettlebell Swing", "russian kettlebell swing", "swing kettlebell", "Swing kettlebell"],
    "Kettlebell Thruster": ["Kettlebell Thruster", "thruster kettlebell", "Thruster kettlebell"],
    "Dominadas kipping": ["Kipping Pull Up", "kipping pull-up"],
    "Jalón al pecho": ["Lat Pulldown", "lat pulldown"],
    "Elevaciones laterales": ["Lateral Raise", "lateral raise"],
    "Rope climb legless": ["Legless Rope Climb", "legless rope climb"],
    "Medball clean": ["Medicine Ball Clean", "med ball clean"],
    "Pistol squat": ["Pistol", "pistol"],
    "Plancha": ["Plank", "plank"],
    "Pullover": ["Pull Over", "pull over", "pullover"],
    "Dominadas": ["Pull Up", "pull up", "pull-up"],
    "Zancadas": ["Reverse Lunge", "reverse lunge"],
    "Fondos en anillas": ["Ring Dip", "ring dip"],
    "Muscle-up anillas": ["Ring Muscle Up", "ring muscle-up"],
    "Remo en anillas": ["Ring Row", "ring row"],
    "Peso muerto rumano": ["Romanian Deadlift", "RDL", "rdl"],
    "Remo máquina": ["Row", "row", "rower"],
    "Remo sentado": ["Seated Row", "seated row"],
    "Push press": ["Shoulder To Overhead", "shoulder to overhead", "STO"],
    "Shuttle run": ["Shuttle Sprint", "shuttle sprint"],
    "Single-Under": ["Single Under", "single under", "simples de comba", "Simples de comba"],
    "SkiErg": ["Ski Erg", "ski erg", "skie rg"],
    "Press francés": ["Skull Crusher", "skull crusher"],
    "Clean": ["Squat Clean", "squat clean"],
    "Jumping squat": ["Squat Jump", "squat jump"],
    "Snatch": ["Squat Snatch", "squat snatch"],
    "Muscle-up estricto barra": ["Strict Muscle Up", "strict muscle-up"],
    "Dominadas estrictas": ["Strict Pull Up", "strict pull-up"],
    "Peso muerto sumo": ["Sumo Deadlift", "sumo deadlift"],
    "Sumo high pull": ["Sumo Deadlift High Pull", "SDHP"],
    "Toes to rings": ["Toes To Ring", "toes to ring"],
    "Extensión tríceps polea": ["Tricep Extension", "tricep extension", "triceps extension"],
    "Triple-Under": ["Triple Under", "triple under", "triples de comba", "Triples de comba"],
    "Wall ball": ["Wall Ball Shot", "wall ball shot"],
    "Dominadas lastradas": ["Weighted Pull Up", "weighted pull-up"],
}

# --- 2) Aliases for the 40 without any ---
NO_ALIAS_FILL: dict[str, list[str]] = {
    "Aperturas": ["flyes", "dumbbell fly", "aperturas mancuernas", "chest fly"],
    "Arch hold": ["arch hold", "superman hold", "arch body hold"],
    "Archer pull-up": ["archer pull up", "archer pullup", "dominada arquero"],
    "Back lever tuck": ["tuck back lever", "back lever en tuck"],
    "Bici estática": ["stationary bike", "exercise bike", "bici indoor", "bike erg static"],
    "Candlestick": ["candlestick stretch", "candlestick mobility"],
    "Cinta / carrera": ["treadmill", "cinta de correr", "treadmill run"],
    "Cruce de poleas": ["cable crossover", "cable cross over", "crossover polea"],
    "Crunch": ["abdominal crunch", "crunches", "crunch abdominal"],
    "Curl barra": ["barbell curl", "curl con barra", "BB curl"],
    "Curl femoral": ["leg curl", "hamstring curl", "curl de femoral"],
    "Dominadas en anillas": ["ring pull up", "ring pull-up", "pull up rings"],
    "Elevación de piernas": ["leg raise", "lying leg raise", "elevaciones de piernas"],
    "False grip hang": ["false grip hang", "cuelgue false grip"],
    "Farmer walk": ["farmer walk", "farmers walk", "farmer's walk"],
    "Fondos": ["dips", "dip", "fondos paralelas genérico"],
    "Fondos en anillas kipping": ["kipping ring dip", "ring dip kipping"],
    "Fondos en banco": ["bench dip", "bench dips", "fondos banco"],
    "Front lever tuck": ["tuck front lever", "front lever en tuck"],
    "German hang": ["german hang", "skin the cat hang"],
    "Hack squat": ["hack squat", "hack squats", "sentadilla hack"],
    "Hip to bar": ["hip to bar", "HTB", "hips to bar"],
    "Kip swing": ["kip swing", "kipping swing", "balanceo kip"],
    "Muscle-up estricto anillas": ["strict ring muscle up", "strict ring MU"],
    "Pájaros": ["reverse fly", "rear delt fly", "pajaritos"],
    "Paso lateral con banda": ["lateral band walk", "monster walk", "band side step"],
    "Planche tuck": ["tuck planche", "planche en tuck"],
    "Prensa": ["leg press", "prensa de piernas", "machine leg press"],
    "Press banca declinado": ["decline bench press", "press declinado"],
    "Press mancuernas": ["dumbbell press", "db press", "press con mancuernas"],
    "Press militar": ["military press", "overhead press", "OHP", "press de hombros barra"],
    "Press to handstand": ["press to handstand", "press handstand", "press a pino"],
    "Pull-over barra": ["barbell pullover", "pull over barra", "pullover barra"],
    "Remo al mentón": ["upright row", "remo mentón", "remo vertical"],
    "Remo invertido": ["inverted row", "australian pull up", "remo australiano"],
    "Skin the cat": ["skin the cat", "skin the cats"],
    "Soporte en anillas": ["ring support", "support hold rings", "soporte anillas"],
    "Toes to bar estrictos": ["strict toes to bar", "strict T2B", "T2B estrictos"],
    "V-sit": ["v sit", "v-sit hold", "ve sit"],
    "Wall walk": ["wall walk", "wall walks", "caminata por pared"],
}


def infer_pattern(name: str, sport: str | None, existing: str | None) -> str:
    if existing and existing.strip():
        return existing.strip()
    n = name.lower()
    # mobility already tagged remotely mostly
    if sport == "Movilidad":
        return "mobility"
    rules = [
        (("snatch", "clean", "jerk", "thruster", "cluster", "ground to overhead", "medball clean", "wall ball"), "olympic"),
        (("deadlift", "rdl", "romanian", "good morning", "swing", "hip thrust", "nordic", "ghd", "jefferson", "stiff leg"), "hinge"),
        (("squat", "prensa", "hack", "wall sit", "goblet"), "squat"),
        (("lunge", "zancad", "split squat", "búlgara", "step-up", "step up", "step over"), "lunge"),
        (("press", "push up", "push-up", "dip", "fondo", "hspu", "bench", "floor press", "pec deck", "apertura", "fly", "pajar"), "push"),
        (("pull", "dominad", "row", "remo", "jalón", "pulldown", "muscle-up", "muscle up", "chin", "face pull", "pullover"), "pull"),
        (("carry", "farmer", "walk", "yoke", "husafell", "sandbag carry", "waiter"), "carry"),
        (("plank", "plancha", "crunch", "sit-up", "sit up", "toes to", "knee raise", "dead bug", "bird dog", "pallof", "woodchop", "russian twist", "v-sit", "hollow", "ab wheel", "leg raise"), "core"),
        (("run", "carrera", "bike", "bici", "ski", "rowerg", "echo", "air bike", "cinta", "shuttle", "jumping jack", "double-under", "single-under", "triple-under", "comba"), "monostructural"),
        (("burpee", "battle rope", "sled", "sledge", "box jump", "broad jump", "mountain climber", "skater", "tuck jump"), "conditioning"),
        (("lever", "planche", "handstand hold", "hang", "skin the cat", "candlestick", "german hang", "false grip", "arch hold", "wall walk", "press to handstand"), "conditioning"),
        (("curl", "extensión", "elevación de gemelos", "abduc", "aduc", "halo"), "push" if "press" in n or "elev" in n else "hinge" if "femoral" in n or "curl femoral" in n else "core"),
    ]
    for keys, pat in rules:
        if any(k in n for k in keys):
            # refine curls
            if "curl" in n and "femoral" not in n and "nordic" not in n and "hamstring" not in n:
                return "pull"  # biceps curl
            if "curl femoral" in n or "leg curl" in n:
                return "hinge"
            if "elevaciones laterales" in n or "elevaciones frontales" in n or "elevación de gemelos" in n:
                return "push" if "gemelos" not in n else "squat"
            if "abduc" in n or "aduc" in n:
                return "squat"
            if "woodchop" in n or "pallof" in n:
                return "core"
            return pat
    # bodypart hints from seed later — default conditioning for odd CF, push for gym leftovers
    if sport in ("CrossFit", "Gimnasia", "Halterofilia"):
        return "conditioning"
    return "push"


def build_families() -> dict[str, list[str]]:
    """Group exercises for alternatives: same movement_pattern + keyword family."""
    fam_keys = [
        ("squat", ["squat", "sentadilla", "goblet", "prensa", "hack", "wall sit"]),
        ("deadlift", ["deadlift", "peso muerto", "rdl", "trap bar", "axle dead", "zercher dead"]),
        ("bench", ["press banca", "bench press", "floor press", "dumbbell bench", "pec deck", "aperturas"]),
        ("ohp", ["press militar", "push press", "push jerk", "strict press", "z press", "arnold", "shoulder press", "bradford"]),
        ("row", ["remo", "row", "pendlay", "t-bar", "face pull"]),
        ("pullup", ["dominad", "pull-up", "pull up", "chin", "muscle-up", "muscle up", "jalón"]),
        ("dip", ["fondo", "dip"]),
        ("lunge", ["lunge", "zancad", "búlgara", "split squat", "step-up", "step up"]),
        ("carry", ["carry", "farmer", "walk", "waiter", "suitcase", "zercher carry"]),
        ("burpee", ["burpee"]),
        ("bike", ["bike", "bici", "air bike", "echo"]),
        ("run", ["run", "carrera", "cinta", "shuttle"]),
        ("swing", ["swing"]),
        ("thruster", ["thruster", "cluster"]),
        ("clean", ["clean", "cargada"]),
        ("snatch", ["snatch", "arrancada"]),
        ("hspu", ["hspu", "handstand push"]),
        ("core_ab", ["crunch", "sit-up", "sit up", "toes to", "knee raise", "v-sit", "hollow", "ab mat", "ab wheel", "plancha", "plank", "pallof", "woodchop"]),
        ("curl_bi", ["curl barra", "curl mancuernas", "curl martillo", "curl predicador", "curl inclinado"]),
        ("curl_ham", ["curl femoral", "nordic", "ring hamstring"]),
        ("kb", ["kettlebell"]),
        ("db", ["dumbbell", "mancuern"]),
        ("gymn_hold", ["lever", "planche", "hang", "skin the cat", "german hang", "false grip", "arch hold", "candlestick"]),
        ("rope", ["comba", "double-under", "single-under", "triple-under", "crossover"]),
        ("sled", ["sled", "sledge", "trineo"]),
        ("sandbag", ["sandbag", "d-ball", "atlas", "keg", "log", "husafell", "jerry"]),
    ]
    buckets: dict[str, list[str]] = defaultdict(list)
    for name in NAMES:
        nl = name.lower()
        for key, tokens in fam_keys:
            if any(t in nl for t in tokens):
                buckets[key].append(name)
    # also pattern-only soft groups for leftovers
    by_pat: dict[str, list[str]] = defaultdict(list)
    for r in ROWS:
        pat = (r.get("movement_pattern") or "").strip() or infer_pattern(r["name"], None, None)
        by_pat[pat].append(r["name"])
    return {**buckets, **{f"pat:{k}": v for k, v in by_pat.items()}}


def alternatives_for(name: str, families: dict[str, list[str]], pattern: str) -> list[str]:
    cands: list[str] = []
    nl = name.lower()
    for key, members in families.items():
        if name in members:
            for m in members:
                if m != name and m not in cands:
                    cands.append(m)
    # ensure same-pattern peers if still sparse
    if len(cands) < 3:
        for r in ROWS:
            p = (r.get("movement_pattern") or "").strip() or infer_pattern(r["name"], None, None)
            if p == pattern and r["name"] != name and r["name"] not in cands:
                # prefer shared token
                other = r["name"].lower()
                shared = set(re.findall(r"[a-záéíóúñ]+", nl)) & set(re.findall(r"[a-záéíóúñ]+", other))
                shared -= {"de", "en", "con", "al", "la", "el", "and", "the", "to"}
                if shared or len(cands) < 6:
                    cands.append(r["name"])
            if len(cands) >= 8:
                break
    # cap
    return cands[:8]


def main() -> None:
    families = build_families()
    alias_updates: dict[str, list[str]] = defaultdict(list)
    pattern_updates: dict[str, str] = {}
    alt_updates: dict[str, list[str]] = {}

    # OWOD + no-alias fills
    for target, aliases in {**OWOD_ALIAS, **NO_ALIAS_FILL}.items():
        if target not in NAMES:
            print("SKIP missing target", target)
            continue
        existing = [a for a in (BY[target].get("aliases") or [])]
        have = {a.lower() for a in existing}
        add = []
        for a in aliases:
            if a.lower() not in have and a != target:
                add.append(a)
                have.add(a.lower())
        if add:
            alias_updates[target] = existing + add

    # movement patterns
    seed = {e["name"]: e for e in json.loads((ROOT / "android/mobile/src/main/assets/catalog_seed.json").read_text())}
    for r in ROWS:
        name = r["name"]
        cur = (r.get("movement_pattern") or "").strip()
        sport = (seed.get(name) or {}).get("sportTag")
        if not cur:
            pat = infer_pattern(name, sport, None)
            if pat not in VALID_PATTERNS:
                pat = "conditioning"
            pattern_updates[name] = pat
        else:
            # keep existing for alt inference
            pass

    # alternatives for everyone with <2 alts
    for r in ROWS:
        name = r["name"]
        cur_alts = r.get("alternatives") or []
        pat = (r.get("movement_pattern") or "").strip() or pattern_updates.get(name) or infer_pattern(name, None, None)
        # temporarily pretend pattern applied for family building
        if len(cur_alts) < 2:
            alts = alternatives_for(name, families, pat)
            # filter to existing names only
            alts = [a for a in alts if a in NAMES and a != name][:8]
            if alts:
                # merge unique with existing
                merged = list(dict.fromkeys(cur_alts + alts))[:8]
                if merged != cur_alts:
                    alt_updates[name] = merged

    report = {
        "alias_targets": len(alias_updates),
        "alias_new_values": sum(len(v) - len(BY[k].get("aliases") or []) for k, v in alias_updates.items()),
        "patterns": len(pattern_updates),
        "alternatives": len(alt_updates),
    }
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "fill_remaining_report.json").write_text(json.dumps(report, indent=2) + "\n")
    (OUT / "fill_remaining_payload.json").write_text(
        json.dumps(
            {
                "aliases": alias_updates,
                "patterns": pattern_updates,
                "alternatives": alt_updates,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n"
    )
    print(json.dumps(report))

    # Emit SQL
    lines = [
        "-- Fill remaining metadata: aliases, movement_pattern, alternatives (no art).",
        "-- 2026-11-04",
        "",
    ]
    for name, aliases in sorted(alias_updates.items()):
        lines.append(
            f"""UPDATE public.training_exercise_metadata m
SET aliases = {arr(aliases)},
    metadata_source = COALESCE(metadata_source,'') || '+fill_aliases_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = '{esc(name)}' AND c.is_active;
"""
        )
    for name, pat in sorted(pattern_updates.items()):
        lines.append(
            f"""UPDATE public.training_exercise_metadata m
SET movement_pattern = '{esc(pat)}',
    metadata_source = COALESCE(metadata_source,'') || '+fill_pattern_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = '{esc(name)}' AND c.is_active
  AND COALESCE(NULLIF(btrim(m.movement_pattern),''), '') = '';
"""
        )
    for name, alts in sorted(alt_updates.items()):
        lines.append(
            f"""UPDATE public.training_exercise_metadata m
SET alternatives = {arr(alts)},
    metadata_source = COALESCE(metadata_source,'') || '+fill_alts_20261104',
    updated_at = now()
FROM public.business_exercise_catalog c
WHERE m.catalog_key = c.catalog_key AND c.name = '{esc(name)}' AND c.is_active;
"""
        )

    mig = ROOT / "supabase/migrations/20261104240000_fill_remaining_catalog_metadata.sql"
    mig.write_text("\n".join(lines) + "\n")
    print("wrote", mig, "bytes", mig.stat().st_size)


if __name__ == "__main__":
    main()
