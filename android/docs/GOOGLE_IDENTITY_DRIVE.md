# Identidad Google y Google Drive (Android)

## Identidad

- Se usa **Credential Manager** y `GetSignInWithGoogleOption`. No existe botón de Apple en Android.
- La ID token de Google proporciona identidad visual local; requiere validar
  firma, emisor, audiencia, expiración y nonce en backend antes de conceder acceso a Supabase.
- `uniqueId` es el identificador estable de cuenta para aislar ficheros, **nunca el correo**.
- `clearCredentialState` restaura la vista inicial; los datos siguen protegidos en el
  espacio privado de esa cuenta para un futuro acceso válido.

## Configuración OAuth recibida (23/10/2026)

Google Cloud project **repera-app**; OAuth consent *External / Testing*.
El usuario ha comunicado que Drive API, scopes y proveedor Google de Supabase están habilitados. Estos ajustes de consola todavía requieren una prueba real con una cuenta autorizada; el conector de Supabase confirma que el proyecto está activo pero no expone la configuración de proveedores Auth.

- Client ID **Web** (identificador público): `1026054616574-qmugi1nalpar1vv0tdftv97cn6aljoji.apps.googleusercontent.com`. Se configura en `android/gradle.properties` y se utiliza como `serverClientId` de Credential Manager. No guardar aquí el client secret.
- Client ID **Android** (identificador público): `1026054616574-aklvn35uk4np08a3b61c5utq06j9vr24.apps.googleusercontent.com`. Google Play Services lo relaciona con `com.app.repera` y el certificado SHA-1 registrado en Google Cloud; **no** sustituye al ID Web en `GetSignInWithGoogleOption`.
- Scope Drive separado: `https://www.googleapis.com/auth/drive.appdata`. No solicitar `drive` completo.
- La cuenta utilizada debe estar incluida entre los usuarios de prueba hasta publicar la pantalla OAuth. La huella debug debe coincidir con el APK instalado y debe añadirse también la de firma de Google Play para producción.
- OAuth Web de Supabase: comprobar en su consola que el callback sea exactamente `https://uvzgujlrqohreoucirms.supabase.co/auth/v1/callback` si no existe dominio Auth personalizado.

**Límite de implementación**: Android obtiene identidad de Google para aislar datos locales y solicitar Drive, pero todavía **no intercambia el Google ID token por una sesión Supabase Auth**. Habilitar Google en Supabase no crea por sí solo esa sesión, permisos RLS ni el vínculo con usuarios Apple. No tratar `GoogleIdTokenCredential.uniqueId` como un `auth.uid()` o token de acceso a Supabase. Para la integración profesional habrá que completar `signInWith(IDToken)` (Google) con nonce compatible, sesión verificada, logout/revocación y pruebas E2E.

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
