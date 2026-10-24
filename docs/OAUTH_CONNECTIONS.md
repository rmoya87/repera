# Conexión de ChatGPT y Claude

Última actualización: 2026-10-24.

## Estado y alcance

OAuth gestionado por Supabase Auth y consentimiento web. **ChatGPT sigue pendiente de verificación del desarrollador y publicación en su directorio. Claude dispone de conexión personalizada guiada por un prompt**, sin publicar en el directorio de Anthropic. El catálogo habilita cada recorrido solo cuando tiene su configuración real. Las instrucciones de Claude contienen únicamente direcciones e ID público de cliente; nunca tokens, secretos ni datos del deportista. No se utiliza la suscripción del asistente desde un chat embebido.

El usuario abre **Ajustes → Datos → Conecta tu IA**. ChatGPT abrirá la ficha publicada cuando esté disponible. Claude abre una guía con **Copiar instrucciones y abrir Claude**: copia un texto público y abre claude.ai para que el usuario lo pegue. Claude guía el alta del conector una vez; el chat no instala un MCP por leer una URL. La guía también ofrece acceso a Conectores, copia de URL e ID de cliente y pasos de alta sin depender del asistente. El usuario autoriza con la misma cuenta Apple/Google de Repera y elige consulta o consulta + planificación. Los cambios de historial y ejercicios personalizados mantienen aprobación nativa. Los PAT existentes continúan en Configuración manual.

## Despliegue comprobado — 2026-10-24

En producción (`uvzgujlrqohreoucirms`) se ha aplicado `ai_oauth_connections` con versión remota `20261024164612` (archivo local `20261024162744_ai_oauth_connections.sql`; misma migración, no reaplicar). Funciones ACTIVE tras esta actualización: `repera-mcp` v19, `repera-ai-tokens` v3 y `repera-ai-connect` v2, todas con autenticación propia.

Verificación HTTP real: catálogo y metadata 200; MCP sin credenciales 401 con desafío OAuth; autorización y emisión de PAT sin sesión 401. Esta comprobación inicial se realizó con los proveedores desactivados. La activación posterior del cliente público de Claude se registra abajo; no existen fichas públicas.

Web publicada en IONOS: `https://repera.app/ai/` y `console/src/core/config.js`. HTML, JS, CSS y configuración devuelven 200 y coinciden con el repositorio; CSP aplicada y página comprobada en navegador.

Con autorización explícita del propietario, se ha habilitado `repera_oauth.access_token_hook` y activado OAuth Server. Site URL: `https://repera.app`; Authorization Path: `/ai/`; registro dinámico desactivado. Se conserva `repera://auth/callback` y se añade `https://repera.app/ai/**` a los retornos permitidos. El Site URL anterior era `http://localhost:3000`.

Discovery OAuth devuelve 200, issuer esperado, PKCE S256 y endpoints de autorización/token; JWKS publica ES256. Comprobación SQL del hook en producción con entradas sintéticas: sesión nativa sin cambios, token delegado con role `repera_mcp` y audiencia MCP; `authenticator` no es miembro de `repera_mcp`. Esto no sustituye la prueba de login y refresh real.

OpenAI Platform permite entrar, pero bloquea crear/subir plugins hasta verificar la identidad del desarrollador; el propietario completará esa verificación. La publicación de Claude exige una cuenta de pago al desarrollador y se sustituye, por decisión del propietario, por la conexión personalizada. No se han enviado fichas a revisión. Pendiente: prueba completa con una cuenta real de Claude, login, lectura, refresh y desconexión, además de publicación de ChatGPT. El despliegue del backend no publica una nueva versión de iOS.

El asesor de seguridad señala RLS sin políticas en `ai_oauth_providers`: es intencional, accesible únicamente desde el backend con service role. También informa incidencias ajenas a este cambio en la vista `training_exercise_catalog`, la RPC `search_discoverable_organizations` y la protección de contraseñas filtradas; no se alteran en este despliegue.

## Claude sin publicación en el directorio

Cliente registrado y habilitado en `ai_oauth_providers` (sin `directory_url`), en Supabase Auth: `2b171bfa-ff6c-4f4f-99db-fe150b9bc834`, nombre `Claude · Repera`, **Public**, retorno `https://claude.ai/api/mcp/auth_callback`. El ID no es una credencial y no da acceso por sí mismo. El registro dinámico permanece desactivado; cada persona debe iniciar sesión y aprobar su propio permiso.

El prompt indica la URL MCP completa, OAuth, **Use your own OAuth client**, el ID público y secreto vacío. Evita las opciones de registro automático/CIMD, que este servidor no ofrece. Si las herramientas de Repera ya están disponibles, Claude debe llamar a `get_mcp_access_info` para comprobar el acceso sin leer ni alterar entrenamientos. Si no lo están, guía el formulario y solicita activar Repera en el chat. Ni copiar el texto ni abrir Claude marcan una conexión como completada.

La ayuda oficial de Claude permite un conector personalizado en Free; publicar una ficha exige un plan de pago del desarrollador. El prompt explica el límite si ya existe otro conector, sin quitarlo ni contratar planes. No se promete instalación automática, ni se envían mensajes automáticamente a Claude.

## Componentes

- `AIAccessView.swift`: catálogo remoto, guía de Claude con instrucciones públicas y apertura de fichas ChatGPT HTTPS verificadas por dominio, último uso, estado pendiente hasta primera llamada autenticada y desconexión. Refresca al volver a primer plano. Conserva acceso manual si aún no está aplicada la migración.
- `web/ai/`: consentimiento accesible, login PKCE mediante Supabase JS 2.118.0, estado en sessionStorage y autorización explícita. No escribe tokens en URLs, prompts ni localStorage. `pack-ionos.sh` incluye esta carpeta y su `.htaccess` sin caché ni referrer.
- `repera-ai-connect`: catálogo con `setup.kind=claude_prompt` e ID público solo para Claude habilitado y registrado; detalles de autorización, consentimiento y desconexión. Solo una sesión personal verificada puede autorizar o revocar. El client ID se obtiene de Auth, nunca del cuerpo enviado por el navegador. Solo clientes habilitados por el operador.
- `repera-mcp` / `_shared/ai-oauth.ts`: OAuth JWT firmado con claves asimétricas del proyecto, issuer y audiencia MCP exactos, role `repera_mcp`, propietario, client ID y sesión viva. Mantiene Bearer PAT. Publica resource metadata y desafío HTTP 401 `WWW-Authenticate`.
- Migración `20261024162744_ai_oauth_connections.sql`: proveedores, atribución OAuth en `ai_access_tokens`, hook de aislamiento y resolución del permiso contra `auth.sessions`. No almacena access/refresh tokens de OAuth. El hash de la fila de permiso es aleatorio y no tiene ningún PAT correspondiente.

## Autorización y revocación

Supabase gestiona PKCE, callbacks registrados, códigos de un uso y refresh. Los permisos deportivos se guardan en el permiso de Repera, **no** se deducen de scopes OIDC ni de `user_metadata`. Los scopes OIDC solicitados se muestran aparte en la web.

El hook `repera_oauth.access_token_hook` asigna a **todos** los JWT delegados audiencia MCP y role `repera_mcp`. Este rol no es miembro de `authenticator` y no recibe privilegios de tablas, RPC ni Storage: el MCP usa el backend con filtros de propietario existentes. **No conceder authenticated a este rol, no concederlo a authenticator ni cambiar la audiencia a authenticated.** `repera-ai-tokens` rechaza sesiones delegadas para impedir convertir OAuth en un PAT.

Desconectar revoca primero el permiso de Repera; cada llamada lo comprueba. Después elimina el grant de Supabase Auth para bloquear refresh y pedir consentimiento al reconectar. Si falla esta segunda operación, el acceso MCP sigue bloqueado; puede ser necesario quitar y añadir la integración en el asistente. La sesión Auth debe haberse creado después del permiso: una sesión antigua/refresh token no reactiva una autorización posterior. La página no sigue redirecciones de consentimiento ya consumido; ofrece reiniciar el flujo.

## Puesta en producción, en orden

1. Revisar la migración en staging y ejecutar las pruebas. Aplicar mediante el flujo de migraciones habitual; no borrar tokens ni historial.
2. Revisar si ya existe un Custom Access Token Hook. Si existe, **integrar** la lógica de aislamiento en él; no sobrescribir sus reglas. Si no existe, configurar `repera_oauth.access_token_hook` en Auth → Hooks. Requiere claves asimétricas ES256/RS256. Comprobar que la sesión nativa conserva `role=authenticated` y su audiencia actual.
3. Subir `web/ai/` junto a `web/console/src/core/config.js` a `https://repera.app/ai/`. Autorizar el retorno social `https://repera.app/ai/**`. Comprobar inicio Apple y Google con una cuenta ya existente; no crear cuentas de prueba en nombre de usuarios.
4. Configurar OAuth Server: Site URL `https://repera.app`, Authorization Path `/ai/`. **No modificar Site URL sin revisar los callbacks existentes de la consola y de iOS.** Mantener el registro dinámico desactivado: esta versión usa clientes pre-registrados.
5. Registrar clientes separados. Para Claude personalizado: cliente **público**, método de token `none`, PKCE S256 y retorno exacto `https://claude.ai/api/mcp/auth_callback`; registrar su UUID y habilitar `claude` en `ai_oauth_providers` dejando `directory_url` nulo. El ID es público y puede copiarse en el formulario, el secreto queda vacío. Para ChatGPT, obtener el retorno exacto de su portal; guardar cualquier secreto solo allí, nunca en git, iOS, web ni prompts.
6. Desplegar `repera-ai-connect`, `repera-ai-tokens` y `repera-mcp`. Los endpoints públicos y el MCP requieren `verify_jwt=false`; las funciones realizan su propia verificación. Usar el secret/service-role del proyecto únicamente en Edge. No cambiar `verify_jwt` de otras funciones.
7. Configurar las conexiones de prueba con el endpoint MCP siguiente y OAuth. Verificar descubrimiento, login, rechazo, autorización, lectura, creación de propuesta, refresh, desconexión y reconexión con dos atletas. Comprobar que los JWT del asistente NO acceden directamente a REST, RPC, Storage ni emiten PAT.
8. Enviar ChatGPT a revisión en OpenAI. Publicar Claude en Anthropic queda fuera del recorrido personalizado elegido. La aprobación y las URLs las emiten los proveedores; subir código a GitHub no realiza este paso.
9. Tras aprobación y prueba móvil real de ChatGPT, configurar `directory_url` con la ficha pública exacta. La app habilita ese botón sin otra actualización. Claude se habilita con su cliente público registrado, sin requerir ficha. Si hay restricciones de cuenta o región, documentarlas en la ficha. El enlace puede abrir web o app según el dispositivo.

### Direcciones para las fichas

- MCP: `https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-mcp`
- Protected resource metadata: `https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-mcp/.well-known/oauth-protected-resource`
- Authorization server issuer: `https://uvzgujlrqohreoucirms.supabase.co/auth/v1`
- Authorization server discovery: `https://uvzgujlrqohreoucirms.supabase.co/.well-known/oauth-authorization-server/auth/v1`
- Consentimiento: `https://repera.app/ai/`
- Privacidad: `https://repera.app/privacy`; condiciones: `https://repera.app/terms`.

Texto de ficha propuesto: **Repera — consulta tu progreso y prepara tus próximos entrenamientos.** Accede al historial deportivo sincronizado, al catálogo de ejercicios y a tu planificación. Crea propuestas para tu calendario; los cambios en entrenamientos realizados requieren confirmación en Repera. No consulta Apple Salud, sueño ni ubicación.

Ejemplos de inicio: «Revisa mis últimos entrenamientos», «Propón mi próxima semana», «Consulta mi progreso en sentadilla». En el recorrido de directorio no hace falta un prompt de instalación; Claude personalizado sí ofrece instrucciones guiadas.

## Pruebas

- `npm ci --prefix tests/oauth && npm test --prefix tests/oauth`: ejecuta la migración sobre PostgreSQL embebido (PGlite), aislamiento de roles, hook, permisos, revocación, expiración y sesiones anteriores a la reconexión.
- `deno check supabase/functions/repera-ai-connect/index.ts supabase/functions/repera-ai-tokens/index.ts supabase/functions/repera-mcp/index.ts`.
- `deno test --allow-env --allow-read tests/oauth/identity_test.ts`.
- `node --check web/ai/connect.js` y suites existentes de MCP/consola.
- Pendientes fuera de Linux: build Xcode iOS 27, login Apple/Google real, pruebas de OAuth dentro de los asistentes y publicación en sus directorios. Las pruebas unitarias no certifican estos recorridos.

## Referencias oficiales

- https://supabase.com/docs/guides/auth/oauth-server/mcp-authentication
- https://supabase.com/docs/guides/auth/oauth-server/getting-started
- https://supabase.com/docs/guides/auth/oauth-server/token-security
- https://developers.openai.com/plugins/build/auth
- https://developers.openai.com/plugins/deploy/submission
- https://claude.com/docs/connectors/building/authentication
- https://claude.com/docs/connectors/building/submission
- https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp

### Resultado de validación de esta entrega

Actualización del recorrido de Claude: 4 pruebas Deno (incluida disponibilidad del cliente y exclusión de campos privados), 4 pruebas SQL de aislamiento/consentimiento y 9 comprobaciones existentes de acceso IA correctas. Typecheck de las dos funciones modificadas correcto, con las mismas dependencias locales versionadas y el sustituto de declaraciones Edge indicado abajo. Catálogo de producción 200 con guía de Claude y ChatGPT pendiente; MCP sin credenciales 401 con discovery OAuth. Inicio OAuth real: cliente público y PKCE redirigen a `https://repera.app/ai/`; un retorno no registrado se rechaza con 400. No se ha completado todavía la autorización y llamada real desde Claude ni una compilación iOS 27.

Validación anterior de la base OAuth:

Pruebas nuevas: 4 casos SQL sobre PostgreSQL embebido y 3 casos Deno, correctos; consola web: 69 casos correctos. Typecheck de las tres Edge Functions correcto (en el entorno local se sustituyó únicamente la importación de declaraciones del runtime Edge, inaccesible desde JSR, por un módulo vacío; Deno aporta las APIs usadas). Se corrigieron dos anotaciones TypeScript preexistentes necesarias para el chequeo estricto del MCP.

Las suites históricas Python muestran 3 fallos que también se reproducen sobre el commit base: dos aserciones literales desactualizadas del MCP (filtro HYROX e import de workout) y una discrepancia de catálogo muscular (48 frente a 40). No se modifican esas funcionalidades en esta entrega.

Comprobación HTTP local: discovery público devuelve el recurso esperado y una petición MCP sin credenciales devuelve 401 con `WWW-Authenticate`. Consentimiento web comprobado en Chromium a 390 px con respuestas simuladas: sin desbordamiento horizontal ni errores JavaScript, selección solo lectura conservada, error recuperable permite reintentar y autorización inválida no muestra el formulario. No sustituye el login real ni la prueba en los proveedores.
