# Auditoría + corrección parcial de ilustraciones Gymbro

Última actualización: 2026-10-17  
Repositorio: `rmoya87/gymbro` · Referencia: `art_ab_wheel.jpg`

## Alcance comprobado

- `188` asignaciones de hero exactas en `nameMap` y `188` archivos hero presentes.
- `291` JPG full y `291` miniaturas emparejadas por stem en el árbol de GitHub.
- `38` secuencias `_1…N` presentes (`11` de dos fotogramas y `27` de tres).
- `0` pasos huérfanos por naming y `0` héroes mapeados ausentes.
- El inventario GitHub solo prueba existencia; resolución y JPEG válido se comprobarán **ejecutando** el auditor de Pillow en una copia local.

## Estado visual (JPG originales examinados)

El fichero `docs/EXERCISE_ART_AUDIT.csv` incluye **los 291 stems** y su estado. No se han dado por OK los 272 stems que aún carecen de una validación visual individual documentada.

| Ejercicio | Stem afectado | Dictamen | Problema | Acción necesaria |
| --- | --- | --- | --- | --- |
| Thruster | `art_cf_thruster_3` | FAIL | Mancuernas en lugar de barra | Regenerar fase OH con la misma barra/discos y figura del paso 1 |
| Turkish get-up | `art_cf_tgu_1` | FAIL | Mancuerna en vez de la KB del resto | Regenerar tumbado con la KB del resto de frames |
| Hang clean | `art_cf_hang_clean_1…3` | FAIL | Camiseta en el atleta; sombra durante tirón aéreo | Regenerar los tres con torso descubierto y sombra adecuada |
| Muscle-up anillas | `art_cf_mu_rings_1…3` | FAIL | Sombra de suelo en suspensión, anillas desiguales | Regenerar tres fases sin suelo ni óvalo |
| GHD sit-up | `art_cf_ghd_1…3` | FAIL | Torso vestido; fases poco diferenciadas | Regenerar sobre GHD real con inicio, mitad y máxima incorporación |
| Peso muerto rumano | `art_rdl_1…2` | FAIL | Cambia cámara/barra entre frames | Regenerar ambos con misma barra, discos y vista lateral |
| Fondos en paralelas | `art_gy_pb_dip_1…2` | WARN | Cambia cámara y estructura del soporte | Regenerar y estabilizar el encuadre |
| Muscle-up barra | `art_cf_mu_bar_1…3` | WARN | La cámara cambia entre suspensión, transición y soporte | Regenerar desde un único ángulo, sin suelo |
| Wall ball | `art_cf_wall_ball_3` | WARN | Recepción inconsistente y cambio de plano | Revisar tercer frame y diana |
| Box jump over | `art_cf_bjo_1…3` | Sin incidencia evidente en inspección de esta secuencia | Salto sin sombra de suelo, aterrizaje al otro lado | Pendiente de verificación comparativa con hero y escala |

**Total del CSV:** 13 stems FAIL, 6 WARN, 272 PENDING_VISUAL_QA. Un stem WARN no equivale a un ejercicio aprobado.

## Correcciones implementadas y pendientes

- `ExerciseArt.swift`: no reutiliza un hero por músculo cuando un ejercicio no está en `nameMap`.
- `ExerciseArt.swift`: se bloquean nueve carruseles con fallos documentados; se conserva el hero como salida segura.
- `ExerciseArt.swift`: se conserva el diccionario candidato `movementFrames`, pero se exige aprobación visual explícita antes de activar cada reutilización. Ningún candidato está aprobado en esta revisión.
- `ExerciseArt.swift`: estáticos siempre en hero y fallback a hero si faltan captions.
- `CatalogSpanish.swift`: se retiraron 233 anotaciones internas `(imagen: …)` y se revisaron ocho bloques de pasos: `Peso muerto rumano`, `Fondos en paralelas`, `Thruster`, `Turkish get-up`, `Wall ball`, `Muscle-up barra`, `Muscle-up anillas`, `GHD sit-up`.
- `ExerciseArtCaptionTests.swift`: asegura el número de frases para los 38 carruseles propios.
- `scripts/audit_exercise_art.py`: valida full 1024, thumb 192, integridad JPEG, naming y N↔N de instrucciones.

**Imágenes JPG regeneradas/exportadas en esta revisión: ninguna.** No se ha tenido acceso al directorio local `/Users/ramon/Proyectos/gymbro` ni a fuentes coherentes de cada fase que puedan exportarse y subirse de forma verificable. Por tanto, no se afirma que los defectos visuales estén subsanados: quedan en cuarentena para no enseñar instrucciones falsas.

## Procedimiento de cierre visual, por stem

1. Abrir `art_ab_wheel.jpg`, el hero y los frames originales para conservar estética, persona, plano, agarre y equipamiento.
2. Regenerar únicamente los FAIL/WARN con la plantilla de generación aprobada, diferenciando biomecánicamente cada fase.
3. Desde la raíz, exportar cada fuente generada:

   ```bash
   .venv-art/bin/python scripts/export_generated_art.py /ruta/corregido.jpg art_cf_thruster_3
   ```

4. Confirmar imagen 1024 y thumb 192, inspeccionar apoyo/suspensión y músculos activos; repetir todos los frames si no es posible igualar personaje y cámara.
5. Ejecutar:

   ```bash
   .venv-art/bin/python scripts/audit_exercise_art.py
   swift test --package-path Packages/GymbroDomain
   ```

6. Retirar la entrada de `quarantinedSequences` únicamente cuando la secuencia haya sido reexportada, revisada y sus captions correspondan 1:1. Añadir a `verifiedMovementFrameExercises` solo una reutilización hero que haya pasado estas comprobaciones.

## Reglas de cierre

No etiquetar como corregido un JPG que aún sea temporal en `~/.cursor/projects/…/assets/`. No prometer consistencia total de persona, torso descubierto, equipo ni sombra hasta revisar **cada imagen** y haber exportado los binarios correctos al directorio de la app.
