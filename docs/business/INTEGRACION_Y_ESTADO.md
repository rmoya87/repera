> **Nota de incorporación a GitHub (19/10/2026):** esta documentación describe el prototipo local v0.2. La rama `feat/repera-business-platform` ya incluye una migración base segura independiente; los scripts de `supabase/repera-greenfield/` son **propuestas no desplegadas ni compatibles automáticamente con ese esquema**. No deben ejecutarse contra Supabase sin un plan de conciliación y validación RLS real.

# Repera Business · Estado verificable y pasos para producción

Fecha 19/10/2026 · v0.2 local. **No afirmar finalización integral.**

## Decisión multiplataforma

- Web de negocio: cliente estático en IONOS, **sin procesos persistentes**.
- iOS/Apple Watch: SwiftUI 27+, datos personales y entrenamiento local-first respaldados por iCloud, sin sobrescribirlos desde la gestión del gimnasio.
- Android futuro: cliente nativo Kotlin/Compose, Room y respaldo de Google/Android. **iCloud y la copia Google NO sincronizan entre sí**: si se requiere transferir historiales personales de iOS a Android será necesario un mecanismo explícito de exportación/importación o consentimiento para sincronización selectiva en Supabase. No suponer portabilidad automática.
- Supabase separado: relaciones negocio/deportista, programación publicada, reservas, centros, permisos, precios y pagos. Los historiales deportivos personales permanecen privados salvo compartición autorizada.
- Una única identidad profesional/atleta de Supabase (email/OAuth Apple verificado); Sign in with Apple en Keychain no constituye un token backend.

## Alcance implementado v0.2

| Componente | Función | Validación |
|---|---|---|
| Web estática | 13 apartados: dashboard, clientes, programas, grupos, agenda, clases, operaciones, tarifas, cobros, analíticas, notificaciones, equipo, ajustes, más admin por rol demo | Tests renderizado Node |
| Clientes y grupos | altas, edición, pertenencia y asignación grupal | Unit tests |
| Programas | 7 días, 1-52 semanas, asignaciones independientes, excepciones de un día, avisos locales | Unit tests |
| Clases | sesiones, recurrencias semanales (hasta 52), aforo, bloqueo de colisiones sala/coach | Unit tests |
| Reservas y asistencia | reserva, lista de espera, promoción, cancelación de clase, devolución de créditos, asistencia/falta | Unit tests |
| Bonos y cobros | ventas simuladas, activación manual de pendiente, movimiento de saldo e importe, CSV, borradores | Unit tests |
| Integración móvil | contrato JSON v1, Swift Codable y Kotlin tipado + merge independiente del histórico | XCTest, Kotlin y tests Node |
| Backend SQL | 0001 entidades y RLS; 0002 funciones de reserva/cancelación e idempotencia; outbox, notas privadas y scopes por coach | Sólo tests estáticos. **FALTA prueba PostgreSQL real** |
| Transport cliente | Supabase REST y RPC autenticados, con lista blanca y paginación | Tests mock. No integrado |

## Bloqueos técnicos de salida a producción

1. **Crear proyecto Supabase Repera independiente**: comprobar que admite plan gratis, región UE, alta de organización Repera. No crear en Cafesito ni ejecutar SQL con producción.
2. **Desplegar esquema en entorno de ensayo**: reemplazar la migración antigua de permisos globales; ejecutar 0001 y 0002; probar que toda tabla expuesta tiene RLS; probar intentos maliciosos (usuarios en 2 centros, coach sin cliente, billing sin notas, atleta sin vínculo, admin simulado), y concurrencia de 50 reservas para cupo 5 con `pgTAP` o integración real.
3. **Habilitar Supabase Auth**: email link + Apple OAuth web y signInWithIdToken en iOS, nonce correcto; MFA para finanzas; sesión persistida segura y logout efectivo.
4. **Integrar frontend real**: eliminar selector de roles demo cuando conecte; RLS y servidor serán la fuente de autorización; separar modo demo de modo conectado; errores, indicadores de sincronización y estrategia offline.
5. **Enlaces y consentimientos**: invitación emitida por backend, aceptada por el propio atleta; enlaces de cliente/rol con verificación; sin transferencia de datos HealthKit sin consentimiento explícito. Revocación efectiva.
6. **Funciones atómicas**: revisar y probar SQL book_class/cancel_class_booking; completar checkout, cambios de tarifas, congelaciones, reembolsos, no-show, prorrateos, clases recurrentes y migración de usuarios.
7. **Stripe**: conectar cuenta por negocio, configurar webhooks con firma sobre raw body y eventos idempotentes, Billing independiente para cuotas que Repera cobre (pricing pendiente), conciliación, fallo/cancelación, devoluciones y antifraude.
8. **Fiscal**: proveedor legalmente compatible con España, datos fiscales, series por emisor, rectificativas, exportación y retención; no convertir borradores demo en facturas reales.
9. **APNs/FCM**: registrar token por dispositivo, preferencias, control de duplicados, enlaces de destino con autenticación de usuario, outbox + reintentos y pruebas de entrega.
10. **iOS**: integrar BusinessAgendaStore no bloqueante, Sign in with Apple → Supabase Auth, deep links, publicar cambios de Hoy/Diario sin perder historial. Pruebas en dispositivo/TestFlight.
11. **Android**: proyecto Gradle/Compose + Room, login seguro, planes, reservas, resultados y sincronización; pruebas dispositivo.
12. **Release**: gestión RGPD con DPA, consentimiento, privacidad de menores, copias recuperables, rendimientos, accesibilidad WCAG, E2E y seguridad de secretos, despliegue IONOS controlado, CI y rollback. El pricing B2B continúa sin fijar.

## API JSON de agenda — contrato compartido

```json
{
  "schema_version": 1,
  "org_id": "uuid del centro",
  "client_id": "uuid de ficha",
  "cursor": null,
  "events": [{
    "id": "uuid o id determinista de evento",
    "kind": "training",
    "date": "2026-10-19",
    "title": "Fuerza",
    "source": "professional",
    "assignment_id": "uuid de asignación",
    "booking_id": null,
    "exercise_text": "Sentadilla 3x8",
    "deep_link": "repera://diary/uuid"
  }]
}
```

Para `kind: class`, `booking_id` es el ID de la reserva y el enlace va a `repera://classes/{classId}`. El UUID estable proviene del servidor; el ejemplo local usa identificadores ficticios para pruebas. La app móvil almacenará este overlay aparte y los entrenamientos terminados permanecerán bajo control del deportista.

## Contratos nativos verificados

- Swift package `mobile-contracts/swift`: `BusinessAgendaEvent`, `BusinessAgendaResponse`, `BusinessAgendaMerger`. XCTest valida JSON, actualizaciones y rechazo de enlaces externos.
- Kotlin `mobile-contracts/android`: mismo modelo y tipos, `mapAgendaEvent` para objetos JSON decodificados y merge por ID. Comprobado con `kotlinc` y JVM; **no** equivale a una compilación Android con Gradle/Emulador.
- `web/console/src/core/mobile-contract.js` convierte un calendario simulado al mismo wire format en `snake_case`.

## Seguridad: límites de lo probado

Pruebas Node y tests estáticos SQL **no demuestran** seguridad de PostgreSQL RLS, consistencia concurrente, autenticación real, cumplimiento tributario ni envío push. Los scripts 0001/0002 se consideran candidatas a despliegue tras auditoría, no una base validada en producción. El selector «Ver como» solo es de demo.

## Qué significa realmente «completo»

Una entrega se podrá declarar completa únicamente cuando funcione el ciclo real desde un gimnasio, entrenador y atleta: registro y permisos reales → tarifa y cobro reales → reserva segura → notificación en móvil → apertura de Diario/Hoy y registro de resultados → datos sincronizados y privados → factura legal → informes que concilian, incluyendo fallos, reembolsos, desconexión, cambios de zona horaria y acceso revocado; con CI y revisión fiscal/de seguridad satisfechas. **Ese hito no se ha alcanzado.**