# Mapa nativo de ruta (HealthWorkoutRouteMap iOS) — opciones Android (24/10)

Pieza: mapa con la polilínea de la ruta GPS en el detalle de cardio del
historial (gap #2 de CAPABILITY_INVENTORY). iOS usa MapKit sin coste ni key.
Android no tiene mapa del sistema; toda opción añade dependencia + fuente de
teselas. Políticas verificadas a 24/10/2026 (URLs al final).

## Opción A — MapLibre GL Native + OpenFreeMap (recomendada, coste 0)
- Librería: org.maplibre.gl:android-sdk (Apache 2.0, mantenida por la
  comunidad MapLibre). Componente nativo real (GL), gestos, estilos.
- Teselas: OpenFreeMap — servicio gratuito también para producción, sin API
  key ni registro. TOS: servicio «as-is» sin SLA; descargas offline acotadas
  (≤3.000 teselas / 50 MB, ≤4 peticiones paralelas, User-Agent propio);
  atribución visible requerida según su guía de inicio.
- Coste: 0 €. Riesgo: dependencia de un servicio gratuito sin SLA (mitigable
  cambiando la URL de teselas/estilo, la integración no cambia).
- Encaja: detalle de historial con unas pocas teselas por vista y caché HTTP.

## Opción B — osmdroid + tile.openstreetmap.org (coste 0, uso limitado)
- Política de teselas OSMF: atribución visible obligatoria, User-Agent que
  identifique la app, caché según cabeceras HTTP (o ≥7 días), PROHIBIDO bulk
  download/prefetch/offline, y uso heavy puede ser bloqueado sin aviso; la
  propia política redirige a servicios derivados para producción.
- Encaja solo si el volumen es testimonial (una ruta en detalle, con caché).
  Riesgo de bloqueo si crece; osmdroid además es raster (menos pulido que GL).

## Opción C — Google Maps SDK (sin coste hasta umbral, requiere facturación)
- Desde el 1/3/2025 el crédito de 200 $/mes se sustituyó por 10.000 solicitudes
  gratuitas mensuales POR SKU de Core Services (Dynamic Maps incluido).
- EXIGE cuenta de facturación con tarjeta en Google Cloud: cambio de cuenta
  con compromiso potencial de cargo → requiere autorización expresa de Ramón
  (wallet-bearing). Superado el umbral, cada carga factura.

## Opción D — Canvas propio sin teselas (ya viable hoy, 0 dependencias)
- Dibujar la polilinea GPS normalizada sobre fondo neutro (sin mapa real).
  No es «mapa nativo»: sin calles ni contexto. Solo como degradado si ninguna
  opción con teselas es aceptable.

## Privacidad (precisión importante)
El array de puntos de la ruta NO se envía a ningún servicio, pero la petición
de teselas revela al proveedor la ZONA visible (bounding box) y la IP del
dispositivo: no se puede afirmar que «la ubicación nunca sale». No se
registran coordenadas en logs ni analytics, no se precargan rutas reales en
tests, y no se promete uso offline completo por una caché puntual del visor.
La atribución se muestra tanto con mapa como con el degradado.

## Recomendación
A (MapLibre + OpenFreeMap): paridad visual con MapKit, coste cero, sin key ni
facturación, producción permitida por sus TOS. B como plan de reserva con
volumen mínimo. C solo si Ramón autoriza abrir facturación en Google Cloud.
Pendiente de decisión antes de implementar (nueva dependencia + fuente de
teselas).

Fuentes (consultadas 24/10/2026):
- https://operations.osmfoundation.org/policies/tiles/
- https://openfreemap.org/tos/ y https://openfreemap.org/quick_start/
- https://developers.google.com/maps/billing-and-pricing/faq
- https://developers.google.com/maps/billing-and-pricing/pricing


## Paridad de Android con MapKit iOS: mapa gratuito (29/10/2026)

Apple/iOS no cambia. Android continúa con MapLibre + teselas OpenFreeMap;
Photon público y Geocoder cubren POI y direcciones sin claves ni facturación.
El buscador combina resultados de ambos y descarta duplicados; mantiene
el pin manual cuando el proveedor no responde. No se utiliza Google Places.

El aspecto se centraliza en ReperaMapAppearance y se aplica a rutas,
mapa de actividad y pin de ubicación. Colores inspirados en la legibilidad
de Apple Maps, sin copiar sus recursos propietarios. Claro: fondo #F6F7F5,
agua #CFE7F5, parque #DDEDD9, edificio #E6E8EA, carretera principal
#FFF0C7, texto #39464F. Oscuro: fondo #19232B, agua #294657,
parque #294235 y edificios #46525A. Las extrusiones de edificios se
activan solamente en navegación 3D, si OSM aporta geometría/altura;
en 2D se dibujan planos incluso a zoom alto. No se promete fotogrametría
ni elevación real del terreno.

Una instalación nueva empieza en 2D, conservando la preferencia si el
usuario cambia de modo. La cámara sigue rumbo GPS medido, no el final
de un GPX cargado; antes de Play utiliza sensor de orientación si existe.
Tras manipular mapa, vuelve al seguimiento 5 s desde el último gesto.
La vista Mapa/Métricas se conserva al iniciar la sesión. La guía GPX usa
banda verde, flecha y distancia sin inventar calles ni rutas recalculadas.

Limitaciones: Photon público no tiene SLA y puede limitar el volumen;
OpenFreeMap no garantiza disponibilidad. Coste de APIs contratadas = 0,
no garantía de coste operativo cero a gran escala. Mantener atribución
OpenStreetMap/OpenFreeMap. Revisión física pendiente: sensores en distintos
fabricantes, noche/día, ciudades con edificios de altura conocida, 2D/3D,
5 s de gestos y audio al bloquear la pantalla.

Refs: https://openfreemap.org/quick_start/ ;
https://maplibre.org/maplibre-native/android/examples/styling/building-layer/ ;
https://github.com/komoot/photon .
