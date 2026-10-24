#!/usr/bin/env python3
"""Extractor del catálogo semilla iOS (origin/main) → catalog_seed.json Android.
Replica la semántica de Catalog.seed(): familias → displayName → libraryMuscleGroup
→ CatalogSpanish.localize. Preserva ids de entradas existentes."""
import json, re, subprocess, sys, unicodedata, uuid

import os
REPO = os.environ.get('REPERA_REPO', os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
REF = sys.argv[sys.argv.index('--git-ref') + 1] if '--git-ref' in sys.argv else 'origin/main'
BASE = 'Packages/ReperaDomain/Sources/ReperaDomain'

def swift(name):
    return subprocess.run(['git','show',f'{REF}:{BASE}/{name}'], cwd=REPO,
                          capture_output=True, text=True).stdout

def blocks(src, head):
    """Bloques balanceados que empiezan por `head(`."""
    out, i = [], 0
    while True:
        j = src.find(head + '(', i)
        if j < 0: break
        depth, k = 0, j + len(head)
        start = k
        while k < len(src):
            c = src[k]
            if c == '(': depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0: break
            k += 1
        out.append(src[start+1:k])
        i = k
    return out

def parse_args(body):
    """Parsea args: posicional inicial opcional + labeled key: valor."""
    args, i, n = {}, 0, len(body)
    def skip_ws(i):
        while i < n and body[i] in ' \t\n,': i += 1
        return i
    def read_value(i):
        i = skip_ws(i)
        if body[i] == '"':
            j, s = i+1, ''
            while j < n:
                if body[j] == '\\': s += body[j:j+2]; j += 2; continue
                if body[j] == '"': break
                s += body[j]; j += 1
            return s.replace('\\"','"').replace('\\n','\n'), j+1
        if body[i] == '[':
            depth, j = 0, i
            while j < n:
                if body[j] == '[': depth += 1
                elif body[j] == ']':
                    depth -= 1
                    if depth == 0: break
                j += 1
            inner = body[i+1:j]
            items, k = [], 0
            while k < len(inner):
                k2 = k
                while k2 < len(inner) and inner[k2] in ' \t\n,': k2 += 1
                if k2 >= len(inner): break
                if inner[k2] == '"':
                    v, k = read_value_at(inner, k2)
                    items.append(v)
                else:
                    m = re.match(r'[^,\]]+', inner[k2:])
                    k = k2 + (m.end() if m else 0)
            return items, j+1
        m = re.match(r'[A-Za-z0-9_.\-]+', body[i:])
        v = m.group(0) if m else ''
        return (None if v in ('nil', 'null') else v), i + (m.end() if m else 0)
    def read_value_at(s2, i):
        j, s = i+1, ''
        while j < len(s2):
            if s2[j] == '\\': s += s2[j:j+2]; j += 2; continue
            if s2[j] == '"': break
            s += s2[j]; j += 1
        return s.replace('\\"','"').replace('\\n','\n'), j+1
    i = skip_ws(0)
    if i < n and body[i] == '"':
        v, i = read_value_at(body, i)
        args['_name'] = v
    while i < n:
        i = skip_ws(i)
        m = re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*:', body[i:])
        if not m: break
        key = m.group(1)
        i += m.end()
        v, i = read_value(i)
        args[key] = v
    return args

def parse_dict(src, varname):
    """Extrae `let varname: [String: String] = [ ... ]` o [String: [String]]."""
    m = re.search(re.escape(varname) + r'\s*:\s*\[[^=]*\]\s*=\s*\[', src)
    if not m: return {}
    i = m.end() - 1
    depth, j = 0, i
    while j < len(src):
        if src[j] == '[': depth += 1
        elif src[j] == ']':
            depth -= 1
            if depth == 0: break
        j += 1
    inner = src[i+1:j]
    out = {}
    for mm in re.finditer(r'"((?:[^"\\]|\\.)*)"\s*:\s*(\[[^\]]*\]|"(?:[^"\\]|\\.)*")', inner):
        k = mm.group(1).replace('\\"','"')
        v = mm.group(2)
        if v.startswith('"'):
            out[k] = v[1:-1].replace('\\"','"')
        else:
            out[k] = re.findall(r'"((?:[^"\\]|\\.)*)"', v)
    return out

def parse_pairs(src, varname):
    m = re.search(re.escape(varname) + r'\s*:\s*\[\(String,\s*String\)\]\s*=\s*\[', src)
    if not m: return []
    i = m.end() - 1
    depth, j = 0, i
    while j < len(src):
        if src[j] == '[': depth += 1
        elif src[j] == ']':
            depth -= 1
            if depth == 0: break
        j += 1
    inner = src[i+1:j]
    return re.findall(r'\("((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\)', inner)

def parse_list(src, varname):
    m = re.search(re.escape(varname) + r'\s*:\s*\[String\]\s*=\s*\[', src)
    if not m: return []
    i = m.end() - 1
    depth, j = 0, i
    while j < len(src):
        if src[j] == '[': depth += 1
        elif src[j] == ']':
            depth -= 1
            if depth == 0: break
        j += 1
    return re.findall(r'"((?:[^"\\]|\\.)*)"', src[i+1:j])

def fold(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn').lower()

# ---- tablas ----
tax = swift('MuscleTaxonomy.swift')
muscles = set(parse_list(tax, 'muscles'))
display_es = parse_dict(tax, 'displayNameES')
alias_raw = re.search(r'private static let alias:\s*\[String:\s*String\?\]\s*=\s*\[(.*?)\n    \]', tax, re.S)
alias = {}
if alias_raw:
    for mm in re.finditer(r'"([^"]+)":\s*("([^"]*)"|nil)', alias_raw.group(1)):
        if mm.group(3) is not None: alias[mm.group(1)] = mm.group(3)
by_body = set(re.findall(r'"([^"]+)":\s*\[', re.search(r'byBodyPartES[^\[]*\[(.*?)\n    \]', tax, re.S).group(1)))
filter_group = parse_dict(tax, 'filterGroupES')

def canonical(v):
    name = v.strip().lower()
    if name in muscles: return name
    if name in alias: return alias[name]
    for slug, label in display_es.items():
        if label.lower() == name: return slug
    return None

def library_muscle_group(primaries, target):
    for raw in list(primaries) + ([target] if target else []):
        slug = canonical(raw)
        if slug and slug in filter_group: return filter_group[slug]
        if raw in by_body: return raw
    t = (target or '').lower()
    if 'cardio' in t: return 'Cardio'
    return 'Custom'

sen = swift('SportExerciseNames.swift')
legacy_es_en = parse_dict(sen, 'legacySpanishToEnglish')
norm_es_en = {fold(k): v for k, v in legacy_es_en.items()}
def canonical_name(name):
    return legacy_es_en.get(name) or norm_es_en.get(fold(name)) or name
def display_name(name, sport):
    if sport in ('CrossFit', 'Halterofilia'): return canonical_name(name)
    return name
def spanish_alias(name):
    en = norm_es_en.get(fold(name))
    if en: return name
    for k, v in norm_es_en.items():
        if fold(v) == fold(name): return k
    return None

cs = swift('CatalogSpanish.swift')
spanish_by_name = parse_dict(cs, 'spanishByName')
spanish_instructions = parse_dict(cs, 'spanishInstructions')
phrase_pairs = parse_pairs(cs, 'phrasePairs')
def translate_sentence(raw):
    lower = raw.lower()
    if any(w in lower for w in [' el ',' la ',' los ',' las ',' con ',' hacia ','túmbate','mantén','ponte']) or \
       any(lower.startswith(p) for p in ['baja ','empuja ','agarra ','sujeta ','siéntate ']):
        return raw
    s = raw
    for en, es in phrase_pairs:
        s = re.sub(re.escape(en), es, s, flags=re.I)
    return s

# ---- filas por familia ----
rows = []  # (name, muscleGroup, equipment, catalogId, target, secondary, body, desc, instructions, primaries, secondaries, sportTag)
enr = swift('CatalogEnrichment.swift')
for b in blocks(enr, 'EnrichedSeed'):
    a = parse_args(b)
    if 'name' not in a: continue
    rows.append(dict(name=a['name'], group=a.get('muscleGroup','Custom'), equip=a.get('equipment'),
        catalogId=a.get('catalogId'), target=a.get('target'), secondary=a.get('secondaryMuscles') or [],
        body=a.get('bodyPart'), desc=a.get('description'), steps=a.get('instructions') or [],
        prim=a.get('primaries') or [], sec=a.get('secondaries') or [], sport=a.get('sportTag')))

for fname, helper, sport in [('CatalogHalterofilia','h','Halterofilia'),
                             ('CatalogGimnasia','gy','Gimnasia'),
                             ('CatalogCrossFit','cf','CrossFit')]:
    src = swift(fname + '.swift')
    for b in blocks(src, helper):
        a = parse_args(b)
        if '_name' not in a: continue
        prim = a.get('primaries') or []
        target = a.get('target')
        rows.append(dict(name=display_name(a['_name'], sport),
            group=library_muscle_group(prim, target), equip=a.get('equipment'),
            catalogId=None, target=target, secondary=a.get('secondary') or [],
            body=a.get('body'), desc=a.get('description'), steps=a.get('instructions') or [],
            prim=prim, sec=a.get('secondaries') or [], sport=sport))

cat = swift('Catalog.swift')
hyrox = cat[cat.index('enum CatalogHyrox'):]
for b in blocks(hyrox, 'sportRow'):
    a = parse_args(b)
    if '_name' not in a: continue
    prim = a.get('primaries') or []
    target = a.get('target')
    rows.append(dict(name=a['_name'], group=library_muscle_group(prim, target),
        equip=a.get('equipment'), catalogId=None, target=target,
        secondary=a.get('secondary') or [], body=a.get('body'), desc=a.get('description'),
        steps=a.get('instructions') or [], prim=prim, sec=a.get('secondaries') or [], sport='HYROX'))

mov = swift('CatalogMovilidad.swift')
body_by_group = {'Hombros':'shoulders','Espalda':'back','Pecho':'chest','Core':'waist',
                 'Glúteos':'upper legs','Piernas':'upper legs','Isquios':'upper legs',
                 'Gemelos':'lower legs'}
mov_names = {}
for b in blocks(mov, 'move'):
    a = parse_args(b)
    if '_name' not in a or 'key' not in a: continue
    group = a.get('group','Custom')
    desc = a.get('description','')
    desc = desc + ' Ejercicio de movilidad controlada para ' + group.lower() + \
        '. Ajusta la amplitud a tus posibilidades, sin convertir el estiramiento en una competición ni aumentar la carga.'
    target = a.get('target')
    rows.append(dict(name=a['_name'], group=group, equip=a.get('equipment'),
        catalogId='mobility-' + str(a['key']), target=target, secondary=[],
        body=body_by_group.get(group, 'lower arms'), desc=desc, steps=a.get('steps') or [],
        prim=[target] if target else [], sec=[], sport='Movilidad'))
    mov_names[a['_name']] = True

# ---- localización (CatalogSpanish.localize con nombre FINAL) ----
def localize(name, desc, steps):
    legacy = spanish_alias(name) or name
    d = spanish_by_name.get(name) or spanish_by_name.get(legacy)
    s = spanish_instructions.get(name) or spanish_instructions.get(legacy)
    if d is None and desc is not None: d = translate_sentence(desc)
    if s is None: s = [translate_sentence(x) for x in steps]
    return d, s

entries, seen = [], set()
for r in rows:
    name = r['name']
    if name in seen:
        print('DUPLICADO en iOS:', name, file=sys.stderr)
        continue
    seen.add(name)
    d, s = localize(name, r['desc'], r['steps'])
    entries.append(dict(
        name=name, muscleGroup=r['group'], catalogId=r['catalogId'],
        detailDescription=d, equipment=r['equip'], instructions=s,
        isCustom=False, isFavorite=False,
        primaryRegions=r['prim'] if r['prim'] else ([r['target']] if r['target'] else []),
        secondaryMuscles=r['secondary'], secondaryRegions=r['sec'],
        targetMuscle=r['target'], bodyPart=r['body'], sportTag=r['sport']))

print('entradas extraídas:', len(entries))
dest = sys.argv[sys.argv.index('--out') + 1] if '--out' in sys.argv else '/tmp/catalog_ios_full.json'
json.dump(entries, open(dest,'w'), ensure_ascii=False, indent=1)
