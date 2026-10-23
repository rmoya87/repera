# Identidad Google y Google Drive (Android)

## Identidad

- Se usa **Credential Manager** y `GetSignInWithGoogleOption`. No existe botón de Apple en Android.
- La ID token de Google proporciona identidad visual local; requiere validar
  firma, emisor, audiencia, expiración y nonce en backend antes de conceder acceso a Supabase.
- `uniqueId` es el identificador estable de cuenta para aislar ficheros, **nunca el correo**.
- `clearCredentialState` restaura la vista inicial; los datos siguen protegidos en el
  espacio privado de esa cuenta para un futuro acceso válido.

## Drive

- Scope OAuth incremental: `https://www.googleapis.com/auth/drive.appdata`.
- `AuthorizationClient` solicita acceso a la misma cuenta Google del inicio de sesión.
- La app usa únicamente `appDataFolder/app_state.json`, invisible en Mi unidad.
- Token de acceso en memoria de una sola operación. Nunca se persiste en preferencias,
  logs ni archivos.
- Las copias se verifican antes de escribir. `AtomicFile` preserva la escritura local
  y guarda la versión local previa; antes de sobrescribir Drive se preserva una copia
  de la versión remota.
- Si coinciden revisión, fecha y escritor pero difieren los bytes, se bloquea la sincronización.
  En otro caso se utiliza exactamente la prioridad de Swift: revisión, fecha y escritor;
  se guarda copia antes de reemplazar una versión.
- Comparación de revisiones distinta: `SyncConflictResolver` de Swift (revision,
  `updatedAt`, `lastWriterDeviceId`). Es necesario probar serialización de fechas.
- Un mismo usuario en Google Drive no recibe automáticamente sus datos de iCloud;
  la migración explícita iOS→Android sigue pendiente.
- La carpeta privada puede eliminarse desde Google Drive o al quitar acceso de la
  aplicación. Local-first se mantiene como fuente de respaldo.
- Pendiente: pruebas de concurrencia real, límites, errores de cuota, desconexión y
  migración; no presentar como sincronización validada en producción.

Referencias:
- https://developer.android.com/identity/sign-in/credential-manager-siwg-implementation
- https://developer.android.com/identity/authorization
- https://developers.google.com/workspace/drive/api/guides/appdata
