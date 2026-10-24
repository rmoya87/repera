#!/usr/bin/env python3
"""Verifica android/mobile/src/main/assets/catalog_seed.json contra la referencia
iOS congelada (catalog_reference_ios.json) y las reglas de identidad:
- 288 entradas, mismo orden y nombres que la referencia iOS.
- Campos de contenido iguales a iOS, salvo Movilidad/Hyrox (contenido de
  mobility_seed.json/hyrox_seed.json ya enviado).
- Ids: los 196 del registry preservados; mobility-*/hyrox-* = UUID v3
  Java nameUUIDFromBytes('repera:catalog:<catalogId>'); nuevas = UUID v5.
Uso: python3 android/tools/check_catalog_parity.py  (offline, sin git)
"""
import json, os, sys, uuid, hashlib

BASE = os.path.dirname(os.path.abspath(__file__))
def java_v3(s):
    b = bytearray(hashlib.md5(s.encode('utf-8')).digest())
    b[6] = (b[6] & 0x0F) | 0x30
    b[8] = (b[8] & 0x3F) | 0x80
    return str(uuid.UUID(bytes=bytes(b)))

ref = json.load(open(os.path.join(BASE, 'catalog_reference_ios.json')))['entries']
registry = json.load(open(os.path.join(BASE, 'catalog_id_registry.json')))['preserved']
seed = json.load(open(os.path.join(BASE, '../mobile/src/main/assets/catalog_seed.json')))
mob = {e['name']: e for e in json.load(open(os.path.join(BASE, '../mobile/src/main/assets/mobility_seed.json')))}
hyrox = {e['name']: e for e in json.load(open(os.path.join(BASE, '../mobile/src/main/assets/hyrox_seed.json')))}
shipped = mob | hyrox

CONTENT = ['muscleGroup','catalogId','detailDescription','equipment','instructions',
           'primaryRegions','secondaryMuscles','secondaryRegions','targetMuscle','bodyPart','sportTag']
errors = []
if len(seed) != 288: errors.append(f'seed tiene {len(seed)} entradas, esperadas 288')
if [e['name'] for e in seed] != [e['name'] for e in ref]:
    errors.append('el orden/nombres del seed no coinciden con la referencia iOS')
ids = [e['id'] for e in seed]
if len(set(ids)) != len(ids): errors.append('ids duplicados en el seed')
for s, r in zip(seed, ref):
    name = r['name']
    if name in shipped:
        src = shipped[name]
        for k in CONTENT:
            if s.get(k) != src.get(k): errors.append(f'{name}: campo {k} difiere de mobility/hyrox_seed')
        if s['id'] != java_v3('repera:catalog:' + src['catalogId']):
            errors.append(f'{name}: id no sigue el esquema v3 de la migración')
    else:
        for k in CONTENT:
            if s.get(k) != r.get(k): errors.append(f'{name}: campo {k} difiere de iOS')
        if name in registry:
            if s['id'] != registry[name]: errors.append(f'{name}: id preservado alterado')
        elif s['id'] != str(uuid.uuid5(uuid.NAMESPACE_URL, 'repera-seed:' + (r.get('catalogId') or name))):
            errors.append(f'{name}: id nuevo no sigue el esquema v5')
missing_reg = set(registry) - {e['name'] for e in seed}
if missing_reg: errors.append(f'{len(missing_reg)} ids del registry sin entrada en el seed')
if errors:
    print('FALLOS DE PARIDAD:'); [print(' -', e) for e in errors]; sys.exit(1)
print(f'Paridad OK: {len(seed)} entradas, {len(registry)} ids preservados, esquemas v3/v5 verificados')
