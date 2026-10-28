# Escala de ritmo de las rutas GPS

Repera interpreta el color en relación con el ritmo habitual de la propia
actividad, no según una velocidad universal ni la máxima puntual del GPS.

- Verde: tramo relativamente lento; amarillo: ritmo habitual; naranja: más
  rápido; rojo: claramente más rápido. En caminatas uniformes no se fuerza
  un gradiente completo ni aparecen tramos rojos injustificados.
- Una mediana y dos percentiles robustos (P10, P50 y P90) se calculan
  ponderando por metros recorridos, en lugar de contar muestras GPS.
  Cada tramo tiene un máximo de 30 m de peso.
- Tramos inferiores a 1 m, velocidades físicamente anómalas y tramos
  reconstruidos/estimados no se utilizan para establecer el centro. Los
  recorridos estimados siguen dibujándose discontinuos.
- La escala solo expande todo su contraste cuando P90–P10 alcanza al
  menos 0,5 km/h al caminar, 1 km/h al correr, 2 km/h en ciclismo,
  1,2 km/h en agua o 0,8 km/h en otros deportes.
- Suavizado ligero de velocidad en tramos vecinos para reducir el ruido GPS
  sin reescribir las muestras de Salud/Health Connect, el recorrido real,
  tiempos, distancia ni parciales.
- La misma fórmula y paleta existen en los dominios Swift y Kotlin:
  Packages/ReperaDomain/Sources/ReperaDomain/AdaptiveRoutePace.swift y
  android/domain/src/main/java/dev/repera/domain/AdaptiveRoutePace.kt.
  El historial y la vista en directo consumen esta escala. En iOS, la
  leyenda muestra extremos robustos y mediana en km/h, o ritmo uniforme.
- Apple Watch y Wear OS registran y sincronizan los datos, pero no tienen
  actualmente una vista de mapa de velocidad, así que no se introduce
  una pantalla nueva en el reloj.

Las pruebas de ambos dominios cubren ritmo uniforme, aceleración real,
desviación GPS y tramos estimados.
