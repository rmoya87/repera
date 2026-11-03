# Origen de los datos meteorológicos (iOS, watchOS y Android)

Última actualización: 2026-11-03.

## Regla de producto: fuentes explícitas

| Dato | iPhone / Apple Watch | Android / Wear OS |
| --- | --- | --- |
| Temperatura | **Apple Weather (WeatherKit)** | Open-Meteo |
| Humedad | **Apple Weather (WeatherKit)** | Open-Meteo |
| Viento | **Apple Weather (WeatherKit)** | Open-Meteo |
| Nevada durante la hora (cm/h) | **Apple Weather (WeatherKit)** | Open-Meteo |
| Marea, tendencia y próximo extremo | **Open-Meteo Marine** | Open-Meteo |
| Altura de oleaje | **Open-Meteo Marine** | Open-Meteo |
| Profundidad / espesor de nieve en suelo | **Open-Meteo Forecast** | Open-Meteo |

WeatherKit es el proveedor principal en dispositivos Apple. Open-Meteo se consulta **solo** para los vacíos de cobertura marinos y el espesor de nieve en suelo; la nevada (cm/h) se obtiene de `HourWeather.snowfallAmount`. No debe confundirse la caída durante una hora con la profundidad acumulada. No se inventan valores cuando un proveedor falla.

## Implementación

- `Apps/Shared/AppleWeatherConditionsClient.swift`: cliente vivo común para iOS y watchOS, WeatherKit current + hourly (nieve), fusionado con complementos Open-Meteo.
- `Apps/Repera/Sources/CardioRouteComponents.swift`: el histórico de temperatura/humedad/viento y nevada viene de WeatherKit, no de Open-Meteo; mareas/oleaje/espesor se muestran solo si existen, con su fuente.
- `Apps/Repera/Sources/LiveActivityView.swift`: refresco aproximado cada 12 minutos durante Comenzar; el snapshot se envía al reloj companion y queda asociado a la sesión guardada.
- `Apps/ReperaWatch/Sources/WatchLiveSessionView.swift` y `WatchSessionHub.swift`: sesiones autónomas del Apple Watch consultan WeatherKit directamente; los datos se guardan y se envían al iPhone por la conectividad existente.
- `Packages/ReperaDomain/Sources/ReperaDomain/ActivityConditions.swift`: `airSource` y `snowfallSource` opcionales para distinguir proveedores y recuperar sesiones antiguas. Las copias previas sin campos nuevos no se atribuyen a Apple.
- `android/`: NO modificado; continúa usando Open-Meteo.

La superficie en Apple Watch separa dos grupos: «Apple Weather» y «Open-Meteo»; en iPhone la franja del mapa identifica los proveedores y presenta por separado la nevada y las condiciones del medio. No mostrar una fuente donde no exista un dato suyo.

## Atribución obligatoria

- **Apple Weather:** `AppleWeatherAttributionView` usa `WeatherService.shared.attribution`, presenta el combined mark oficial según modo claro/oscuro y ofrece un enlace visible «Fuentes legales» hacia `WeatherAttribution.legalPageURL`. El fallback visual muestra  Weather y el enlace legal oficial; validar carga de marca oficial en iPhone y Watch físicos antes de App Review.
- **Open-Meteo:** cada grupo marino/espesor incluye «Open-Meteo»; la interfaz enlaza al proveedor y a la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). La tendencia de marea es calculada; aviso «Mareas orientativas; no usar para navegar».
- **Cumplimiento comercial pendiente de contratación:** la API **gratuita** de Open-Meteo es *solo para uso no comercial*. Repera, al incorporar suscripciones, necesita contratar/activar una licencia comercial y el endpoint autorizado, o desactivar los complementos Open-Meteo en la compilación pública. No dar por legalmente resuelto este punto por añadir la atribución. Véase https://open-meteo.com/en/terms y https://open-meteo.com/en/pricing.

## App Review 5.2.5 — pasos de validación

1. Comprobar la capacidad WeatherKit para ambos identificadores (iOS `com.app.repera` y Watch `com.app.repera.watchkitapp`) en Apple Developer y generar perfiles actualizados.
2. Compilar el mismo commit en Xcode 27, instalar en iPhone y Apple Watch físicos y verificar temperatura/humedad/viento en un entrenamiento con GPS. Para nieve verificar que nevada se atribuye a Apple y profundidad a Open-Meteo; para agua, marea/oleaje a Open-Meteo.
3. Probar modo claro y oscuro, VoiceOver, enlace al aviso legal de Apple y al de Open-Meteo. Probar ausencia de red/datos, datos históricos y sincronización del Watch.
4. Grabar un vídeo **de un dispositivo físico**: Historial → Entrenamiento con ruta GPS → mapa → franja de meteorología → marca Apple Weather → tocar «Fuentes legales». Grabar también el bloque «Condiciones» en Watch si se muestran datos WeatherKit.
5. Añadir enlace al vídeo en **App Store Connect → App Review Information → Notes**, y contestar al hilo del rechazo explicando la funcionalidad. El código por sí solo no resuelve la revisión ni aporta una grabación.
6. No afirmar que el App Review está solucionado hasta contar con compilación firmada, pruebas físicas, grabación y aprobación de Apple.

## Límites

- WeatherKit necesita conexión, entitlement y cuota disponible; no promete datos horarios ilimitados ni meteorología histórica para fechas fuera de la cobertura del proveedor.
- El snapshot de condiciones en directo puede guardar datos junto a la sesión; la franja histórica del mapa consulta WeatherKit para el lugar y fecha correspondientes.
- Mareas/oleaje de Open-Meteo son modelos aproximados y no sustituyen información náutica.
