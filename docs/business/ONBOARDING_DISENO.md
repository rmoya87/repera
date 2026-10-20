# Onboarding y mascota · revisión 2026-10-20

La UI atleta usa tokens `OG*` **adaptativos** (día/noche según el sistema). La pantalla de **bienvenida y acceso Apple** sigue siendo excepción intencionada (canvas negro con textos blancos); permisos y planes usan el mismo tema adaptativo que el resto de la app.

El flujo para nuevas instalaciones es Apple → permisos de notificaciones / Apple Salud / ubicación (opcionales) → selección de plan (Gratis o Pro) → Inicio. Nunca se activa el `PaywallCoordinator` modal desde el paywall *inline* de onboarding, porque la transición al Inicio hacía aparecer una segunda pantalla de precios. El estado persistido v1 se migra de forma que un usuario que ya pasó por la pantalla de planes no vuelva a verla tras continuar los permisos.

Los cuatro PNG de `MascotWelcome`, `MascotPermissions`, `MascotHero` y `MascotWatch` se han reparado en la rama usando `scripts/repair_mascot_alpha.py`: rellena **únicamente islas pequeñas de píxeles transparentes rodeadas por dibujo opaco**, utilizando el color más frecuente de su borde. El área transparente exterior se preserva; no se redibuja la forma del personaje. La reparación determinista ha confirmado píxeles opacos nuevos. Se recomienda comprobación visual manual en dispositivo real para descartar diferencias de percepción en la cinta.

Estas verificaciones estáticas son un contrato de regresión; además deben pasar iOS 27 CI y las pruebas reales de compra StoreKit en entorno de prueba.
