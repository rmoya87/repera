# Repera Android y Wear OS (trabajo en curso)

Implementación nativa independiente en `android/`:

- `mobile`: Kotlin + Jetpack Compose / Material 3, Credential Manager Google,
  Google Drive appDataFolder, historial local, importación JSON y ejecución de
  rutinas de fuerza y WOD con resultado global, cronómetro local persistente,\n  programación por fecha/semana y persistencia compatible con `AppState` Swift.
- `domain`: reloj, captura de resultado WOD, prescripción y resolución de conflictos.
- `wear`: Compose for Wear OS Material 3 y recepción de sesión activa mediante Data Layer.
- `Health Connect`: lectura voluntaria de pasos y calorías activas reales, sin datos inventados ni escrituras.

Google reemplaza a Apple en Android; Google Drive reemplaza a iCloud para
el almacenamiento privado. Para dar acceso profesional a Supabase se requiere
un proveedor Google y autenticación verificada en backend; nunca basta con el
identificador de cuenta obtenido en el teléfono.


## Biblioteca de movilidad

El catálogo Android mantiene los **196 movimientos anteriores** e incorpora **82 ejercicios de movilidad** (278 ejercicios en el seed inicial) importados de `CatalogMovilidad.swift` en la rama iOS `feat/exercise-mobility-catalog-20261023`. Incluyen nombre español, alias ingleses, descripción, dos instrucciones, grupo muscular y el campo `sportTag = "Movilidad"`.

En **Ejercicios** hay chips Material 3 **Todos / Movilidad** y búsqueda bilingüe. `CatalogBootstrap.appendMissingMobility` añade exclusivamente los 82 ejercicios ausentes a cuentas ya existentes, conserva los UUID y los entrenamientos anteriores, y evita duplicaciones en sucesivos arranques. Las sesiones de movilidad no admiten introducir kg como fuerza. Hay pruebas instrumentadas para catálogo, alias y migración idempotente.

**Pendiente de validación real:** compilar e instrumentar en emulador/dispositivo, revisar miniaturas y sincronizar el contenido con las versiones finales de iOS cuando se fusionen las ramas. No se asume que las imágenes de movilidad estén generadas ni revisadas.

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
Los formatos por movimiento (EMOM, Tabata, Circuito, etc.) permanecen
bloqueados. Tampoco se afirma que el reloj en Play funcione aún como iOS.
Ver `docs/STATUS_AND_PARITY.md`.

## Autenticación Google y Supabase

El ID OAuth Web público ya se incorpora como valor por defecto de
`REPERA_GOOGLE_WEB_CLIENT_ID`; también se configura la URL de Repera Supabase
y su clave pública `sb_publishable_`. Se exige una sesión Supabase validada
con ID token Google y nonce antes de mostrar la aplicación autenticada.
No existen claves privadas ni OAuth Client Secret en el APK o en el repositorio.
Es posible sobrescribir los valores públicos mediante propiedades Gradle.
La sesión verificada no se persiste: al reiniciar el proceso se solicita
una nueva autenticación.
