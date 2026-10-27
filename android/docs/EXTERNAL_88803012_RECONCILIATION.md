# Reconciliacion del commit externo 88803012 (adaptive right pane) · 26oct2026

Commit externo (rmoya87, 26oct 00:38) "Android adaptive right-pane UX for tablet and foldable": solo tocaba
ExercisesTab.kt y ReperaMobileScreen.kt. El arbol local ya tenia trabajo propio en esos ficheros, asi que se
registro como ancestro con `merge -s ours` (conserva el commit, no su comportamiento) y se reconcilio por partes.
Referencia Apple: fc3ef7e1ad850818f463133122fead864c201701 (lectura de Swift, no se toco Apple).

| Parte externa | Decision | Evidencia |
|---|---|---|
| Umbral `screenWidthDp >= 600` | Se mantiene el local: ancho de contenido >= 620dp (`adaptiveCardColumns`) | Apple HomeView/LibraryView/HealthRecovery usan `onGeometryChange { $0.size.width >= 620 }` |
| Panel de ajustes a la derecha con slide 280ms | Local ya tenia panel (TrailingColumnPanel, scrim, medio ancho, BackHandler). Se anade slide desde el borde trailing y fade del scrim; sin animacion de salida | Apple Theme.swift ogTrailingColumnPanel: scrim `.opacity` 0.10, panel `.move(edge:.trailing)`, ancho = mitad |
| Editor de rutina en panel derecho desde Inicio | Integrado (commit 8f3bc385) reutilizando guards/draft/cuenta locales | Apple HomeView usa ogTrailingColumnPanel para ajustes; para rutina no se ha verificado equivalente Apple: parte externa conservada por intencion del commit, no por evidencia Apple |
| Biblioteca de ejercicios lista+detalle, "Selecciona ejercicio" | Local ya lo tenia (selectedExerciseId, library_split) | ver ExercisesTab.kt |
| Iconos favorito y "apuntar" sobre el detalle | Favorito (estrella) anadido al detalle, local y ruta compacta; "Apuntar ejercicio" ya existia como boton | Apple ExerciseDetailView.swift:418-440 toolbar: estrella y "Apuntar ejercicio" (+) |
| Titulo "Ejercicios" headlineLarge | Aplicado (antes "Biblioteca" headlineMedium) | Apple LibraryView navigationTitle "Ejercicios" |

Sin comprobacion UI, pixeles ni dispositivo. Las diferencias restantes (sin animacion de salida del panel,
detalle compacto: estrella como icono en el cuerpo y no en la barra) siguen abiertas.
