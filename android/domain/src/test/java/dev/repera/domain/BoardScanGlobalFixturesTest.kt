package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** User-supplied training boards, transcribed after OCR. Test parser behavior,
 * not camera OCR accuracy, which requires device integration tests. */
class BoardScanGlobalFixturesTest {
    @Test fun warmupStrengthAndAmrapPreserveThreeSections() {
        val blocks=BoardScanLiteParser.parse("""
            WARM UP - 2 ROUNDS OF
            10/8 CAL
            5+5 SINGLE LEG KB DEADLIFT
            10 SIT UPS
            7 DDB PUSH PRESS
            EVERY 2' X 4
            5-4-4-3 DEADLIFT OFF BLOCKS @6-8
            ▶ DEADLIFT OFF BLOCKS
            AMRAP 14'
            16 DB SNATCH 22,5/15
            14 BOX JUMP
            12 RING DIPS
            10/8 CAL
        """.trimIndent()).blocks
        assertEquals(3,blocks.size)
        assertEquals(2,blocks[0].rounds)
        assertEquals(4,blocks[0].movements.size)
        assertEquals(4,blocks[2].movements.size)
        assertTrue(blocks[1].wodNotes.orEmpty().contains("DEADLIFT OFF BLOCKS"))
        assertFalse(blocks.flatMap {it.movements}.any {
            it.name.uppercase()=="OF" || it.name.contains("▶") || it.name.uppercase().contains("WARM UP")
        })
    }

    @Test fun namedPartnerAndDescendingAscendingLadder() {
        val named=BoardScanLiteParser.parse("""
            WODSITO (TC35')
            100 CAL MACHINE (DIV)
            20 ROUNDS (ALTERNANDO)
            2 HANG C&J (60/40)
            4 FRONT SQUAT
            6 PULL UPS/C2B
            BUY OUT
            200 DUERS (TO DIV.)
        """.trimIndent()).blocks
        assertEquals(1,named.size)
        assertEquals(35,named[0].timeCapMinutes)
        assertEquals(20,named[0].rounds)
        val partner=BoardScanLiteParser.parse("""
            FOR TIME · TC 40'
            3 RONDAS
            * 600 M RUN JUNTOS
            * 40 CAL ROW O SKI — A REPARTIR
            * 30 POWER CLEAN — A REPARTIR · 50/30 KG
            * 24 T2B — A REPARTIR
            * 16 BAR FACING BURPEES — SYNCRO
        """.trimIndent()).blocks
        assertEquals(1,partner.size)
        assertEquals(3,partner[0].rounds)
        assertEquals(5,partner[0].movements.size)
        val ladder=BoardScanLiteParser.parse("""
            FOR TIME (TC 10')
            10-9-8-7-6-5-4-3-2-1
            POWER CLEAN 50/35
            1-2-3-4-5-6-7-8-9-10
            BURPEES OVER THE BAR
        """.trimIndent()).blocks
        assertEquals(2,ladder[0].movements.size)
        assertEquals(listOf(10,9,8,7,6,5,4,3,2,1),ladder[0].movements[0].repScheme)
        assertEquals(listOf(1,2,3,4,5,6,7,8,9,10),ladder[0].movements[1].repScheme)
    }

    @Test fun photographedFormatMatrix() {
        val cases=listOf(
            Triple("team", """EMOM 40' (TEAM II)
                60 BOB
                60 CAL MACHINE
                60 CLEAN & JERK (60/40)
                60 CAL MACHINE
                60 DBX1 ALT HANG SNATCH (25/17,5)
                60 CAL MACHINE
                60 GOBLET SQUAT (25/17,5)
                (I GO YOU GO)""",1),
            Triple("emom/every/amrap", """EMOM 8'
                2 SQUAT SNATCH @6-8
                EVERY 90" X 7
                1 BACK SQUAT @5-9
                AMRAP 10'
                1 RMU / 2 BMU / 4 C2B / 6 PULL UPS
                3 SNATCH 60/40
                5 BFB
                3 CLUSTER 60/40
                5 BFB""",3),
            Triple("emom/amrap", """EMOM 12'
                3-2-2-1 W.S. PULL UPS @RIR 2-1
                8-12M DDB STEP UP @7-8
                1' REST
                AMRAP 18'
                20 RKBS 24/16
                400M RUN
                10 HSPU
                16/12 CAL""",2),
            Triple("strength/rft", """EMOM 8'
                2 SQUAT CLEAN @6-8
                EVERY 2' X 4
                3-5 FRONT SQUAT 2" PAUSE DOWN @6-8
                4 RFT (TC 13')
                3 POWER CLEAN 70/45
                30 DU / 60 SU
                3 SHOULDER TO OVERHEAD 70/45
                30 DU / 60 SU
                3 HANG SQUAT CLEAN 70/45
                30 DU / 60 SU""",3),
            Triple("chipper", """EMOM 12'
                3-2-2-1 PUSH PRESS @6-9
                3 DEFICIT DEADLIFT @6-8
                1' REST
                FOR TIME (TC 20')
                10 BMU
                20 BOX JUMP
                30 CAL ANY CARDIO
                40M BURPEE BROAD JUMP
                500M RUN
                40M DB W. LUNGES 22,5/15
                30 T2B
                20 WALL BALL 12/9
                10 BTT""",2),
            Triple("warmup/ladder", """WARM UP - 2 ROUNDS OF
                10/8 CAL
                10 LUNGES
                7 WORM PUSH UPS
                10 RING ROW
                EMOM 16'
                1 ROPE CLIMB
                5-15 STRICT HSPU @RIR 3-2
                14M DDB FRONT RACK W. LUNGES @7-8
                1' REST
                FOR TIME (TC 15')
                30-20-10
                AMERICAN KB SWING 24/16
                WALL BALL 9/7
                PULL UPS
                CAL ANY CARDIO""",3),
            Triple("tabata", """WARM UP - TABATA 4'
                ODD: AKBS
                EVEN: DU / SU
                EMOM 10'
                1 SQUAT CLEAN @5-9
                EVERY 2' X 4
                3-5 FRONT SQUAT TO A MEDBALL @6-8
                ▶ FRONT SQUAT TO A MEDBALL
                FOR TIME (TC 10')
                10-9-8-7-6-5-4-3-2-1
                POWER CLEAN 50/35
                1-2-3-4-5-6-7-8-9-10
                BURPEES OVER THE BAR""",4),
            Triple("metcon rft", """Metcon
                10 Rounds For Time: (25min Cap)
                3 Wall Walk
                5 Power Clean #60/40kg
                7 Chest to Bar
                9/8 Cal Row""",1),
            Triple("accessory", """Accessory Work
                Every Minute for 12min (4 Rounds)
                Minute 1: 6 Double DB Z Press
                Minute 2: 10 Standing Landmine Anti-rotation
                Minute 3: 10 KB Alternating Goblet Cossack Squat
                *Lo más pesado posible""",1),
            Triple("amrap x4", """Metcon
                3min AMRAP (x4)
                5 Hang Power Snatch #40/25kg
                10 Pull Up
                15 Air Squat
                20 Double Under
                1mn Rest between AMRAPs
                *Continua por donde te quedaste en el AMRAP anterior""",1),
            Triple("amrap x3", """Metcon
                5min AMRAP (x3)
                Buy in... 400/320m Row
                Max Rounds of (Cindy):
                5 Pull up
                10 Push up
                15 Air Squat
                2min Rest entre AMRAPs
                *Retoma el Cindy por donde lo dejaste""",1),
            Triple("weightlifting", """Weightlifting "Squat Clean 1RM Test"
                Every 90s For 15min (10 Series)
                Sets 1-2: 3 Reps #75-80%
                Sets 3-4: 2 Reps #80-85%
                Sets 5-10: 1 Rep #Buscar la 1RM
                *NO Touch & Go. Trabaja a singles""",1),
            Triple("metcon 12", """Metcon
                12min AMRAP
                4 Wall Walk
                8 Deadlift #80/55kg
                200m Run""",1)
        )
        for((name,board,count) in cases) {
            val actual=BoardScanLiteParser.parse(board.trimIndent()).blocks
            assertEquals("board "+name,count,actual.size)
        }
    }
}
