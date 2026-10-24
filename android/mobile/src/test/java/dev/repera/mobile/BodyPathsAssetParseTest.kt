package dev.repera.mobile

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Verifica que TODAS las rutas del asset real BodyPaths.json (copia idéntica
 * al recurso de iOS) parsean a operaciones no vacías con SvgPathParser.
 * Detecta parseos vacíos silenciosos que dejarían el mapa sin dibujar.
 */
class BodyPathsAssetParseTest {

    @Test
    fun `todas las rutas del asset real parsean a ops no vacias`() {
        val file = File("src/main/assets/BodyPaths.json")
        assertTrue("asset ausente: ${file.absolutePath}", file.isFile)
        val text = file.readText()
        // Las rutas SVG del asset empiezan por M (absolutas); extraer cada literal.
        val paths = Regex("\"(M[^\"]+)\"").findAll(text).map { it.groupValues[1] }.toList()
        assertTrue("se esperaban >50 rutas, hay ${paths.size}", paths.size > 50)
        val vacias = paths.mapIndexedNotNull { i, d ->
            if (SvgPathParser.parse(d).isEmpty()) "[$i] ${d.take(60)}" else null
        }
        assertTrue(
            "${vacias.size} rutas parsean a VACÍO:\n" + vacias.take(10).joinToString("\n"),
            vacias.isEmpty())
    }
}
