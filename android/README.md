# Repera Android y Wear OS (trabajo en curso)

Implementación nativa independiente en `android/`:

- `mobile`: Kotlin + Jetpack Compose / Material 3, Credential Manager Google,
  Google Drive appDataFolder, historial local, importación JSON y ejecución de
  rutinas **de fuerza** con persistencia compatible con `AppState` Swift.
- `domain`: reloj, captura de resultado WOD, prescripción y resolución de conflictos.
- `wear`: Compose for Wear OS Material 3 y recepción de sesión activa mediante Data Layer.
- `Health Connect`: lectura voluntaria de pasos y calorías activas reales, sin datos inventados ni escrituras.

Google reemplaza a Apple en Android; Google Drive reemplaza a iCloud para
el almacenamiento privado. Para dar acceso profesional a Supabase se requiere
un proveedor Google y autenticación verificada en backend; nunca basta con el
identificador de cuenta obtenido en el teléfono.

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

**Estado:** no verificadas estas compilaciones con SDK/Gradle, ni OAuth/Drive
con cuentas reales. Falta la paridad completa con iOS/watchOS.
Véanse `docs/STATUS_AND_PARITY.md`, `docs/GOOGLE_IDENTITY_DRIVE.md`
y `docs/AUDIT_2026_10_23.md`.

## WOD (primera integración real)

Ya hay inicio de rutinas mixtas fuerza + WOD **con resultado global**,
registro por bloque (reps/rondas o tiempo) y guardado sin series inventadas.
Los formatos por movimiento (EMOM, Tabata, Circuito, etc.) permanecen
bloqueados. Tampoco se afirma que el reloj en Play funcione aún como iOS.
Ver `docs/STATUS_AND_PARITY.md`.
