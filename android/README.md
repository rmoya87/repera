# Repera Android y Wear OS (trabajo en curso)

**Última actualización:** 2026-10-29 — Revisión 5: subtítulos sin `null`/duplicados; ▶ abre Play; fin sin pantalla blanca; Play Resultado del bloque + series; AMRAP → reloj; Photon 12 s + pin; shell sin repera/gear; Progreso Entreno/Actividad/Recuperación; preview/detalle página; músculos ES; Comenzar 3D/dark + sheets; timer Arriba; formatos iOS; series SERIE/ANTERIOR; resumen tiempo pared + pin elegido; tab bar en Crear/Ajustes/ejercicio.

Implementación nativa independiente en `android/`:

- `mobile`: Kotlin + Jetpack Compose / Material 3 (`ReperaTheme` + `reperaColorScheme`, sin púrpura M3 por defecto), Credential Manager Google,
  Google Drive appDataFolder, historial local, importación/exportación JSON y ejecución de
  rutinas de fuerza y WOD global o por movimiento, temporizador libre con guardado en historial
  (`timerDetails`), programación por fecha/semana y persistencia compatible con `AppState` Swift.
- `domain`: reloj, `WeightUnit`, `TimerCompletionDetails`, WOD, CSV Hevy/Strong (incl. libras),
  resolución de conflictos.
- `wear`: Compose for Wear OS Material 3 con paridad Watch (ready/outline/running/blockReview/
  resumen W-01 sin bug de duración, Tile + complicaciones); Data Layer + cola offline;
  Health Services E2E físico pendiente.
- `Health Connect`: lectura voluntaria de pasos y calorías activas reales, sin datos inventados ni escrituras.

Google reemplaza a Apple en Android; Google Drive reemplaza a iCloud para
el almacenamiento privado. Para dar acceso profesional a Supabase se requiere
un proveedor Google y autenticación verificada en backend; nunca basta con el
identificador de cuenta obtenido en el teléfono.

## Catálogo Supabase dinámico y sincronización invisible (25/10/2026)

`RemoteExerciseCatalogWorker.kt` usa **WorkManager** nativo con restricciones de
conectividad y comprobación periódica oportunista (6 h, nunca exacta). Consume la
misma tabla editorial `mobile_exercise_catalog_events` de Supabase que iOS:
consulta solo la última revisión, después páginas de 150 eventos nuevas,
persistidas atómicamente en una caché pública independiente del historial.
El token de acceso se lee del `SessionStore` cifrado con Android Keystore;
si está próximo a caducar el trabajador no intenta abrir la UI ni refrescar
credenciales sin permiso: la autenticación del móvil se restaurará al abrir.

La aplicación aplica silenciosamente la caché tras el seed local y antes de
construir la pantalla. En primer plano comprueba la versión con corutinas en
`Dispatchers.IO`, actualiza solo tras una descarga completa y vuelve a cargar
la pantalla únicamente si hay cambios efectivos. Nunca crea sesiones ficticias
ni modifica entrenos o rutinas existentes; mantiene los UUID, favoritos y
campos personalizados. Los nuevos ejercicios usan UUID determinista calculado
con la misma clave que iOS. Una baja editorial marca
`isCatalogArchived=true`: los ejercicios desaparecen del selector público
pero sus datos permanecen para el historial. El seed empaquetado no puede
sobrescribir una corrección remota previamente publicada. La resolución de
identidad bilingüe usa `SportExerciseNames.canonicalName`: se han comparado las
288 fichas de Android contra las 288 de Supabase y no quedan altas ni faltantes.
La variante «Fondos en anillas kipping» se publicó como ficha editorial nueva.
Los datos publicados llegan también al Watch en la siguiente transferencia
nativa de entrenamientos por el Data Layer.

Se ha retirado el botón de Google Drive «Sincronizar» y su spinner de las
pantallas Cuenta del móvil. La copia privada existente sigue en las tareas
WorkManager de Drive. Wear OS recibe los entrenamientos por el Data Layer
del teléfono; no abre otra conexión Supabase ni se le delegan claves.

**QA pendiente:** ejecutar Android CI, pruebas instrumentadas
`RemoteExerciseCatalogInstrumentedTest`, migración de un historial de cliente,
modo avión, perfiles múltiples, sincronización Android↔iOS y reloj físico.
La periodicidad de WorkManager depende de la política de ahorro de energía
y no se promete ejecución inmediata con la app forzada a cerrar.

## Configuración externa

Google Cloud debe tener habilitados Credential Manager/Google Auth Platform, Drive API,
clientes OAuth Android/Web con huellas SHA correctas y pantalla de consentimiento.
En `~/.gradle/gradle.properties`:

```properties
REPERA_GOOGLE_WEB_CLIENT_ID=el_id_del_cliente_web
```

No subir secretos ni keys de servidor a Git. Ejecutar:

```shell
cd android
gradle :domain:testDebugUnitTest :mobile:assembleDebug :wear:assembleDebug
gradle :mobile:connectedDebugAndroidTest
```

**Validación:** CI `39931372564` aprobado: compilación de mobile/wear,
tests unitarios y pruebas instrumentadas en emulador. Las incorporaciones
posteriores de cronómetro y Diario tienen sus propios runs de CI.
**No se ha realizado aún el E2E OAuth/Drive con una cuenta Google ni pruebas
en un reloj físico.** Falta la paridad completa con iOS/watchOS.
Véanse `docs/STATUS_AND_PARITY.md`, `docs/GOOGLE_IDENTITY_DRIVE.md`,
`docs/AUDIT_2026_10_23.md`, `docs/MONETIZATION_PLAY_BILLING.md`,
`docs/RAMON_BLOCKERS.md` y `docs/BILLING_DEPLOY.md` (migrate/deploy verify).

## WOD (primera integración real)

Ya hay inicio de rutinas mixtas fuerza + WOD **con resultado global**,
registro por bloque (reps/rondas o tiempo) y guardado sin series inventadas.
Los movimientos por intervalo (EMOM, Tabata, Circuito) disponen de registro
manual, corrección y borrado. No hay paridad completa de los editores y
cronómetros iOS: revisar los casos todavía no cubiertos en `docs/PARITY_BACKLOG_2026_10_23.md`.
Ver `docs/STATUS_AND_PARITY.md`.

## Registro de cardio y métricas

Play ya admite registro nativo local de carrera, SkiErg, remoergómetro, bicicleta
y comba. Las cantidades se guardan con `quantityUnit` (`calories`, `meters` o
`reps`) y duración real opcional `durationSeconds`. El usuario puede corregir
las cantidades, la unidad cuando el ejercicio lo admite y el tiempo. La
evolución calcula mejores calorías, metros, duración y cargas desde las
series efectivas sin fabricar registros de WOD globales. Estas capacidades
no implican todavía paridad de la experiencia completa de Progreso con iOS.

En Wear OS, las series de fuerza con peso y reps se confirman con una cola
persistente y un identificador estable; terminar el entreno no borra las
pendientes. El cierre de sesión solicita limpiar la caché y las series del
reloj. Las mediciones de cardio y técnicas especiales aún deben registrarse
desde el móvil: el reloj no las transforma artificialmente en reps.

## Autenticación Google y Supabase

El ID OAuth Web público ya se incorpora como valor por defecto de
`REPERA_GOOGLE_WEB_CLIENT_ID`; también se configura la URL de Repera Supabase
y su clave pública `sb_publishable_`. Se exige una sesión Supabase validada
con ID token Google y nonce antes de mostrar la aplicación autenticada:
Credential Manager recibe `SHA-256(raw)` y Supabase el `raw` (`GoogleAuthNonce`).
No existen claves privadas ni OAuth Client Secret en el APK o en el repositorio.
Es posible sobrescribir los valores públicos mediante propiedades Gradle.
Checklist de consolas (SHA-1 Play + Authorized Client IDs):
`docs/GOOGLE_IDENTITY_DRIVE.md` y `docs/RAMON_BLOCKERS.md` (RP-28).


## Catálogo actualizado — iOS / Android

La biblioteca Android conserva los 196 movimientos originales e incorpora, mediante
migraciones locales idempotentes, los **82 movimientos de movilidad** y las
**2 estaciones HYROX adicionales**, hasta **280 ejercicios**. Los importados desde
Apple se identifican por nombre canónico cuando Swift no asigna catalogId;
no se reescriben UUID, sesiones, series, plantillas ni ejercicios personalizados.
Las posturas de movilidad permiten registrar duración sostenida sin RIR ni cargas;
el trabajo por movimiento no genera volumen de fuerza ni récords inventados.

HYROX es una etiqueta adicional para movimientos compartidos con CrossFit.
Burpee Broad Jump y Sandbag Lunges se registran por metros; el segundo admite
peso del saco. La distancia nunca se introduce como repeticiones en Epley/e1RM.
Las imágenes de los nuevos movimientos no tienen aún cobertura visual verificada
en Android y el planificador MCP, Play Billing y Health Services mantienen
tareas específicas de integración/E2E.
