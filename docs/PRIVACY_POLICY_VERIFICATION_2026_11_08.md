# Verificación política de privacidad — 2026-11-08

Contraste entre afirmaciones publicadas, repo (`main` local) y páginas vivas.
**No es asesoramiento legal.** Marcas `[CONFIRMAR]` requieren decisión humana.

## Contradicciones detectadas

| Tema | Repo / runtime | Página viva (antes de este cambio) |
|---|---|---|
| «Repera no opera un servidor propio que lea tu historial» | Falso si hay conexión IA (`athlete_workout_mirror`, MCP) | Afirmado en `/privacy` |
| Planes IA «con tu aprobación / las activas tú» | `AITrainingInboxStore` importa planes `pending` automáticamente | `/ia` prometía revisión/activación; `/ai/` ya matizaba cambios de entrenos completados |
| RevenueCat | Eliminado; StoreKit 2 (`AGENTS.md`, `docs/MONETIZATION.md`) | Política antigua no lo nombraba como actual; prompt lo listaba como candidato |
| Email+contraseña | UI App y `/ai/` solo Apple + Google | Prompt: habilitado en panel 8-nov — **no verificado en cliente** |

## Tabla de afirmaciones

| Afirmación | Fuente / estado |
|---|---|
| App local-first; sitio repera.app | Repo + site |
| Entrenar sin cuenta posible | Arquitectura + política previa; sin contradicción en código de onboarding forzado para diario |
| Conexión IA exige cuenta Supabase | `/ai/`, `BusinessAuthStore`, docs MCP |
| Login UI: Apple y Google | `web/ai/index.html`, App auth stores |
| Email+contraseña disponible al usuario | **[CONFIRMAR]** — no en UI revisada |
| Región servidor Supabase Repera: eu-west-1 | `docs/business/BASE_DATOS.md` (proyecto `uvzgujlrqohreoucirms`) |
| MCP `repera-mcp`: 39 tools (22 read / 17 write) | Conteo `registerTool` en `supabase/functions/repera-mcp/` (prompt decía 23/16) |
| Historial MCP sin HealthKit/GPS/notas/peso | Descripción `get_workout_history` en `index.ts` + docs |
| Planes: auto-import al abrir/sincronizar | `AITrainingInboxStore.swift` |
| Cambios entreno completado / custom exercise: aprobación en App | `AIChangeRequestStore` + nota `/ai/` |
| Revocación fiable: Ajustes → Conecta tu IA | `AIAccessView` revoke/disconnect; nota `/ai/` |
| Quitar conector en el asistente ≠ revocar Repera | Incidencia conocida (prompt + flujo disconnect) |
| Destinatario infra: Supabase | Verificado |
| Destinatarios OpenAI/Anthropic solo si el usuario conecta | Lógico/producto; no hay proxy de modelo propio |
| iCloud / HealthKit / StoreKit | Código + docs; Health «sin publicidad» conservado (sin evidencia en contra en analytics docs) |
| RevenueCat | **No** usado |
| Contacto soporte concreto | **[CONFIRMAR]** — `/soporte` sin correo |
| Retención exacta backups/logs tras delete | **[CONFIRMAR]** — `repera-delete-account` borra Auth + cascada personal; plazos infra no verificados |
| Responsable = desarrollador individual ES; menores 16+ | **[CONFIRMAR]** identidad fiscal; 16+ ya en política previa |
| Claude y ChatGPT «ya conectados» en producción | **[CONFIRMAR]** estado de publicación del conector en cada plataforma (código + OAuth docs; no equivale a ficha publicada) |

## Decisiones que necesitas tomar tú

1. **Contacto** de privacidad/soporte definitivo (email u otro canal).
2. **Identidad del responsable** (nombre/razón social para la sección 1).
3. **Email+contraseña**: ¿exponerlo en UI / política o dejarlo fuera hasta que exista en App y `/ai/`?
4. **Comportamiento planes IA**:
   - **A (actual, textos publicados):** auto-import + política/marketing lo describen.
   - **B (borrador, no publicar):** exigir aprobación previa de planes — solo cuando el código lo haga y esté verificado.
5. **Umbral de edad** en fichas de tienda (¿mantener 16+?).
6. **Plazos de borrado** de backups Supabase / GA4 a declarar (o omitir cifras hasta confirmar).
7. Estado público de conectores Claude/ChatGPT/Grok para no afirmar «conectado» si la revisión sigue pendiente.
8. Revisión profesional del texto antes de usarlo frente a OpenAI/Anthropic/AEPD.

## Entregables en repo

1. Política ES: `web/content/privacy_body.html` → `/privacy`
2. Política EN: `web/content/privacy_body_en.html` → `/privacy-en`
3. Textos `/ai/` y marketing `/ia`: variante **A**
4. Borrador variante **B**: `docs/AI_CONSENT_VARIANT_B_DRAFT.md` (**no publicar**)
5. Esta tabla

## Variante A (publicable) — resumen copy

- Planes del asistente: se importan al abrir/sincronizar.
- Cambios de entrenos completados y ejercicios personalizados: aprobación en App.
- Revocar en App, no solo en el asistente.
