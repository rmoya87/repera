# Android Ajustes + Ejercicios parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline in this session). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Alinear UI de Ajustes, biblioteca de ejercicios y chrome (tab bar / topbar) de Android con iOS según `docs/superpowers/specs/2026-10-30-android-settings-exercises-parity-design.md`.

**Architecture:** Cambios de UI Compose en `android/mobile`; override de entitlements solo en `BuildConfig.DEBUG`; inset inferior único vía `Scaffold` + altura de `ReperaTabBarChrome`.

**Tech Stack:** Kotlin, Jetpack Compose Material3, Play Billing, Health Connect, Credential Manager / Google Sign-In.

## Global Constraints

- iOS 27+ / Android target del proyecto; sin API keys LLM cloud.
- Docs vivos: actualizar `android/docs/STATUS_AND_PARITY.md` al cerrar.
- Commits solo si el usuario lo pide.
- Spec: `docs/superpowers/specs/2026-10-30-android-settings-exercises-parity-design.md`.

---

### Task 0: Inset inferior encima del menú

**Files:**
- Modify: `android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt` (Scaffold host)
- Modify: `android/mobile/src/main/java/dev/repera/mobile/ReperaFloatingTabBar.kt` (medir/exportar altura si hace falta)
- Modify: listas con `contentPadding` que anulen el hueco (Inicio/Progreso/Ejercicios/Ajustes/Historial)

- [ ] **Step 1:** Confirmar que `Modifier.padding(padding)` del Scaffold aplica cuando `showTabBar`; excluir solo rutas full-bleed (`en-vivo` mapa, shells ocultos).
- [ ] **Step 2:** Si el bottomBar transparente no reserva espacio, forzar altura mínima o `WindowInsets` explícitos equivalentes a tab + nav bars.
- [ ] **Step 3:** Verificar scroll: último ítem de Ajustes/Ejercicios queda por encima de la píldora.

### Task 1: Topbar circular día/noche

**Files:**
- Modify: `android/mobile/src/main/java/dev/repera/mobile/ReperaComponents.kt` (`ReperaToolbarGlassIconButton`)
- Modify: pantallas con `IconButton` + fondo gris (`ExerciseDetailScreen`, `AIAccessScreen`, historial, etc.)

- [ ] Fondo círculo: blanco light / negro dark; icono 24 dp; sin alfa gris.
- [ ] Sustituir usos topbar relevantes por el componente unificado.

### Task 2: Cuenta

**Files:**
- Modify: `ProfileSettingsSection.kt`
- Modify: `SessionStore.kt` / sign-in en `MainActivity.kt` (persistir `profilePictureUri` de Google si falta)
- Create: `android/mobile/src/main/res/drawable/ic_google_g.xml` (logo)

- [ ] Padding horizontal en card; badge Google; avatar Google → local → placeholder; email/cerrar sesión compactos.

### Task 3: Centro Buscar sin chevron

**Files:**
- Modify: `ReperaMobileScreen.kt` `SettingsListRow` Buscar → `showChevron = false`

### Task 4: Salud + Objetivos

**Files:**
- Modify: `HealthGoalsSection.kt` (filas icono+texto | input)
- Modify: `PermissionSettingsSection.kt` / `SettingsHealthRows` si el flujo de permisos falla

### Task 5: Entrenamiento

**Files:**
- Modify: `CompleteHistoryScreen.kt` (quitar fila Deportes)
- Modify: `SettingsDropdownPickerRow` (menú anclado bajo el campo, `Box(Modifier.fillMaxWidth())` + offset)

### Task 6: Acceso Debug Pro

**Files:**
- Create: `android/mobile/src/main/java/dev/repera/mobile/monetization/DebugEntitlementController.kt`
- Modify: `SubscriptionManager.kt` para respetar override
- Modify: `SettingsTab` sección Debug si `BuildConfig.DEBUG`

### Task 7: Ejercicios lista + filtros

**Files:**
- Modify: `ExercisesTab.kt` (buscador fondo blanco)
- Modify: `ExerciseFilterSheet.kt` (full screen; divisores; sin cards envolventes)
- Revisar listado Material (secciones + filas)

### Task 8: Detalle ejercicio orden + evolución

**Files:**
- Modify: `ExerciseDetailScreen.kt` — orden: título → arte+desc → cómo → músculos → carga → evolución
- Toolbar con botones circulares; tiles evolución (top 1RM, max, e1RM, …) + rangos 1m/3m/1a/todo

### Task 9: Docs

**Files:**
- Modify: `android/docs/STATUS_AND_PARITY.md` (fecha + bullets de paridad UI)

---

## Spec coverage

| Spec § | Task |
|--------|------|
| 0 Inset menú | 0 |
| 1 Topbar | 1 |
| 2 Cuenta | 2 |
| 3 Centro | 3 |
| 4 Acceso+Debug | 6 |
| 5 Salud/Objetivos | 4 |
| 6 Entrenamiento | 5 |
| 7 Ejercicios | 7 |
| 8 Detalle | 8 |
| Docs | 9 |
