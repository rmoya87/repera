package dev.repera.mobile

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** Apple 9d4037b8: polilinea unica por tramo continuo con gradiente conectado
 *  por distancia (lineMetrics+lineGradient) y esquinas suavizadas (join/cap
 *  round). Contrato de cableado sobre el renderer; el degradado visual real
 *  queda para validacion runtime (MapLibre nativo no carga bajo Robolectric). */
class RouteMapGradientContractTest {
    private val src = File("src/main/java/dev/repera/mobile/RouteMapView.kt").readText()

    @Test fun gradientUsesSourceLineMetricsAndProgress() {
        assertTrue(src.contains("PropertyFactory.lineGradient(gradient)"))
        // lineMetrics es opcion de GeoJsonSource (GeoJsonOptions), verificado
        // en el bytecode del SDK; NO propiedad de layout de LineLayer.
        assertTrue(src.contains("GeoJsonOptions().withLineMetrics(true)"))
        assertTrue(!src.contains("\"line-metrics\""))
        assertTrue(src.contains("Expression.interpolate(Expression.linear(), Expression.lineProgress()"))
    }

    @Test fun cornersRounded() {
        assertTrue(src.contains("PropertyFactory.lineJoin(\"round\")"))
        assertTrue(src.contains("PropertyFactory.lineCap(\"round\")"))
    }

    @Test fun stopsWeightedByDistancePerRun() {
        // Paradas por distancia acumulada relativa dentro de cada tramo continuo.
        assertTrue(src.contains("acc = (acc + dists[i] / total).coerceAtMost(1.0)"))
        assertTrue(src.contains("Expression.stop(acc, Expression.color(seg.argb.toInt()))"))
        // Cortes entre tramos: el enlace estimado rompe la continuidad.
        assertTrue(src.contains("runs.last().last().b !== seg.a"))
        // Limpieza de fuentes/capas por tramo al recomponer.
        assertTrue(src.contains("route-src-\$i"))
    }
}
