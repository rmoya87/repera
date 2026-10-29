# Apple App Review — 29 de octubre de 2026 (Repera 1.0)

## 5.1.1(iv) — Permisos
Se ha eliminado el preintersticial de permisos del onboarding. Después del inicio de sesión se avanza directamente a los planes o a la app. La autorización nativa de Salud se solicita en «Ajustes > Salud conectada» y la de ubicación al utilizar mapas/rutas GPS. Las personas que rechazaron el permiso pueden utilizar las secciones no dependientes de ese acceso.

## 5.2.5 — WeatherKit
**La app sigue usando WeatherKit real, no datos simulados**, para la meteorología histórica de las actividades con ruta. La marca oficial combinada de Apple Weather y el enlace legal se muestran bajo las métricas en una fila visible. Si no es posible obtener la atribución, no se muestran datos meteorológicos. No se debe responder a App Review que WeatherKit está deshabilitado.

**Vídeo obligatorio que debe aportar quien tenga un iPhone físico:** abrir Repera > historial > entrenamiento con ruta > mapa y Tiempo/Humedad/Viento, mostrar la **marca oficial Apple Weather** (enlace a `legalPageURL`; sin copy custom «Fuentes y atribución legal»), abrir el enlace. Adjuntar el vídeo a la respuesta en App Review y añadir la descripción a App Review Information → Notes, como exige el rechazo.

## 2.5.4 — Audio
Se ha eliminado `audio` de `UIBackgroundModes` en el plist y en XcodeGen, conservando `location` y `fetch`. Sigue disponible el GPS en segundo plano mediante Core Location, así como las notificaciones locales de avisos cuando están autorizadas. Las locuciones de navegación son breves, no un reproductor continuo. Es obligatorio probar en iPhone real que las indicaciones y los temporizadores mantienen el comportamiento esperado con la app bloqueada; quitar `audio` puede limitar las locuciones en determinados estados de suspensión.

## Para enviar la compilación
1. Regenerar el proyecto XcodeGen y compilar los targets iOS + Watch.
2. Ejecutar pruebas de contrato Python y tests Swift y verificar la firma/entitlements del archive.
3. Probar permisos con instalación limpia, concesión y rechazo.
4. Probar clima histórico real con Internet en modos claro/oscuro y grabar la atribución.
5. Probar temporizadores, GPS y voz con pantalla bloqueada en dispositivo físico.
6. Incrementar número de build (42 → siguiente libre), subir a TestFlight y App Store Connect.
7. Responder a Apple indicando los tres cambios y adjuntando vídeo meteorológico.

**No es posible garantizar aprobación mediante pruebas estáticas; Apple debe verificar la build y el vídeo.**
