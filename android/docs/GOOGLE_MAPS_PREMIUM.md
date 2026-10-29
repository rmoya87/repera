# Google Maps para Android (Gratis y Pro) + navegación 3D exclusiva Pro en iOS y Android

## Alcance

- Gratis: Google Maps SDK Android como motor de visualización cuando la compilación incluye la clave (decisión de 29/10: Maps deja de ser diferenciador de plan); sin clave, MapLibre + OpenFreeMap. Buscador Photon/Geocoder. Navegación 2D sin inclinación por gestos, GPX y grabación GPS sin bloqueo.
- Premium verificado (incluye acceso patrocinado por centro): mismo motor de mapas; el beneficio cartográfico exclusivo de Pro es la navegación 3D.
- Sin clave configurada: fallback seguro a MapLibre en cualquier plan. No instanciar Google Map sin credenciales.
- Los GPS grabados, GPX, indicaciones y temporizadores siguen siendo lógica propia de Repera. Maps SDK dibuja las capas de ruta, posición, edificios y cámara 2D/3D.
- No se contratan Google Routes, Navigation ni Google Places con esta implementación. Buscar lugares sigue siendo Photon y el Geocoder Android; Google Places requeriría integrar otro SDK y cuotas de facturación distintas.
- iOS mantiene MapKit como proveedor para ambos planes, pero su modo de navegación con cámara inclinada 3D ahora está restringido a Repera Pro. El mapa 2D, GPS, GPX y métricas siguen siendo gratuitos. watchOS y WearOS sin modificaciones.

## Permisos y pantallas de precios

- En ambas apps `FeatureAccessPolicy.canUse3DNavigation` comprueba el acceso Pro efectivo; no basta con una preferencia guardada de otra sesión.
- Al tocar el selector 3D se **revalida el acceso** con Play y backend antes de decidir: Pro o centro patrocinador activan 3D sin abrir pricing; Gratis confirmado puede ver la oferta; verificación indisponible muestra aviso para comprobar/restaurar compras, sin conceder acceso no verificado. Al perder Pro se vuelve a 2D. El paywall bloquea llamadas redundantes desde cualquier componente si existe Pro efectivo.
- La inclinación manual por gesto también queda bloqueada sin Pro.
- Las dos pantallas de pricing incluyen la navegación 3D como ventaja Pro. Google Maps ya no aparece como diferenciador de plan; Gratis lo comunica como mapa 2D.
- Google Maps está disponible **solo en Android**, para todos los planes. La navegación 3D es un beneficio Pro en **ambas** plataformas y puede usar MapLibre si la clave Google todavía no está disponible.

## Activar Maps SDK en Google Cloud

1. Crear/seleccionar proyecto Google Cloud con cuenta de facturación y habilitar Maps SDK for Android.
2. Generar clave de API Android **restringida por paquete** com.app.repera y **SHA-1** de la firma de Android de debug y la de Play App Signing de producción. Restringir la clave por API a Maps SDK for Android.
3. Pasar la clave sin guardar en git a Gradle mediante la propiedad o variable de entorno REPERA_GOOGLE_MAPS_API_KEY. Ejemplo desde android/: ./gradlew :mobile:assembleDebug -PREPERA_GOOGLE_MAPS_API_KEY=TU_CLAVE
4. Configurar un secreto equivalente en CI, pasando la variable a Gradle para compilar la versión distribuida.
5. Probar en dispositivo Android real Google Play Services, con usuario Gratis y Premium reconocido por Play/backend. Verificar fase IDLE, RECORDING, REVIEW, GPX y zoom/pan/rotación (seguimiento a los cinco segundos), mapa 2D/3D y pines.
6. Configurar presupuestos y alertas de Google Cloud; una alerta presupuestaria no es un límite de gasto. Usar claves restringidas para reducir abusos.

## Arquitectura

- AndroidMapProviderChoice: la clave presente habilita Google Maps en cualquier plan; sin clave, fallback a MapLibre. El acceso Pro solo gobierna la navegación 3D (FeatureAccessPolicy.canUse3DNavigation).
- RouteMapView y PlacePinMap: conmutan el renderizador sin cambiar sus contratos de datos y navegación ni el almacenamiento.
- AndroidManifest: com.google.android.geo.API_KEY, sustituido por manifestPlaceholders en Gradle; BuildConfig.GOOGLE_MAPS_API_KEY solo indica si la clave se ha configurado.
- Documentación Google: https://developers.google.com/maps/documentation/android-sdk/config

PENDIENTE: la compilación y pruebas reales en el dispositivo deben ejecutarse tras configurar una clave, y el CI debe comprobar el nuevo SDK. No afirmar que Google Maps funciona en producción hasta entonces.
