# Plan: código setup IA 15 min + rediseño `/ai/`

Última actualización: 2026-11-11.

Spec: `docs/superpowers/specs/2026-11-11-ai-setup-code-design.md`.

## Archivos

- `supabase/migrations/20261111180000_ai_setup_code.sql`
- `supabase/functions/repera-ai-tokens/index.ts`
- `supabase/functions/repera-ai-connect/index.ts`
- `web/ai/*`
- `Apps/Repera/Sources/AIAccessView.swift`
- `android/.../AIProviderLaunch.kt`, `AIAccessStore.kt`, `AIAccessScreen.kt`
- `tests/test_ai_provider_launch_contract.py` (+ contrato setup code)
- `docs/FEATURES.md`, `docs/OAUTH_CONNECTIONS.md`, `AGENTS.md` lección breve si aplica

## Orden

1. Migración columnas setup (sin GRANT a authenticated del ciphertext).
2. Tokens: emitir setupCode + cifrar reveal; connect: acción `redeem-setup`.
3. Web `/ai/` rediseño + flujo `code`.
4. iOS/Android Continuar crea token y mete setupUrl en instrucciones; manual muestra MCP + token + setupUrl.
5. Contratos + docs.
