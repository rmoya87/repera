# Repera Android / Wear OS — estado de implementación

Fecha base: 2026-10-23. Fuente de verdad: `main` del repositorio Repera,
`Packages/ReperaDomain`, `Apps/Repera` y `Apps/ReperaWatch`.

## Normas no negociables

1. Android nativo Kotlin + Jetpack Compose Material 3; Wear OS nativo Compose for Wear OS Material 3.
2. Google Credential Manager como identidad de usuario Android, **sin Apple ID**.
3. `AuthorizationClient` solicita consentimiento Drive por separado, scope `drive.appdata`.
4. Estado privado local por identidad Google; backups en appDataFolder privada por cuenta.
5. No utilizar correo como prueba de identidad para RLS, no vincular cuentas Apple/Google por correo.
6. Supabase profesional separado: necesita Google como provider OAuth con verificación JWT, políticas RLS y pruebas reales antes de habilitar sus operaciones.
7. Paridad semántica con Swift: sin estimar datos de Salud, sin crear registros ficticios, sin sustituir planes del entrenador por rutinas personales.
8. Sin afirmar paridad hasta pasar compilación, tests unitarios y E2E con dispositivos.

## Base comprobada en Swift y traducida en Android

| Área | Fuente Swift | Android actual | Pendiente |
|------|--------------|----------------|-----------|
| Reglas de reloj y descansos | WorkoutClockMath.swift | `domain/WorkoutClock.kt` | E2E de temporizador real |
| WOD 14 formatos y score | Models.swift / WODFormat | `domain/WodRules.kt` | ejecución de cada formato |
| Presets por serie y calentamiento | SessionExercise.nextWorkSetPrescription | `domain/SetPrescription.kt` | editor/sesión |
| Revisión sin duplicación | SessionController.replaceLoggedSet | `domain/SetPrescription.kt` | editor completo |
| Sign in | AppleAuthStore | Credential Manager Google en MainActivity | OAuth cliente real / backend |
| Almacén personal | LocalStore + iCloud | AtomicFile por Google ID + Drive appDataFolder | importación de histórico iCloud / comparación E2E |
| Inicio, Diario, Crear, Progreso, Ejercicios | RootTabView y vistas SwiftUI | Navegación Material 3, listado real de histórico/rutinas/catálogo | toda la funcionalidad e interacciones |
| Watch | WatchSessionHub | pantalla Wear + Data Layer lectura del estado activo | sesión offline, Health Services, series, WOD y cronómetro |
| Supabase centros | BusinessAuthStore y BusinessDataStore | no activado | proveedor Google, RLS, reservas, planes |
| Pro / compras | StoreKit + RevenueCat | no activado | Play Billing y misma política `FeatureAccessPolicy` |
| Salud | HealthKit | no activado | Health Connect, Health Services, procedencia |
| Escáner pizarra | BoardImportPipeline | no activado | ML Kit on-device y parser idéntico |
| Catálogo y estadísticas | Catalog*.swift, StatsEngine | sólo conteo de JSON real | port de dominio y gráficos |

### Limitación esencial de la nube

El inicio de sesión con Google y Google Drive **no dan acceso al iCloud privado** de
un usuario Apple. No prometemos sincronización automática entre ecosistemas:
se necesita exportar/importar datos iOS o un protocolo de migración explícito.
Google Drive sirve como almacén personal Android y nunca debe usarse para
hacer escrituras sobre iCloud. El formato JSON de base conserva los nombres de
`AppState` Swift; validación integral de compatibilidad queda pendiente.

### Por qué no está listo para publicación

No hay client ID OAuth configurado, servidor de verificación de identidad,
Google Drive API/OAuth consent en proyecto Google Cloud verificados,
Google Play Billing, Health Connect, pruebas Gradle en CI ni emuladores
ejecutados en esta sesión. No sustituir estos hechos por valores simulados.
Las apps Apple de `main` no deben cambiar.
