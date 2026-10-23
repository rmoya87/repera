# Paridad Android/Wear — revisión contrastada, 23/10/2026

## Refs comprobadas

- iOS `main`: `b8f45fa50feb44e06bd09d73f37e0e257bc97a09`; 59 commits desde la base común `864650c`.
- Android/Wear antes de integrar: `40a680bc3379b35b1e634c3271ea2d1154d856a1`; 60 commits propios.
- Merge no destructivo: `e43e52b` incorpora la historia de main y conserva el árbol Android y su workflow.
- GitHub Actions Android `39948430912`: compilación phone+wear, tests de dominio y tests en emulador, correctos en el head anterior al merge.
- CI main `39954688280`: fallo **Docs touchpoints** y **ReperaDomain swift test**; build XcodeGen de iOS/watchOS y pruebas UI sí pasan. No confundir build con validación global.

## Cambios recientes Apple que deben gobernar la paridad

| Commits main | Contrato observable de producto | Traducción Android |
|---|---|---|
| `b8f45fa`, `c1f5148`, `85c2614`, `fa1463b` | Mostrar todas las series prescritas aceptadas en entrenamientos finalizados sin logs reales; repercutir en detalle/estadísticas de ejercicio | Resolver registros efectivos **solo para sesiones finalizadas** sin escribir series inventadas en JSON; integrar en Progreso por ejercicio, PR, e1RM y métricas |
| `d217d70`, `d1f62d4`, `83dd2e2` | No ocultar sets registrados porque igualan score WOD; mostrar resultado una sola vez y alinear filas al título | Conservar loggedSets, un único score por bloque y filas compactas |
| `433c621`, `aea2591` | Recuperación sin recargas recurrentes ni parpadeos | Health Connect estable, flujos con cache y actualización diferencial |
| `5773b29`, `510ca2a`, `4eece72`, `1764dd5` | Relojes grandes, pre-cuenta independiente, pausa/reanudación, disposición adaptable | Máquina de estados de timer con tests de reloj monotónico, pre-cuenta y pausa en Compose |
| `52310ee`, `b2b5121`, `3045fb7`, `5058f75` | Paisaje, calendario siete días, márgenes y splash | Compose adaptativo WindowSizeClass, orientación y edge-to-edge según sistema |
| `21e26ff`, `06884b8`, `c3d2f24` | Logout anula recuperación de caché antigua y exige identidad propietaria | Google/Supabase sesión durable con cache ligada al `userId` verificado y sin mezcla de cuentas |
| `df76e24` | Catálogo traducido y técnicas completas de nuevas entradas | Actualizar seed/aliases y descripciones Android desde Swift; preservar identificadores |

## Inventario inspeccionado

`android/mobile` contiene MainActivity, una pantalla Compose de ~1.000 líneas, repositorio local JSON, cronómetro WOD, sincronización Google Drive, Health Connect solo pasos/calorías y puente Data Layer de salida. `android/domain` contiene WODClock, reglas de WOD, conflictos y búsqueda bilingüe. `android/wear` contiene una única Activity y escucha Data Layer: refleja la sesión activa, cache offline solo lectura; sin escritura autónoma, Health Services ni compensación.

## Bloqueos prioritarios (no marcar completos hasta sus pruebas)

**P0 — corrección y seguridad:**
1. Autenticación Google con refresh, logout coherente, propiedad de datos Supabase y E2E real entre móviles; evitar mezcla Google Drive/iCloud.
2. Importación/exportación portable y conflictos bidireccionales de sesiones, rutinas y planes, con reversión y recuperabilidad.
3. Paridad de todos los formatos de WOD, selección y edición por movimiento, RIR/RPE, calentamientos, técnicas especiales y edición de sesión terminada.
4. Verificar CI actual de iOS (dos jobs rojos) y Android tras cada integración; escenarios reales de reloj emparejado.

**P1 — función del atleta:**
5. Progreso: periodos/filtros, e1RM, máximos, frecuencia, PR, equilibrio muscular, zonas y recuperación sin flashes; mismo motor de registros efectivos que historial.
6. Pantallas Inicio, Diario, Crear y Ejercicios equivalentes; navegación/detalles, miniaturas, widgets contextuales, fechas y planificaciones.
7. Wear: sesiones offline de escritura, temporizador/control bidireccional, reconciliación por ID de set, Health Services, pausas, haptics y errores de red.
8. Escaneo de pizarra con ML Kit y parser equivalente al iOS; validación bilingüe.

**P2 — integraciones y distribución:**
9. Conexión MCP, mensajes Realtime, planificaciones IA/profesionales y autorización RLS.
10. Suscripciones Play Billing, restauración, restricciones Gratis/Pro y protección de entitlement.
11. Accesibilidad, TalkBack, Dynamic Color coherente con la marca, tablet/plegable, landscape, rotación; notificaciones, permisos y consumo de batería.
12. Firma, Play Console, pruebas en varios dispositivos, monitorización de fallos y versión de datos/migraciones.

## Criterios de cierre

La paridad no es un porcentaje inventado: requiere matriz por comportamiento y resultado entre iOS 27 y Android 17, pruebas contractuales para cada WOD/unidad/estadística, E2E Google/Supabase/Drive, pruebas con reloj físico y CI verde después de integrar. En la revisión actual **no se afirma equivalencia funcional ni ausencia de bugs**.

### Incremento de esta auditoría

El lector `WorkoutHistorySets` aplica fallback de sets prescritos terminados **solo en memoria**, conserva warmups reales, unidades Cal/metros, RIR y WOD globales sin series falsas. La prueba instrumentada protege estos invariantes. Para estadísticas agregadas faltan portar `StatsEngine.effectiveWorkSets` a un motor transversal Android, no reimplementar reglas diferentes por pantalla.
