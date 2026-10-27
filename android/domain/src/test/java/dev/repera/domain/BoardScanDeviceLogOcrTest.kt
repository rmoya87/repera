package dev.repera.domain

import org.json.JSONArray
import org.junit.Assert.*
import org.junit.BeforeClass
import org.junit.Test

/**
 * Port parcial de BoardScanHangReproTests/BoardScanFullCatalogTests (Apple fc3ef7e1). Apple los ejecuta contra
 * BoardImportParser (no es la ruta de produccion de Apple, que usa BoardScanLiteParser); aqui se ejecuta el LiteParser
 * de Android, que es el equivalente de la ruta real. El catalogo es catalog_seed.json de Android, no Catalog.seed() de Apple.
 */
class BoardScanDeviceLogOcrTest {
    companion object {
        lateinit var catalog: List<CatalogExercise>
        @BeforeClass @JvmStatic fun load() {
            val a=JSONArray(requireNotNull(BoardScanDeviceLogOcrTest::class.java.classLoader?.getResource("catalog_seed.json")).readText())
            catalog=(0 until a.length()).map {a.getJSONObject(it).let {o->CatalogExercise(id=o.getString("id"),name=o.getString("name"))}}
        }
    }
    private val ocr = """
        EMOM 12.
        4-3-3-2 W.S. PULL UPS @RIR 2-1
        5-10 KIPPING HSPU @FQ
        1, REST
        EMOM 8.
        ODD: 6-8 DB ALT HANG SNATCH @HEAVY
        EVEN: 45 MAX DU
        AMRAP12'
        5 DDB DEVIL PRESS 20/12,5
        10 T2B
        200M RUN
        """.trimIndent()
    @Test fun deviceLogOcrParsesThreeBlocksQuicklyWithFullSeedCatalog() {
        assertTrue(catalog.size>=180)
        val t0=System.nanoTime()
        val result=BoardScanLiteParser.parse(ocrText=ocr,catalog=catalog)
        val ms=(System.nanoTime()-t0)/1_000_000
        println("DEVICELOG ms=$ms blocks=${result.blocks.size} formats=${result.blocks.map {it.wodFormat}} moves=${result.blocks.map {it.movements.size}}")
        assertTrue("tardo $ms ms",ms<2000)
        assertEquals(3,result.blocks.size)
        assertEquals(listOf(WODFormat.EMOM,WODFormat.EMOM,WODFormat.AMRAP),result.blocks.map {it.wodFormat})
    }

    private fun parse(t:String)=BoardScanLiteParser.parse(ocrText=t.trimIndent(),catalog=catalog)
    // --- Port de BoardScanPhotoRegressionTests (Apple fc3ef7e1): texto OCR literal, sin camara real. Ruta LiteParser. ---
    @Test fun metconForTimeKeepsThreeSequentialStages() {
        val r=parse("""
        Metcon
        For Time: (20min Cap)
        750m Run
        15 Overhead squat #40/25kg
        15 Push Jek #40/25kg
        15 Burpee Over the Bar
        500m Run
        12 Overhead squat #50/35kg
        12 Push Jerk #50/35kg
        12 Burpee Over the Bar
        250m Run
        9 Overhead squat #60/40kg
        9 Push Jerk #60/40kg
        9 Burpee Over the Bar
        """)
        assertEquals(1,r.blocks.size);val w=r.blocks[0]
        assertEquals(WODFormat.FOR_TIME,w.wodFormat);assertEquals(20,w.timeCapMinutes);assertNull(w.rounds)
        assertEquals(12,w.movements.size)
        assertEquals(listOf(750,500,250),w.movements.mapNotNull {it.distanceMeters})
        assertEquals(listOf(40.0,40.0,50.0,50.0,60.0,60.0),w.movements.mapNotNull {it.weightMaleKg}.map {it.toDouble()})
    }
    @Test fun squatSnatchIntervalHasEightDistinctPercentSets() {
        val r=parse("""
        Weightlifting "Squat Snatch Work"
        Every 90s For 12min (8 Series)
        Sets 1-2: 3 Squat Snatch #70%
        Sets 3-4: 2 Squat Snatch #75%
        Sets 5-8: 1 Squat Snatch #>80%
        *NO Touch & Go. Trabaja a singles
        """)
        assertEquals(1,r.blocks.size);val b=r.blocks[0]
        assertEquals(RoutineBlockKind.STRENGTH,b.kind);assertEquals(90,b.emomIntervalSeconds);assertEquals(12,b.timeCapMinutes)
        assertEquals(1,b.exercises.size)
        assertEquals(listOf(3,3,2,2,1,1,1,1),b.exercises[0].plannedSets.map {it.targetReps})
        assertEquals(listOf(70,70,75,75,80,80,80,80),b.exercises[0].plannedSets.map {it.targetPercent1RM?.toInt()})
        assertEquals(listOf(false,false,false,false,true,true,true,true),b.exercises[0].plannedSets.map {it.targetPercent1RMIsMinimum})
        assertTrue(b.wodNotes?.contains(">80%")==true)
    }
    @Test fun alternateWeightedPullupAndRingRowInFiveRounds() {
        val r=parse("""
        Pulling Strength & Power
        Every 90s For 15min (5 rondas) Alternando A y B
        A: 4 Weighted Pull Up #85% o RPE 8,5/10
        B: 8 Plyo Ring Row (Feet Elevated)
        Realiza ambos ejercicios a máxima velocidad.
        """)
        assertEquals(1,r.blocks.size);val b=r.blocks[0]
        assertEquals(RoutineBlockKind.STRENGTH,b.kind);assertEquals(15,b.timeCapMinutes);assertEquals(90,b.emomIntervalSeconds)
        assertEquals(2,b.exercises.size);assertTrue(b.exercises.all {it.plannedSets.size==5})
        assertTrue(b.wodNotes?.contains("8,5/10")==true)
    }
    @Test fun intervalMetconIsFourRoundsAndWorkRest() {
        val r=parse("""
        Metcon
        En intervalos de 4min ON y 1min OFF, completa:
        4 Rounds For Time:
        100 Double Under
        20 Deadlift #80/55kg
        20 Toes to bar
        *Cap: 4 Intervalos de 4min
        """)
        assertEquals(1,r.blocks.size);val b=r.blocks[0]
        assertEquals(WODFormat.FOR_TIME,b.wodFormat);assertEquals(4,b.rounds);assertEquals(240,b.workSeconds);assertEquals(60,b.restSeconds)
        assertEquals(3,b.movements.size)
    }
    @Test fun betweenRoundsRestIsNotExtraMovement() {
        val r=parse("""
        Metcon
        6 Rounds For Time: (25min Cap)
        20 KB Goblet Alt Box Step Up
        20 American KB Swing #24/16kg
        10 Handstand Push Up
        1min rest entre rondas
        """)
        assertEquals(1,r.blocks.size);val b=r.blocks[0]
        assertEquals(WODFormat.FOR_TIME,b.wodFormat);assertEquals(6,b.rounds);assertEquals(25,b.timeCapMinutes)
        assertEquals(60,b.restBetweenRoundsSeconds);assertEquals(3,b.movements.size)
    }
}
