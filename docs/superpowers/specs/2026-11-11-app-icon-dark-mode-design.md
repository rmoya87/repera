# App Icon Dark Mode — Design

Última actualización: 2026-11-11.

## Goal

En modo noche del sistema, el icono de la app en la pantalla de inicio pasa de fondo verde de marca a negro puro, manteniendo la misma mascota 3D. Paridad en iPhone, Apple Watch, Android y Wear OS.

## Decisions

- Enfoque: nativo por plataforma (no regenerar todos los mipmaps legacy).
- Visual: misma mascota; solo el fondo cambia de `#30D158` a `#000000`.
- Solo modo noche / apariencia oscura del sistema. No permanente.
- Fuera de alcance: variante tinted iOS, splash/launch screen, favicon web, complicaciones Watch, cambios de UI in-app.

## Apple (iPhone + Watch)

### Current state

- `Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/` — un único `AppIcon.png` 1024×1024, `pre-rendered`, sin apariencias.
- Watch reutiliza el mismo PNG canónico (`Apps/ReperaWatch/.../AppIcon.appiconset/`).

### Change

1. Generar `AppIcon-Dark.png` (1024×1024) desde el PNG canónico: sustituir el verde de marca del fondo por `#000000` sin alterar la mascota.
2. Registrar en `Contents.json` de iPhone y Watch una entrada con:
   - `appearances: [{ appearance: luminosity, value: dark }]`
   - `filename: AppIcon-Dark.png`
   - mismo `idiom` / `platform` / `size` que el asset claro.
3. El asset claro (`AppIcon.png`) no se modifica.
4. Mantener `pre-rendered: true`.

### Generation

- Script reproducible (p. ej. extensión de tooling de iconos existente o script dedicado) que:
  - lea el AppIcon canónico,
  - detecte el verde de fondo (tolerancia alrededor de `#30D158`),
  - escriba el dark PNG en ambos appiconsets (o copie el mismo digest a Watch).
- Preferible un solo artefacto fuente + copia idéntica a Watch para no divergir.

## Android + Wear

### Current state

- Adaptive icons: `background` = `@color/ic_launcher_background` (`#FF30D158`), `foreground` = mascota.
- Mismos patrones en `android/mobile` y `android/wear`.
- No existe `values-night` para ese color.

### Change

1. Añadir `android/mobile/src/main/res/values-night/colors.xml` con `ic_launcher_background = #FF000000`.
2. Añadir el mismo override en `android/wear/src/main/res/values-night/colors.xml`.
3. Claro permanece `#FF30D158` en `values/colors.xml`.
4. No regenerar mipmaps legacy precomposados (API < 26 / fallback); el cambio de noche aplica al adaptive.

### Nota de launcher

Algunos launchers Android cachean el icono; puede hacer falta reinicio del launcher o reinstalación para ver el cambio. No es un bug de la app.

## Testing / contracts

- Contrato Python (nuevo o ampliación):
  - Contents.json iPhone y Watch declaran apariencia `dark` + archivo `AppIcon-Dark.png` presente.
  - Digests de `AppIcon-Dark.png` iPhone ↔ Watch idénticos.
  - `values-night/colors.xml` mobile y wear definen `ic_launcher_background` negro.
  - Claro sigue `#30D158` / `#FF30D158`.
- Actualizar aserciones que asumen un solo PNG en el appiconset (p. ej. healthkit/watch contracts) sin romper la igualdad del asset claro canónico.
- Manual: home screen claro vs oscuro en iOS y Android.

## Docs

Tras implementar: `docs/ARCHITECTURE.md` (launcher icon) y nota breve en `docs/FEATURES.md` si aplica; fecha de actualización.

## Non-goals

- Icono tintado / tinted appearance de iOS.
- Cambiar splash verde de launch.
- Forzar fondo negro en modo claro.
- Paridad visual idéntica de mipmaps legacy API < 26 en noche.
