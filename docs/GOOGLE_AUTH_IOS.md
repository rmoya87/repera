# Inicio de sesión Google · Repera iOS

Última actualización: 2026-10-24 (SDK oficial Google Sign-In).

Repera utiliza `GoogleSignIn` y `GoogleSignInSwift` **10.1.0** mediante Swift Package Manager. El botón es `GoogleSignInButton` del SDK, en estilo `.wide`, con los recursos, localización y estados que proporciona Google. No se dibuja una G ni se distribuyen fuentes propias para imitarlo.

## Configuración necesaria

1. En el proyecto Google Cloud **repera-app**, crear o localizar un cliente OAuth de tipo **iOS** para el bundle `com.app.repera`. Los IDs Web y Android existentes no sustituyen este cliente. No se necesita un client secret en el iPhone.
2. `Configs/GoogleSignIn.xcconfig` ya contiene los identificadores públicos facilitados por el propietario:
   - `REPERA_GOOGLE_IOS_CLIENT_ID`: identificador del cliente iOS.
   - `REPERA_GOOGLE_REVERSED_CLIENT_ID`: esquema invertido que muestra Google Cloud; por ejemplo, `com.googleusercontent.apps.123456-example` para `123456-example.apps.googleusercontent.com`.
   - `REPERA_GOOGLE_SERVER_CLIENT_ID`: ya contiene el cliente Web existente `1026054616574-qmugi1nalpar1vv0tdftv97cn6aljoji.apps.googleusercontent.com`, usado como audiencia del token para Supabase.
3. Cerrar Xcode y ejecutar `./Repera-Xcode.command` desde la raíz: regenera el proyecto y ejecuta `xcodebuild -resolvePackageDependencies` antes de abrirlo. `Version.xcconfig` incluye la configuración; `project.yml` y `Info.plist` declaran `GIDClientID`, `GIDServerClientID` y el esquema de retorno. No copiar el cliente Android en estos valores.
4. En el proveedor Google de Supabase, mantener habilitado Google y comprobar que el cliente **Web** anterior figura como audiencia admitida. No desactivar la verificación del nonce.
5. Para vincular Google desde una cuenta Apple, habilitar **Manual Linking** en Supabase Auth.

**Estado:** cliente iOS `1026054616574-537ebde8voqhs74are9ra05a0gjhjmad.apps.googleusercontent.com` y esquema `com.googleusercontent.apps.1026054616574-537ebde8voqhs74are9ra05a0gjhjmad` configurados. El esquema coincide con la inversión del identificador. La app valida estos ajustes antes de llamar al SDK. El cliente Web existente se mantiene como audiencia del backend. Pendientes la resolución SPM, compilación y validación interactiva en Xcode/iPhone; configurar los identificadores no acredita una prueba de autenticación real.

## Flujo e identidad

- El botón llama a `GIDSignIn.sharedInstance.signIn(withPresenting:hint:additionalScopes:nonce:completion:)`, desde la escena activa. El SDK decide la interfaz de autenticación; la app no sustituye sus pantallas ni promete un selector de cuentas sin diálogo web.
- Cada intento crea un nonce criptográfico distinto: Google recibe su SHA-256 hexadecimal y Supabase recibe el valor original junto al ID token y access token. Solo la respuesta validada por `signInWithIdToken` permite continuar.
- `ReperaApp.onOpenURL` entrega la respuesta al SDK mediante `GIDSignIn.sharedInstance.handle(url)`. Este flujo no utiliza el retorno `repera://auth/callback` del OAuth web anterior.
- Se comprueba el UUID Supabase contra el propietario local antes de reutilizar datos. No se fusionan historiales por comparar direcciones de correo.
- **Cuenta → Vincular cuenta de Google** obtiene la credencial con el mismo SDK y usa `linkIdentityWithIdToken` sobre la sesión Apple existente. Debe conservar el UUID antes de informar del éxito. Si Google ya pertenece a otra cuenta, el backend rechaza la vinculación; no se ejecuta una fusión manual.
- Cancelar el SDK deja la app en el mismo estado y no muestra un error de acceso. Cerrar sesión limpia Google y Supabase, conserva el identificador no secreto del dueño local e invalida los intentos pendientes.
- La sesión Supabase en Keychain sigue siendo la fuente del estado de acceso y de su restauración. La actualización de la app no exige volver a pasar por Google si la sesión existente sigue disponible.
- iCloud es un almacenamiento distinto: utilizar Google no traslada los archivos de otro Apple ID ni sincroniza automáticamente con Google Drive de Android.

## Bienvenida

«Todo tu entrenamiento. Cada vez mejor.» presenta rutinas, escaneo de pizarra, registro de series y WOD, marcas, actividad, recuperación, Apple Watch y ayuda del entrenador o IA. El contenido permite scroll y Dynamic Type; la mascota reduce su altura en paisaje. El texto técnico de identidad/Supabase se ha eliminado de la bienvenida.

## Validación

Si Xcode muestra `No such module GoogleSignIn` o `Unable to resolve module dependency: GoogleSignInSwift`, comprobar primero la generación y la resolución de paquetes del proyecto local: ambos productos ya figuran en `project.yml`. El lanzador resuelve sus dependencias de forma explícita y se detiene si falla la descarga. No eliminar los imports del SDK ni volver al botón imitado para ocultar el problema.

Las comprobaciones estáticas protegen el uso del SDK, las dependencias y variables de configuración, el nonce, la vinculación y el propietario local. No sustituyen una compilación ni una prueba interactiva.

Pendiente en Xcode/iPhone firmado: regenerar XcodeGen, resolver SPM y compilar con Swift 6; comprobar botón y localización en claro/oscuro, Google nuevo, mismo UUID Apple/Google, Apple con correo privado y vinculación, cuenta distinta rechazada, cancelación, logout, relanzamiento y sesión anterior conservada. El entorno de edición no tiene Xcode ni Swift para ejecutar estas pruebas.

El error anterior de retorno a `localhost` correspondía al flujo OAuth web y el usuario confirmó que se había resuelto. Con el SDK nativo, el retorno depende del esquema invertido del cliente iOS; conservar las redirecciones web existentes para los otros clientes.

Referencias: [configuración iOS de Google](https://developers.google.com/identity/sign-in/ios/start-integrating), [botón y autenticación](https://developers.google.com/identity/sign-in/ios/sign-in), [SDK y API](https://github.com/google/GoogleSignIn-iOS/tree/10.1.0), [Supabase ID token](https://supabase.com/docs/reference/swift/auth-signinwithidtoken).
