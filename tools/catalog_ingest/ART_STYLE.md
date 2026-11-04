# Contrato de estilo — ExerciseArt Repera

Última actualización: 2026-11-04.

Cualquier ejercicio nuevo o regenerado del catálogo maestro **debe** usar este estilo. Prohibido embeber o redistribuir fotografías/GIF de Free Exercise DB, Gym Visual, ExRx, RepDB u otras bibliotecas, aunque el JSON de la fuente sea abierto.

## Canon visual

1. **Referencia maestra:** `Apps/Repera/Resources/ExerciseArt/art_ab_wheel.jpg`.
2. **Prompt completo:** sección «PROMPT MAESTRO» en [`docs/EXERCISE_ART_REGEN_PROMPTS.md`](../../docs/EXERCISE_ART_REGEN_PROMPTS.md).
3. **Sujeto único:** adulto atlético masculino, silueta/anatomía plana, cara sin rasgos, pelo charcoal corto, **torso descubierto siempre**, shorts charcoal, zapatillas grises.
4. **Fondo:** negro mate (~`#101314`), sin gimnasio, sin texto, sin logos.
5. **Highlight:** lima neón solo como relleno plano en músculos activos de esa fase.
6. **Equipo:** gris, constante en hero + frames `_1…N` (misma barra/discos/KB).
7. **Sombra:** óvalo suave solo con apoyo; **sin** sombra de suelo en suspensión/salto.
8. **Export:** full 1024×1024 + thumb 192×192 con `scripts/export_generated_art.py`.
9. **Wire en app:** añadir stem a `ExerciseArt.nameMap` (iOS) y mapa Android equivalente; no reutilizar héroe por grupo muscular.

## Flujo al añadir un movimiento nuevo

1. Publicar ficha editorial en Supabase (texto/aliases) → aparece en apps sin arte.
2. Generar hero (+ carrusel si aplica) con el prompt maestro + referencias hermanas.
3. Exportar, pasar `scripts/audit_exercise_art.py`, QA visual, mapear stem.
4. Desplegar app (el arte **sí** requiere binario; el texto no).
