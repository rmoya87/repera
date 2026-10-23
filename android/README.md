# Repera Android y Wear OS (trabajo en curso)

Implementación nativa independiente en `android/`:

- `mobile`: Kotlin + Jetpack Compose / Material 3, Credential Manager Google,
  Google Drive appDataFolder, historial local, importación/exportación JSON y ejecución de
  rutinas de fuerza y WOD global o por movimiento, cronómetro local persistente,
  programación por fecha/semana y persistencia compatible con `AppState` Swift.
- `domain`: reloj, captura de resultado WOD, prescripción y resolución de conflictos.
- `wear`: Compose for Wear OS Material 3, sesión desde Data Layer y registro de series de fuerza
  con cola offline y confirmaciones; faltan reconciliación automática sin abrir el móvil,
  ejecución completa de WOD y Health Services.
- `Health Connect`: lectura voluntaria de pasos y calorías activas reales, sin datos inventados ni escrituras.

Google reemplaza a Apple en Android; Google Drive reemplaza a iCloud para
el almacenamiento privado. Para dar acceso profesional a Supabase se requiere
un proveedor Google y autenticación verificada en backend; nunca basta con el
identificador de cuenta obtenido en el teléfono.

## Movilidad — 82 ejercicios con tiempo real

La categoría **Movilidad** incluye 82 ejercicios con alias ES/EN, clasificación anatómica, seis indicaciones técnicas por ficha y migración segura de usuarios existentes. En Material 3 aparece el chip «Movilidad» dentro de Ejercicios, sin retirar los filtros de cardio, Hyrox o deporte.

- Configuración de rutinas: segundos prescritos por serie (`targetDurationSeconds`) y repeticiones cuando el movimiento es dinámico; las posturas sostenidas solo tienen tiempo.
- Play: se parte de la duración prescrita, se pueden corregir los segundos realizados y se guardan en `LoggedSet.durationSeconds`. Para movilidad no existen kg ni RIR.
- Wear OS: registro de segundos desde el reloj con controles de incrementos de cinco segundos y outbox con UUID, confirmado por el teléfono. No se marcan las series como guardadas hasta recibir confirmación.
- Evolución y Progreso: mejor duración por ejercicio, repeticiones si aplican, tiempo acumulado y sesiones reales. Una prescripción no registrada nunca se contabiliza como progreso ni como volumen de fuerza o fatiga.
- La lista y ficha utilizan un icono/diagrama de respaldo. **Ninguna de las 82 imágenes técnicas definitivas está creada ni validada**: no se debe afirmar cobertura visual completa.

**Validación pendiente:** confirmar compilación actual de mobile y wear, ejecución de pruebas instrumentadas, funcionalidad sobre un Wear OS real y sincronización del catálogo con iOS. No se debe dar por finalizada la paridad sin estas comprobaciones.

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
Véanse `docs/STATUS_AND_PARITY.md`, `docs/GOOGLE_IDENTITY_DRIVE.md`
y `docs/AUDIT_2026_10_23.md`.

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
con ID token Google y nonce antes de mostrar la aplicación autenticada.
No existen claves privadas ni OAuth Client Secret en el APK o en el repositorio.
Es posible sobrescribir los valores públicos mediante propiedades Gradle.
La sesión verificada no se persiste: al reiniciar el proceso se solicita
una nueva autenticación.
