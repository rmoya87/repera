# Repera Business — puerta de salida a producción
Última actualización: 2026-10-20. **NO APTO PARA FUSIÓN NI DESPLIEGUE DE PAGO**.

Este documento es el criterio operativo para cerrar `feat/repera-business-platform` y autorizar
`origin/main`. No confundir interfaz implementada, pruebas SQL aisladas y servicios validados
de extremo a extremo. Ninguna operación de CI o scripts locales puede declarar listo el producto
si falla alguno de estos puntos.

## Comprobaciones nuevas de Business 360
- Probar con cuentas reales separadas: registro y verificación, rol administrador, aislamiento por organización, vencimiento de prueba y elección de plan sin activación de cobro.
- Validar altas/bajas de alumnos de clase, devolución de créditos, aforo, recurrencias, modificaciones con reservas, cancelaciones y solapamientos.
- Validar permiso revocable en iOS: historia espejada solo para organización consentida y entrenador asignado; comprobar revocación, ausencia de consentimiento y acceso cruzado con cuentas distintas.
- Comprobar publicación de WOD a asistentes vinculados y avisos individuales en Ajustes iOS.
- La migración está aplicada en el proyecto real, pero **no** existe aún ningún usuario ni organización real; sin E2E no hay autorización de producción.
- IONOS: empaquetado incluye `/console/`; aún falta despliegue, configuración Auth redirect/SMTP, HTTPS, revisión de CSP, prueba de seguridad en navegador y rollback.
- Sin Stripe B2B ni activación de planes; la prueba de siete días no debe confundirse con suscripción de pago.

## Comprobaciones locales con doble clic

En un Mac con copia de la rama, abre `Repera-Verificar.command`. Ejecuta Node tests, Swift tests, el generador de canvas, XcodeGen y builds iOS/watchOS (cuando los SDK estén instalados). Escribe los registros bajo `$TMPDIR/Repera-Preflight-AAAA...`. Si falta una herramienta o falla alguna prueba, sale con error. **Incluso todos los tests locales correctos NO equivalen a autorización de merge:** faltan Auth Apple real, pagos, pruebas de concurrencia y revisión E2E. La ejecución no realiza `git push`, pagos ni cambios en Supabase.

## 1. Dependencias externas de la cuenta del propietario

| Servicio | Acción necesaria | Cómo verificar sin compartir secretos |
| --- | --- | --- |
| GitHub Actions | Diagnosticar los jobs que fallan antes de ejecutar pasos. Abrir Settings → Billing & licensing → Budgets/Actions y revisar medio de pago, presupuesto y límites de consumo; después comprobar runners/permisos del repo. La facturación bloqueada es una **hipótesis**, no un diagnóstico confirmado de esta cuenta. | Deben aparecer pasos y logs descargables; los jobs de iOS, arte, panel Business y SQL deben terminar verdes. En los intentos del 19/10 hasta el commit base de main fallan en 2–9 s sin `steps` ni logs. |
| Apple Developer / App Store Connect | Confirmar App ID `com.app.repera`, Sign in with Apple, permisos del equipo y perfiles, certificados de firma, SKU/plan Repera Pro en sandbox y acceso a TestFlight. | Login real Apple con relay privado, reinicio/restauración de sesión, login desde un segundo dispositivo; compra sandbox y restauración. **Nunca enviar claves o archivos .p8 por el chat o Git.** |
| Supabase Repera | Configurar proveedor Apple (ID Token nativo), SMTP y redirects del panel web, separar staging de producción antes de pruebas de pago. | Cuentas nuevas creadas realmente en Auth, invitación aceptada desde iOS y el panel; RLS negativa con dos tenants y tres usuarios. |
| Stripe | Conectar y verificar cuenta de Repera para B2B y estrategia Connect para pagos B2C de profesionales. Acordar productos, IVA, renovaciones y comisiones. | Webhooks de test firmados, eventos idempotentes, conciliación real sin saldo inventado; secretos guardados en gestor seguro, jamás en clientes públicos. |
| IONOS y dominio | Autorizar despliegue de `/console/` con HTTPS, CSP, rutas, rollback y variables públicas por entorno. | Pruebas navegador Safari/Chrome móvil y desktop, subida controlada de estáticos; landing actual intacta. |
| Pruebas de dispositivos | Mac/Xcode con SDK iOS 27 y watchOS 27, iPhone real y simuladores; entorno Android Studio/Gradle/Compose para Android. | Builds reproducibles, UI tests, TestFlight interno y escenarios offline. |

## 2. Funcionalidad que todavía falta implementar

- [ ] Identidad verificada y revocable en iOS/Watch y panel; cambios entre cuentas sin fugas, sesiones caducadas, MFA administrativo.
- [ ] Programación profesional completa: ejercicios, series, bloques, plantillas, 1–52 semanas, grupos, versiones, publicación/cancelación y resultados compartidos **solo con consentimiento**.
- [ ] Clases recurrentes y cancelación de clase completa; controles de aforo de sala, entrenador y múltiples sedes.
- [ ] Lista de espera real, promoción atómica, liberación de plaza, no-show y registro de asistencia.
- [ ] Productos y contratos de pago: sesiones restantes, caducidad, renovación, suspensión y cambio de plan. Repera Pro / B2B / B2C separados.
- [ ] Stripe Connect, conciliación, impuestos/documentos de cobro, reembolsos, cancelación y protección antifraude.
- [ ] Notificaciones por email y push con consentimiento, deduplicación y enlaces seguros.
- [ ] Android nativo compatible (hoy solo contratos Kotlin); paridad de funciones importantes y exportación de datos consciente de la privacidad.
- [ ] Administración de la plataforma, métricas reales, auditoría, derechos RGPD, retención, eliminación/exportación y accesibilidad.

## 3. Pruebas de aceptación obligatorias

- [ ] CI completo **verde** en la cabeza exacta del commit que se pretende fusionar; sin deshabilitar ni silenciar controles.
- [ ] `npm test` en `web/console`; `swift test` en los paquetes; compilación y UI tests iOS/watchOS.
- [ ] Aplicar las migraciones desde cero en **staging** limpio y ejecutar cada smoke SQL; todas las tablas expuestas con RLS y asesor sin riesgos críticos.
- [ ] Dos deportistas reservan simultáneamente la última plaza: una sola confirmación; idempotencia y ledger sin crédito negativo.
- [ ] Cancelar dentro/fuera de la política publicada: saldo, posible reintegro, notificaciones y auditoría coherentes.
- [ ] Invitar y aceptar desde cuentas Apple distintas, con email relay; revocar vínculo y asegurar que desaparecen accesos y datos profesionales.
- [ ] Entrenador crea plan ejecutable; aparece en Diario e Inicio, registra el atleta una sesión y solo se comparte el resultado autorizado.
- [ ] Compras B2B/B2C sandbox con casos de error, impago, duplicado, reembolso y cierre mensual.
- [ ] Pruebas de dispositivos y web, sin regresiones en `ReperaStore`, Salud, iCloud, Watch ni la versión Gratis/Pro.
- [ ] Procedimiento documentado de backup/restauración, rollout controlado y rollback.

## 4. Política de promoción

`origin/main` representa una línea estable. La existencia de una PR mergeable y una migración
aplicada **no** es autorización para presentar pagos o membresías como producción.
Para cerrar: todos los ítems críticos completados, verificables, revisados y sin dependencias
desconocidas; la PR sale de draft, pasa revisión y se fusiona. Despliegues a IONOS y TestFlight
son decisiones adicionales y no se realizan como efecto lateral de una fusión.

### Estado verificable a 19/10/2026

Siete migraciones Supabase Repera, 16 tablas públicas con RLS y cero avisos del asesor; no
hay cuentas reales de usuario ni reservas de producción. Los checks GitHub Actions de iOS y
Business siguen fallando sin pasos ejecutados. El código del panel y la integración iOS aún
necesitan ejecución E2E con proveedor Apple real. **Sin aprobación para fusionar.**
