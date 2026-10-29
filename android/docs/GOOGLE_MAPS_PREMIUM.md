# Google Maps para Android Premium (iOS no cambia)

## Alcance

- Gratis: MapLibre + OpenFreeMap, manteniendo el buscador Photon/Geocoder.
- Premium verificado (incluye acceso patrocinado por centro): Google Maps SDK Android como motor de visualización para Comenzar, vista previa de rutas y selección de pines del entrenamiento.
- Sin clave configurada: fallback seguro a MapLibre aunque el usuario sea Premium. No instanciar Google Map sin credenciales.
- Los GPS grabados, GPX, indicaciones y temporizadores siguen siendo lógica propia de Repera. Maps SDK dibuja las capas de ruta, posición, edificios y cámara 2D/3D.
- No se contratan Google Routes, Navigation ni Google Places con esta implementación. Buscar lugares sigue siendo Photon y el Geocoder Android; Google Places requeriría integrar otro SDK y cuotas de facturación distintas.
- iOS, watchOS y WearOS sin modificaciones.

## Activar Maps SDK en Google Cloud

1. Crear/seleccionar proyecto Google Cloud con cuenta de facturación y habilitar Maps SDK for Android.
2. Generar clave de API Android **restringida por paquete** com.app.repera y **SHA-1** de la firma de Android de debug y la de Play App Signing de producción. Restringir la clave por API a Maps SDK for Android.
3. Pasar la clave sin guardar en git a Gradle mediante la propiedad o variable de entorno REPERA_GOOGLE_MAPS_API_KEY. Ejemplo desde android/: ./gradlew :mobile:assembleDebug -PREPERA_GOOGLE_MAPS_API_KEY=TU_CLAVE
4. Configurar un secreto equivalente en CI, pasando la variable a Gradle para compilar la versión distribuida.
5. Probar en dispositivo Android real Google Play Services, con usuario Gratis y Premium reconocido por Play/backend. Verificar fase IDLE, RECORDING, REVIEW, GPX y zoom/pan/rotación (seguimiento a los cinco segundos), mapa 2D/3D y pines.
6. Configurar presupuestos y alertas de Google Cloud; una alerta presupuestaria no es un límite de gasto. Usar claves restringidas para reducir abusos.

## Arquitectura

- AndroidMapProviderChoice: solo estado Pro real + clave presente habilitan Google Maps.
- RouteMapView y PlacePinMap: conmutan el renderizador sin cambiar sus contratos de datos y navegación ni el almacenamiento.
- AndroidManifest: com.google.android.geo.API_KEY, sustituido por manifestPlaceholders en Gradle; BuildConfig.GOOGLE_MAPS_API_KEY solo indica si la clave se ha configurado.
- Documentación Google: https://developers.google.com/maps/documentation/android-sdk/config

PENDIENTE: la compilación y pruebas reales en el dispositivo deben ejecutarse tras configurar una clave, y el CI debe comprobar el nuevo SDK. No afirmar que Google Maps funciona en producción hasta entonces.
