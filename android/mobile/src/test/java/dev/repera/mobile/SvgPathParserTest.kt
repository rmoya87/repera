package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SvgPathParserTest {

    @Test
    fun `tokenize separa segundo punto decimal como numero nuevo`() {
        assertEquals(listOf("37.02", ".75"), SvgPathParser.tokenize("37.02.75"))
    }

    @Test
    fun `tokenize signo negativo abre numero y exponente lo conserva`() {
        assertEquals(listOf("10", "-5"), SvgPathParser.tokenize("10-5"))
        assertEquals(listOf("1e-3"), SvgPathParser.tokenize("1e-3"))
    }

    @Test
    fun `M con pares extra implica LineTo`() {
        val ops = SvgPathParser.parse("M10 20 30 40")
        assertEquals(
            listOf(
                SvgPathParser.PathOp.MoveTo(10.0, 20.0),
                SvgPathParser.PathOp.LineTo(30.0, 40.0)
            ), ops)
    }

    @Test
    fun `comandos relativos suman al punto actual`() {
        val ops = SvgPathParser.parse("M10 10 l5 5 h5 v-5 z")
        assertEquals(SvgPathParser.PathOp.MoveTo(10.0, 10.0), ops[0])
        assertEquals(SvgPathParser.PathOp.LineTo(15.0, 15.0), ops[1])
        assertEquals(SvgPathParser.PathOp.LineTo(20.0, 15.0), ops[2])
        assertEquals(SvgPathParser.PathOp.LineTo(20.0, 10.0), ops[3])
        assertEquals(SvgPathParser.PathOp.Close, ops[4])
    }

    @Test
    fun `curvas cubicas relativas`() {
        val ops = SvgPathParser.parse("M0 0 c1 2 3 4 5 6")
        assertEquals(listOf(
            SvgPathParser.PathOp.MoveTo(0.0, 0.0),
            SvgPathParser.PathOp.CubicTo(1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
        ), ops)
    }

    @Test
    fun `arco circular alcanza el punto final`() {
        // Medio círculo de radio 10 de (0,0) a (20,0): debe terminar exactamente en (20,0).
        val ops = SvgPathParser.parse("M0 0 a10 10 0 0 1 20 0")
        val last = ops.last() as SvgPathParser.PathOp.CubicTo
        assertEquals(20.0, last.x, 1e-6)
        assertEquals(0.0, last.y, 1e-6)
    }

    @Test
    fun `arco relativo y radios cero degradados a linea`() {
        val ops = SvgPathParser.parse("M5 5 a0 0 0 0 0 10 10")
        assertEquals(SvgPathParser.PathOp.LineTo(15.0, 15.0), ops.last())
    }

    @Test
    fun `paths reales de BodyPaths parsean sin error y cierran`() {
        // Muestra representativa con curvas y arcos (deltoides frontal).
        val d = "M37.02 45.75c-2.6 2.3-4.4 4.2-5.3 6.9-.8 2.6-.9 5.6-.3 8.9l.6 3.1c.5 2.6 1.5 4.5 3.1 5.6z"
        val ops = SvgPathParser.parse(d)
        assertTrue(ops.isNotEmpty())
        assertEquals(SvgPathParser.PathOp.Close, ops.last())
    }
}
