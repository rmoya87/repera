# BORRADOR — no publicar

**Variante B** de textos de consentimiento / marketing IA.

Solo sería verdadera si el producto **deja de auto-importar** planes de `ai_training_plans` y exige aprobación expresa en la App **antes** de guardar la rutina local — y ese comportamiento está verificado en dispositivo.

Estado actual (nov-2026): `AITrainingInboxStore` importa planes pendientes automáticamente. Publicar este texto hoy sería **falso**.

## Copy tentativo (ES)

- «Los planes que proponga tu asistente llegarán a Repera como solicitudes. Solo se añadirán a tu diario cuando los apruebes en la App.»
- «Ningún plan se activa solo al abrir o sincronizar.»

## Copy tentativo (EN)

- “Plans your assistant proposes arrive in Repera as requests. They are added to your journal only after you approve them in the App.”
- “No plan activates merely because you open or sync the App.”

## Checklist antes de publicar B

- [ ] Código: bandeja de planes requiere aprobación (sin `saveRoutine` automático).
- [ ] Prueba en dispositivo: Claude/ChatGPT + sync sin importar hasta aprobar.
- [ ] Actualizar política §§9.3 ES/EN, `/ai/`, `/ia` y FAQ.
- [ ] Quitar o archivar esta marca de borrador.
