# Deploy Play billing verify (ops)

**Última actualización:** 2026-10-28

Código en `origin/main` (ownership Apple-parity + Edge `repera-play-billing-verify`).
Migrate/deploy **no** se ejecutan desde el agente sin token Supabase al proyecto
Repera (`uvzgujlrqohreoucirms`). **No activar** productos Play hasta verify en prod.

- Migración: `supabase/migrations/20261028173000_play_subscription_ownership.sql`
- Función: `supabase/functions/repera-play-billing-verify/`
- Detalle producto/seguridad: `android/docs/MONETIZATION_PLAY_BILLING.md`
- Bloqueadores: `android/docs/RAMON_BLOCKERS.md`

```bash
npx supabase login
# o: export SUPABASE_ACCESS_TOKEN=...

npx supabase secrets list --project-ref uvzgujlrqohreoucirms
# Esperados: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON, PLAY_PACKAGE_NAME
# Si faltan:
# npx supabase secrets set --project-ref uvzgujlrqohreoucirms \
#   PLAY_PACKAGE_NAME=com.app.repera \
#   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="$(cat path/to/sa.json)"

npx supabase db push --project-ref uvzgujlrqohreoucirms

npx supabase functions deploy repera-play-billing-verify \
  --project-ref uvzgujlrqohreoucirms
```

Después (manual): activar productos Play (hoy borrador) → smoke con JWT tester +
`purchaseToken` de test → E2E delete/restore con identidad desechable → E2E Xiaomi.
