# ADR 003 — Navegación y Liquid Glass

**Estado:** aceptado · **Fecha:** 2026-10-17

## Decisión
- Tabs: `TabView` nativo + accessory Continuar.
- Flujo de sesión: overlay `NavigationStack` (preserva estado de tabs). Nested routes (editar / apuntar resultados) usan gesto de volver del sistema.
- Swipe: `swipeActions` + `swipeActionsContainer()` (iOS 27) en Inicio.
- Reorden: `reorderable(collectionID:)` + `reorderContainer` en ejercicios de bloque.
- Glass: no aplicar glass custom encima de toolbars del sistema (`appliesGlass: false` en `.toolbar`).
- Zoom biblioteca→ficha: `matchedTransitionSource` + `navigationTransition(.zoom)` respetando Reduce Motion.

## APIs iOS 27
- [swipeActionsContainer()](https://developer.apple.com/documentation/swiftui/view/swipeactionscontainer())
- [reorderable()](https://developer.apple.com/documentation/swiftui/dynamicviewcontent/reorderable())
- [matchedTransitionSource](https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource(id:in:))
- [navigationTransition(_:)](https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:))
