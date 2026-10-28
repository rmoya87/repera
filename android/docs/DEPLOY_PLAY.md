# Despliegue Repera Android en Google Play (beta)

Autorizado por Ramon el 25/10/2026 ("Ok hazlo", tras plan presentado por chat):
beta automatica SOLO de telefono a prueba INTERNA; produccion preparada pero
SIN via ejecutable; Wear y pruebas cerrada/abierta posteriores; nada de
productos/suscripciones/precios/backend comercial en este alcance.

## Flujo

1. Push a la rama `beta` (nace de `feat/android-wear-native-parity`).
2. El workflow `.github/workflows/android-native-ci.yml` ejecuta TODOS los
   tests (JVM, telefono API 30/35/37.2, Wear 5.1/6.0).
3. Solo si todos estan verdes, el job `deploy-internal-beta` construye el AAB
   release de telefono firmado con la upload key y lo sube a la track
   **internal** (status completed).
4. Tras el primer AAB, Play App Signing genera el certificado de firma de la
   app: registrar su SHA-1 como SEGUNDO cliente OAuth Android en el proyecto
   Cloud "Repera" (conservando el cliente debug de desarrollo).

## Versionado

- `versionCode` = minutos desde 2026-01-01 UTC: monotonico por reloj de
  pared, inmune a reejecuciones de runs antiguos (un re-run obtiene un codigo
  nuevo y mayor), unico mientras los despliegues esten serializados por el
  concurrency group del workflow. Limite de Play 2100000000: holgado.
  No existian releases previos (verificado 25/10/2026).
- `versionName` = tag exacto si el commit lo tiene; si no,
  `0.1.0-beta.<run_number>`.
- Builds locales: versionCode 1 / 0.1.0 (sin cambios).

## Secrets de GitHub Actions (solo nombres; valores en vault/secret store)

- `REPERA_UPLOAD_KEYSTORE_B64`: keystore de subida (PKCS12) en base64.
- `REPERA_UPLOAD_STORE_PASSWORD`: password del keystore (PKCS12: la misma
  para almacen y clave). Alias: `repera-upload`.
- `REPERA_PLAY_SERVICE_ACCOUNT_JSON`: JSON de la cuenta de servicio de
  Google Cloud con permiso de releases limitado a Repera.

La password del keystore esta ademas en el vault (entrada
"Repera upload keystore"). Perder la upload key es recuperable pidiendo un
reset a soporte de Google Play; la app signing key la guarda Google.

## Produccion: BLOQUEADA

La rama `produccion` existe como referencia pero NO hay job, workflow ni
via alguna que publique a produccion. Habilitar cualquier despliegue a
produccion requiere autorizacion explicita nueva de Ramon. Ademas, Google
exige para cuentas personales creadas tras el 13/11/2023 una prueba cerrada
con >=12 testers con opt-in continuo durante 14 dias antes de conceder
acceso a produccion (support.google.com/googleplay/android-developer/answer/14151465),
y la track abierta solo se desbloquea tras ese acceso.

## Requisitos pendientes fuera de este alcance

- Ficha de tienda completa (icono 512, feature graphic 1024x500, capturas),
  Health apps declaration y precio gratis: necesarios para prueba CERRADA.
- Lista de >=12 testers para la cerrada.
- Suscripciones 5,99/39,99 + RTDN + verificacion backend: autorizacion
  separada; trial aun por decidir.

## Rollback

- Parar el despliegue: borrar la rama `beta` o revertir el commit del
  workflow; cancelar el run en Actions.
- Un release ya subido a internal puede retirarse desde Play Console
  (Release > Testing > Internal testing) sin afectar a nada mas.
