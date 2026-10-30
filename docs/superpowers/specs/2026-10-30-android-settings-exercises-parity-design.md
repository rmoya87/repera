# Android Ajustes + Ejercicios — paridad UI con iOS

**Fecha:** 2026-10-30  
**Estado:** aprobado; implementación en curso (2026-10-30)  
**Alcance:** app Android (`android/mobile`), no Wear  
**Fuera de alcance:** widgets, Wear, E2E OAuth real, compras Play reales en producción

## Objetivo

Igualar disposición y comportamiento visible de Ajustes y biblioteca de ejercicios Android con iOS, respetando APIs nativas Android (permisos, Health Connect, Play Billing) donde el SO lo exige.

## Orden de implementación

1. Inset inferior global (contenido encima del menú)  
2. Topbar global (componente compartido)  
3. Cuenta  
4. Salud + Objetivos  
5. Entrenamiento (historial, pickers)  
6. Ejercicios + detalle  
7. Acceso / billing + debug  
8. Centro («Buscar» sin chevron)  
9. Docs `android/docs/STATUS_AND_PARITY.md` (+ README si hace falta)

## 0. Contenido por encima del menú principal (toda la app)

- El scroll/contenido de **todas** las pestañas y pantallas bajo el `Scaffold` principal **no debe quedar oculto** detrás de `ReperaFloatingTabBar`.
- El contenido termina **justo encima** del menú flotante (último ítem visible y alcanzable sin tapar la tab bar).
- Solución preferida: un único inset inferior en el host (`ReperaMobileScreen` / `Scaffold` `padding` / `contentPadding` del nav) basado en la altura real de la floating tab bar + `navigationBars`, de modo que las pantallas hijas hereden el hueco sin hardcodear 72 dp sueltos en cada lista.
- Pantallas a pantalla completa que **ocultan** la tab bar (live workout, reloj WOD, paywall a pantalla completa, etc.) no añaden ese inset de menú; solo respetan system bars si aplica.
- Revisar listas con `contentPadding` propio para que sumen el inset del host y no lo anulen a cero.

## 1. Topbar

- Unificar botones de toolbar vía `ReperaToolbarGlassIconButton` (o renombrar si deja de ser “glass”).
- Círculo sólido: **blanco en light / negro en dark**.
- Sin alfa gris/`surfaceVariant` ni degradados a gris.
- Icono **24 dp** (Material toolbar); touch target **48 dp**; círculo visible **44 dp**.
- Sustituir `IconButton` + fondos grises en pantallas de Ajustes, detalle de ejercicio, Acceso IA, etc. que usen el patrón topbar.

## 2. Cuenta (`ProfileSettingsSection`)

- Padding horizontal de la fila de cuenta (icono no pegado al borde izquierdo de la card).
- Badge inferior: **logo Google** (asset/vector oficial), no letra «G».
- Avatar: foto de perfil Google de la sesión cuando exista; si no, JPEG de perfil local; si no, placeholder.
- Email y «Cerrar sesión»: menos espacio vertical (padding/spacing reducidos; «Cerrar sesión» pegado al email).

## 3. Centro y entrenador

- Fila «Buscar»: `showChevron = false` en `SettingsListRow` (sigue siendo clicable).

## 4. Acceso

- Mantener estructura alineada a iOS Settings «Acceso»:
  - Patrocinado por centro / Pro activo / Free + Descubrir Pro
  - Comprobar acceso Pro, Restaurar compras
  - Conecta tu IA → `AIAccessScreen`
- Copy y acciones adaptadas a Play (gestionar suscripción vía Play Store / URL comercial Android si ya existe).
- **Debug Pro (solo `BuildConfig.DEBUG`):**
  - Toggle «Simular suscripción»
  - Picker de `SubscriptionStatus` (free, trial, proMonthly, proAnnual, grace, expired, revoked, unknown)
  - Toggle «Simular offline» si el manager lo soporta o stub local
  - Reset cuota escáner si existe equivalente Android
- Portar patrón iOS `DebugEntitlementController` a Kotlin (override local que `SubscriptionManager` respete antes de Billing).
- IA: sin cambio de arquitectura; tokens + inbox; cambios de entrenos aparecen tras decidir/aplicar.

## 5. Salud

- Notificaciones: estado real `NotificationManagerCompat`; en API 33+ request `POST_NOTIFICATIONS`; si denegado o ya decidido → Ajustes del sistema.
- Ubicación: request fine/coarse; si denegado → Ajustes.
- Salud: Health Connect (no Apple Salud); CTA «Conectar con Salud» / estado de lecturas; abrir flujo HC existente.
- Objetivos (`HealthGoalsSection` / pantalla `ajustes-objetivos`): cada fila **icono + texto a la izquierda, campo numérico a la derecha** (no `OutlinedTextField` full-width con label flotante apilado). Secciones diarios / semanal / corporal como ahora.

## 6. Entrenamiento

- «Historial» navega a lista completa de entrenamientos hechos (`CompleteHistoryScreen` o equivalente ya cableado); al abrir un ítem, Volver regresa a esa lista; Volver desde la lista a Ajustes.
- Quitar de Ajustes (y del flujo asociado desde esta sección) la entrada «Deporte · evolución y récords» si aparece en el stack de Entrenamiento/historial de ajustes.
- Pickers Unidad / Semana empieza / Esfuerzo: menú anclado **debajo del campo** (`DropdownMenu` con `offset`/`ExposedDropdownMenu` anclado al row), no desplazado a la izquierda de la pantalla.

## 7. Biblioteca de ejercicios

- Buscador: fondo **blanco en light** (surface blanco / `Color.White`); en dark, surface del tema oscuro sólido (no gris translúcido raro).
- Listado: patrón Material 3 nativo — filas de lista / secciones con títulos; evitar card anidada que envuelva cada sección completa si iOS usa lista plana con separadores.
- Modal de filtros: **pantalla completa** (o sheet expandido al máximo); eliminar el recuadro que agrupa todas las subsecciones; **HorizontalDivider** entre bloques (Filtro / Ordenar / etc.).

## 8. Detalle de ejercicio (`ExerciseDetailScreen`)

Orden de bloques (fijo):

1. Título (tras toolbar)  
2. Carrusel/imagen + descripción que acompaña  
3. Cómo hacerlo  
4. Músculos y equipo  
5. Carga sugerida (solo si el ejercicio la tiene / no movilidad)  
6. Evolución: métricas top (1RM, max, e1RM, reps max, veces, top serie, 1RM est, esfuerzo), gráfica con rangos **1m / 3m / 1a / Todo**, debajo mejor serie / última / historial  

Hoy la evolución aparece **antes** de descripción/cómo hacerlo; hay que **reordenar**. Toolbar del detalle usa botones circulares del §1.

## Criterios de aceptación

- Con la tab bar visible, el final del scroll de Inicio / Progreso / Ejercicios / Ajustes (y subpáginas con menú) queda **por encima** del menú; nada importante queda tapado detrás.
- En light/dark, iconos de topbar son círculos blancos/negros sin degradado gris.
- Cuenta: padding, logo Google, avatar de sesión, email/cerrar sesión compactos.
- Buscar centro sin flecha derecha.
- Acceso: opciones Play + sección Debug visible solo en debug; override de status cambia UI Pro sin compra real.
- Salud: permisos Android coherentes; Objetivos icono+texto | input.
- Historial desde Entrenamiento muestra sesiones y back stack correcto; sin «Deporte evolución y récords» en esa sección; dropdowns bajo el campo.
- Buscador ejercicios fondo blanco (día); filtros full-screen con divisores; detalle en el orden §8.

## No hacer

- No meter API keys LLM cloud.
- No reintroducir «+ Plan» en lista de ejercicios.
- No asumir backend social nuevo.
- No commit de secrets / Maps keys.

## Archivos principales tocados (orientativo)

- `ReperaMobileScreen.kt`, `ReperaFloatingTabBar.kt` — inset inferior global  
- `ReperaComponents.kt` — toolbar  
- `ProfileSettingsSection.kt`, `SettingsTab` en `ReperaMobileScreen.kt`  
- `PermissionSettingsSection.kt`, `HealthGoalsSection.kt`  
- `TrainingSettingsSection` / pickers en Settings  
- `CompleteHistoryScreen.kt`, rutas nav  
- `ExercisesTab.kt`, filter sheet  
- `ExerciseDetailScreen.kt` + sección evolución  
- `monetization/SubscriptionManager.kt` + nuevo debug controller  
- `android/docs/STATUS_AND_PARITY.md`
