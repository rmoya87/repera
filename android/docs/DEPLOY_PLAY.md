# Despliegue Repera Android en Google Play (beta)

**Última actualización:** 2026-11-10 — gate estricto para Android estable, versión mensual AAAA.MM.VV y notas verificables en Google Play Internal.

Autorizado por Ramon el 25/10/2026 ("Ok hazlo", tras plan presentado por chat):
beta automatica SOLO de telefono a prueba INTERNA; produccion preparada pero
SIN via ejecutable; Wear y pruebas cerrada/abierta posteriores; nada de
productos/suscripciones/precios/backend comercial en este alcance.

## Flujo

1. Push a `main`: compilar Android y Wear; ejecutar toda la suite JVM de `mobile`,
   pruebas de dominio y Wear, y pruebas instrumentadas de Android.
2. Sync / push a `beta` (cuando esté validado): el mismo workflow repite la
   validación y despliega exclusivamente la aplicación de teléfono a Google
   Play, pista **internal**. `main` y las pull requests jamás publican.
3. **Gate de publicación**: compilación y tests JVM completos + instrumentación
   estable Android API 30/35. Wear OS y Android 17 canary siguen probándose,
   pero no bloquean la distribución del teléfono por sus problemas históricos
   de arranque de imágenes. No se omite el gate mediante parámetros manuales.
4. Se consulta el estado actual de Google Play antes de construir el AAB
   firmado. Se aborta si es un commit obsoleto de `beta`.
5. Se genera la versión y las notas en español con
   `android/scripts/play_release_metadata.py` y se suben como artefacto
   `play-release-metadata`. También se guarda el SHA256 del AAB firmado.
6. La acción de publicación utiliza `releaseName` y `whatsNewDirectory`
   (archivo `whatsnew-es-ES`), con estado `completed` en la pista
   `internal` únicamente. Una subida completada no garantiza disponibilidad
   instantánea para los probadores.

## Versionado mensual

- **`versionName` visible**: `AAAA.MM.VV` con dos dígitos para el mes y
  `VV` incremental desde `0` en cada mes:
  `2026.11.0`, `2026.11.1`; en diciembre `2026.12.0`.
  La fecha se calcula en la zona horaria `Europe/Madrid`.
- El contador mensual se calcula comparando los nombres de todas las releases
  disponibles en las pistas de Google Play. Las versiones antiguas de formato
  `0.1.0-beta.*` no impiden comenzar por `2026.11.0`.
- **`versionCode` interno**: entero positivo creciente, mayor que los códigos
  encontrados en pistas y bundles de Play y como mínimo los minutos desde
  2026-01-01 UTC. No puede ser `2026.11.0` porque Android exige un entero.
  Se comprueba el máximo de 2.100.000.000.
- Los valores se pasan al build release por
  `-PREPERA_VERSION_NAME` / `-PREPERA_VERSION_CODE`. Los builds locales
  siguen usando valores por defecto sin alterar el número de versión del código.
- Para publicar varias versiones simultáneas hay que serializar los despliegues.
  El workflow cancela runs antiguos de la misma rama y comprueba el HEAD antes
  de subir. No habilitar otro publicador concurrente sin protección adicional.

## Novedades: comparación con la última producción

- Se consulta la pista `production` de Play. Si tiene una release efectiva
  (`completed` / `inProgress`), se exige la versión y **fecha real de subida**
  verificadas en Play Console mediante dos variables de GitHub Actions:
  `REPERA_LAST_PRODUCTION_VERSION` (nombre exacto de la release actual,
  por ejemplo `2026.10.5`) y `REPERA_LAST_PRODUCTION_DATE` (fecha y hora
  ISO 8601, por ejemplo `2026-10-31T12:00:00+01:00`).
  **No se deben inventar**: la API Publisher entrega nombre, códigos y estado,
  pero no el instante histórico de subida. Si faltan, o no corresponden a la
  última versión de producción, el deploy se detiene.
- Se leen los títulos de los commits Android posteriores a dicha fecha, se
  transforman señales identificables en beneficios para usuarios y se genera
  un texto de hasta 500 caracteres, apto para Google Play, en español.
  No se citan novedades que no aparezcan en el historial de Android.
- Si **no hay publicación en producción** (estado documentado de Repera),
  no se finge una fecha de producción: la primera versión del mes utiliza
  los cambios Android desde su inicio. En el artefacto aparece la procedencia
  `first-release-month`. Si no existen cambios Android verificables, el
  proceso falla en lugar de inventar características.
- Cuando se publique una nueva versión en producción **fuera de este CI**,
  registrar inmediatamente sus dos variables con la fecha real de Play
  antes del siguiente deploy interno.
- Pruebas del generador: `python3 -m unittest discover -s android/scripts
  -p 'test_play_release_metadata.py' -v`.

## Mantenimiento y avisos de CI

- El publicador queda fijado al commit verificado de `r0adkll/upload-google-play`
  (`v1.1.5`, `e738b9dd8f2476ea806d921b64aacd24f34515a5`). No se
  depende de la etiqueta móvil `v1`. Las advertencias Node.js `DEP0040`
  (`punycode`) y `DEP0169` (`url.parse`) proceden de dependencias
  del publicador y constan en
  https://github.com/r0adkll/upload-google-play/issues/265. No se ocultan.
  Antes de reemplazar esta acción se debe validar firma, mapping, notas en
  español, versionCode, track internal, edición atómica y prohibición de
  publicar a producción, en una prueba sin subir una segunda release.
- La instalación de plataformas usa el Android CLI oficial con
  `android sdk install --canary`, no `sdkmanager` obsoleto:
  https://developer.android.com/tools/agents/android-cli/commands/sdk_install.
- El job de release genera el artefacto `android-native-symbols-release`,
  con un inventario no destructivo de bibliotecas `.so` y secciones de
  símbolos presentes. El aviso `Unable to strip` no demuestra un defecto
  funcional: nunca borrar bibliotecas, hacer `doNotStrip` global o manipular
  el bundle solo para eliminar mensajes.
- Los tests y el generador de novedades leen únicamente commits que hayan
  modificado `src/main` de Android; las alteraciones exclusivas de tests,
  workflows y documentación no se presentan como novedades de producto.
  Los mensajes de marketing y las evidencias quedan registrados en
  `release-metadata.json`. Si la pista production existe, su fecha real
  y versión siguen siendo obligatorias y se verifican.
- Para revisar estos cambios se usa solo `main`; no sincronizar `beta`
  por mantenimiento del CI: un push a esa rama activa un nuevo release.

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
