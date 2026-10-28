package dev.repera.mobile

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** Apple fafe016a/26a625be: velo oscuro bajo la ruta (aboveRoads) y trazo en
 *  3 capas halo/edge/core por encima (aboveLabels) dentro del renderer
 *  MapLibre aprobado. Contrato de cableado sobre el codigo del renderer; el
 *  orden visual real en el mapa queda para validacion runtime. */
class RouteMapLayersContractTest {
    private val src = File("src/main/java/dev/repera/mobile/RouteMapView.kt").readText()

    @Test fun darkBackdropBeneathRoute() {
        assertTrue(src.contains("\"route-backdrop\""))
        assertTrue(src.contains("PropertyFactory.fillOpacity(0.33f)"))
        // Padding del rectangulo como Apple: max(0.06, span*4) por eje.
        assertTrue(src.contains("maxOf(0.06, (maxLat - minLat) * 4)"))
        assertTrue(src.contains("maxOf(0.06, (maxLon - minLon) * 4)"))
    }

    @Test fun threeLayerStrokeWithAppleWidthsAndOpacities() {
        assertTrue(src.contains("floatArrayOf(4f, 2.25f, 1.4f)"))
        assertTrue(src.contains("floatArrayOf(0.23f, 0.75f, 1f)"))
        assertTrue(src.contains("route-line-halo") && src.contains("route-line-core"))
        // Estimados discontinuos en las 3 capas (dash 4pt absoluto relativo al ancho).
        assertTrue(src.contains("arrayOf(4f / widths[i], 4f / widths[i])"))
    }

    @Test fun insertionOrderPutsBackdropBeneathStroke() {
        val backdrop = src.indexOf("addLayer(org.maplibre.android.style.layers.FillLayer")
        val stroke = src.indexOf("fun strokeLayers")
        assertTrue(backdrop in 1 until stroke)
        // La recomposicion retira backdrop, capas de trazo y estimadas (sin duplicados).
        assertTrue(src.contains("route-line-est-halo-"))
        assertTrue(src.contains("\"route-backdrop-src\""))
    }
}
