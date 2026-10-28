# Identidad Google y Google Drive (Android)

**Última actualización:** 2026-10-28

## Identidad

- Se usa **Credential Manager** y `GetSignInWithGoogleOption`. No existe botón de Apple en Android.
- Flujo: Google emite un ID token → la app lo intercambia con Supabase
  (`POST /auth/v1/token?grant_type=id_token`) → solo la sesión verificada abre la app.
- **Nonce (obligatorio, paridad iOS):** Credential Manager recibe
  `SHA-256(raw)` en hex (`GoogleAuthNonce.hashedHex`); Supabase recibe el
  `raw`. Enviar el mismo string a ambos provoca Auth HTTP 400 (nonce
  mismatch); el mensaje genérico de la app dice «revisa Google Client IDs».
- `uniqueId` es el identificador estable de cuenta para aislar ficheros, **nunca el correo**.
- `clearCredentialState` restaura la vista inicial; los datos siguen protegidos en el
  espacio privado de esa cuenta para un futuro acceso válido.

## Client IDs públicos (app)

| Rol | ID | Dónde |
|-----|-----|--------|
| **Web** (audiencia del ID token / `serverClientId`) | `1026054616574-qmugi1nalpar1vv0tdftv97cn6aljoji.apps.googleusercontent.com` | `android/gradle.properties` → `REPERA_GOOGLE_WEB_CLIENT_ID` → `BuildConfig.GOOGLE_WEB_CLIENT_ID` |
| **Android** (paquete + SHA-1; no va en Credential Manager) | `1026054616574-aklvn35uk4np08a3b61c5utq06j9vr24.apps.googleusercontent.com` | Solo Google Cloud / Play Services |

- Paquete: `com.app.repera`.
- Supabase URL: `https://uvzgujlrqohreoucirms.supabase.co`.
- Scope Drive separado: `https://www.googleapis.com/auth/drive.appdata` (nunca `drive` completo).
- No guardar client secret ni `service_role` en el APK.

## Pasos exactos en Google Cloud (Ramón)

Proyecto **repera-app** → APIs y servicios → Credenciales.

1. **Cliente OAuth Web** (ya existe): confirmar el ID de la tabla superior.
   Su *Client secret* solo se usa en el proveedor Google de Supabase (paso
   siguiente), nunca en la app.
2. **Cliente(s) OAuth Android** para `com.app.repera`:
   - Mantener el cliente de **debug** con la SHA-1 del
     `~/.android/debug.keystore` (desarrollo / `assembleDebug`).
   - Crear un **segundo** cliente Android (o editar uno dedicado a release)
     con la SHA-1 de **Play App Signing** (no la upload key):
     `AA:A1:93:52:FE:D0:C3:8C:B0:5D:CD:A9:60:3D:53:7B:39:59:D6:93`
     (Play Console → App Repera → Configuración → Integridad de la app →
     Certificado de firma de la aplicación → SHA-1).
3. Pantalla de consentimiento OAuth: External / Testing → añadir la cuenta
   de prueba que vaya a iniciar sesión hasta publicar la app.
4. APIs: Drive API habilitada; Credential Manager / Google Identity activos.

Sin el cliente Android + SHA-1 del APK que se instala, Google a menudo falla
*antes* de llegar a Supabase. Si el selector de cuentas funciona y el error
es `Supabase Auth HTTP 400: revisa Google Client IDs`, el fallo está en
nonce (ya corregido en código) o en la audiencia / secret de Supabase.

## Pasos exactos en Supabase Dashboard (Ramón)

Proyecto `uvzgujlrqohreoucirms` → Authentication → Providers → **Google**:

1. Provider **Enabled**.
2. **Client ID** = cliente **Web**
   `1026054616574-qmugi1nalpar1vv0tdftv97cn6aljoji.apps.googleusercontent.com`.
3. **Client Secret** = el secret de ese mismo cliente Web (Google Cloud →
   Credenciales → cliente Web → Secretos).
4. **Authorized Client IDs** (audiencias admitidas del ID token), separados
   por coma si hay varios:
   - Web: `1026054616574-qmugi1nalpar1vv0tdftv97cn6aljoji.apps.googleusercontent.com`
   - Android: `1026054616574-aklvn35uk4np08a3b61c5utq06j9vr24.apps.googleusercontent.com`
     (y el ID del segundo cliente Android de Play SHA-1 si Cloud crea uno nuevo).
5. Callback Auth (si no hay dominio custom):
   `https://uvzgujlrqohreoucirms.supabase.co/auth/v1/callback`.
6. No desactivar la verificación de nonce.
7. Guardar → reintentar login en el dispositivo.

Esto **no** es billing ni Play Billing; es solo OAuth / Auth.

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
- Un mismo usuario en Google Drive no recibe automáticamente sus datos de iCloud;
  la migración explícita iOS→Android sigue pendiente.
- Pendiente: pruebas E2E de concurrencia, cuota y dispositivo firmado con cuenta de prueba.

Referencias:
- https://supabase.com/docs/guides/auth/social-login/auth-google?platform=android
- https://developer.android.com/identity/sign-in/credential-manager-siwg-implementation
- https://developer.android.com/identity/authorization
- https://developers.google.com/workspace/drive/api/guides/appdata
