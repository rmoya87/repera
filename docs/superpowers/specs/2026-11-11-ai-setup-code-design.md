# Conexión IA con código de 15 min (opción B)

Última actualización: 2026-11-11.

## Objetivo

Unificar Continuar (Claude/ChatGPT/Grok) y Conexión manual sin pegar la URL de Supabase ni el token largo en el prompt. Confirmación en la app; `https://repera.app/ai/?code=` solo como respaldo web.

## Decisiones

- TTL del código de setup: **15 minutos**, un solo uso (revelar token en web).
- Flujo feliz: la app crea el PAT y confirma; **no** abre `/ai/`.
- URL pública del servidor MCP: `https://repera.app/mcp` (sin secreto).
- Token Bearer se muestra en la app al crear (manual) o se obtiene en `/ai/?code=` tras login (respaldo / cuando el asistente lo pide).
- Continuar crea un token etiquetado con el asistente (lectura por defecto), mete en el prompt la URL MCP limpia + el enlace `https://repera.app/ai/?code=…` para que el usuario copie el token si el conector lo pide; no OAuth como camino principal de Continuar.
- OAuth `authorization_id` permanece en backend/web para clientes que aún lo disparen; Continuar ya no lo presenta como guía principal.
- Rediseño de `web/ai/` al lenguaje visual del site (`/assets/icon.png`, tokens de `site.css`).

## Datos

Columnas en `ai_access_tokens` (o equivalente):

- `setup_code_hash` text nullable
- `setup_code_expires_at` timestamptz nullable
- `setup_code_used_at` timestamptz nullable

Código opaco ~32 chars URL-safe; solo se almacena el hash.

## API

- `repera-ai-tokens` POST: además de `token`, devuelve `setupCode`, `setupUrl` (`https://repera.app/ai/?code=…`), `setupExpiresAt` (+15 min).
- Canje web (p. ej. `repera-ai-connect` o tokens): con sesión personal + `code` válido → una vez `token` en claro + URL MCP; marca `setup_code_used_at`.

## App

- Manual: sheet actual; tras crear, sheet/alert con MCP URL + token + enlace setup (15 min).
- Continuar: crear token → abrir chat con instrucciones actualizadas (MCP limpio + setupUrl); sin abrir Safari a `/ai/`.
- iOS + Android en el mismo cambio.

## Web `/ai/`

- Si `authorization_id`: flujo OAuth legado.
- Si `code`: login si hace falta → revelar token una vez + MCP URL, o mensaje caducado/usado.
- UI alineada al site actual.

## Fuera de alcance

- Proxy transparente de `/mcp` (sigue el 307 actual).
- Publicación en directorios ChatGPT/Claude.
- Desplegar Edge/migración sin confirmación humana explícita posterior.
