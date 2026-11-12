import Testing
@testable import ReperaDomain

/// Real training-board transcription regression cases. These are OCR text
/// fixtures, not images: photo/OCR accuracy remains an on-device integration test.
struct BoardScanGlobalFixturesTests {
    private let catalog = Catalog.seed()

    @Test func ddbPushPressPrefersDumbbellCatalogVariant() {
        let dumbbell = Exercise(name: "Dumbbell Push Press", muscleGroup: "Hombro")
        let barbell = Exercise(name: "Push press", muscleGroup: "Hombro")
        let parsed = BoardScanLiteParser.parse(
            ocrText: "AMRAP 4'\n7 DDB PUSH PRESS",
            catalog: [barbell, dumbbell]
        ).blocks
        #expect(parsed.first?.movements.first?.exerciseId == dumbbell.id)
    }

    @Test func warmUpStrengthAndAMRAPDoNotCreateHeadersOrVideosAsExercises() {
        let blocks = BoardScanLiteParser.parse(ocrText: """
        WARM UP - 2 ROUNDS
        OF
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
        """, catalog: catalog).blocks
        #expect(blocks.count == 3)
        guard blocks.count == 3 else { return }
        #expect(blocks[0].rounds == 2)
        #expect(blocks[0].movements.count == 4)
        #expect(blocks[1].wodNotes?.contains("DEADLIFT OFF BLOCKS") == true)
        #expect(blocks[2].movements.count == 4)
        #expect(!blocks.flatMap(\.movements).contains {
            $0.name.uppercased().contains("WARM UP") ||
            $0.name.uppercased().contains("▶") ||
            $0.name.uppercased() == "OF"
        })
    }

    @Test func namedWODAndStandaloneRoundCountAreBlockMetadata() {
        let named = BoardScanLiteParser.parse(ocrText: """
        WODSITO (TC35')
        100 CAL MACHINE (DIV)
        20 ROUNDS (ALTERNANDO)
        2 HANG C&J (60/40)
        4 FONT SQUAT
        6 PULL UPS/C2B
        BUY OUT
        200 DUERS (TO DIV.)
        """, catalog: catalog).blocks
        #expect(named.count == 1)
        #expect(named.first?.timeCapMinutes == 35)
        #expect(named.first?.rounds == 20)
        #expect(!named.flatMap(\.movements).contains { $0.name.uppercased().contains("BUY OUT") })

        let partner = BoardScanLiteParser.parse(ocrText: """
        FOR TIME · TC 40'
        3 RONDAS
        * 600 M RUN JUNTOS
        * 40 CAL ROW O SKI — A REPARTIR
        * 30 POWER CLEAN — A REPARTIR · 50/30 KG
        * 24 T2B — A REPARTIR
        * 16 BAR FACING BURPEES — SYNCRO
        """, catalog: catalog).blocks
        #expect(partner.count == 1)
        #expect(partner.first?.rounds == 3)
        #expect(partner.first?.movements.count == 5)
    }

    @Test func prescribedRepWaveIsAttachedToFollowingMovements() {
        let blocks = BoardScanLiteParser.parse(ocrText: """
        FOR TIME (TC 10')
        10-9-8-7-6-5-4-3-2-1
        POWER CLEAN 50/35
        1-2-3-4-5-6-7-8-9-10
        BURPEES OVER THE BAR
        """, catalog: catalog).blocks
        #expect(blocks.count == 1)
        #expect(blocks.first?.movements.count == 2)
        #expect(blocks.first?.movements.first?.repScheme == [10,9,8,7,6,5,4,3,2,1])
        #expect(blocks.first?.movements.last?.repScheme == [1,2,3,4,5,6,7,8,9,10])
    }

    @Test func buyInRowIsDistanceNotBarbellWeight() {
        let blocks = BoardScanLiteParser.parse(ocrText: """
        Metcon
        5min AMRAP (x3)
        Buy in... 400/320m Row
        Max Rounds of (Cindy):
        5 Pull up
        10 Push up
        15 Air Squat
        2min Rest entre AMRAPs
        """, catalog: catalog).blocks
        #expect(blocks.count == 1)
        #expect(blocks.first?.movements.first?.distanceMeters == 400)
        #expect(blocks.first?.movements.first?.weightMaleKg == nil)
        #expect(blocks.first?.movements.first?.notes?.contains("320") == true)
    }

    @Test func maxRepsAndGeneric1RMProgressionAreNotFakeMovements() {
        let maximum = BoardScanLiteParser.parse(ocrText: """
        Squat snatch
        Max (n) rep(s)
        Metcon
        3min AMRAP (x4)
        5 Hang Power Snatch #40/25kg
        10 Pull Up
        15 Air Squat
        20 Double Under
        1mn Rest between AMRAPs
        """, catalog: catalog).blocks
        #expect(maximum.count == 2)
        guard maximum.count == 2 else { return }
        #expect(maximum[0].wodFormat == .maxEffort)
        #expect(maximum[0].movements.count == 1)
        #expect(maximum[1].wodFormat == .amrap)
        #expect(maximum[1].rounds == 4)
        #expect(maximum[1].restBetweenRoundsSeconds == 60)

        let clean = Exercise(name: "Clean", muscleGroup: "Piernas", searchAliases: ["Squat Clean"])
        let strength = BoardScanLiteParser.parse(ocrText: """
        Weightlifting "Squat Clean 1RM Test"
        Every 90s For 15min (10 Series)
        Sets 1-2: 3 Reps #75-80%
        Sets 3-4: 2 Reps #80-85%
        Sets 5-10: 1 Rep #Buscar la 1RM
        *NO Touch & Go. Trabaja a singles
        """, catalog: [clean]).blocks
        #expect(strength.count == 1)
        #expect(strength.first?.kind == .strength)
        #expect(strength.first?.exercises.first?.plannedSets.map(\.targetReps) ==
                [3,3,2,2,1,1,1,1,1,1])
        #expect(strength.first?.wodNotes?.contains("75-80%") == true)
    }

    @Test func thePhotoFormatsStaySeparatedAcrossManyRealBoards() {
        let cases: [(String, String, Int)] = [
            ("team emom", """
            EMOM 40' (TEAM II)
            60 BOB
            60 CAL MACHINE
            60 CLEAN & JERK (60/40)
            60 CAL MACHINE
            60 DBX1 ALT HANG SNATCH (25/17,5)
            60 CAL MACHINE
            60 GOBLET SQUAT (25/17,5)
            (I GO YOU GO)
            """, 1),
            ("emom + 90s + options amrap", """
            EMOM 8'
            2 SQUAT SNATCH @6-8
            EVERY 90" X 7
            1 BACK SQUAT @5-9
            AMRAP 10'
            1 RMU / 2 BMU / 4 C2B / 6 PULL UPS
            3 SNATCH 60/40
            5 BFB
            3 CLUSTER 60/40
            5 BFB
            """, 3),
            ("emom + 18 amrap", """
            EMOM 12'
            3-2-2-1 W.S. PULL UPS @RIR 2-1
            8-12M DDB STEP UP @7-8
            1' REST
            AMRAP 18'
            20 RKBS 24/16
            400M RUN
            10 HSPU
            16/12 CAL
            """, 2),
            ("squat clean + paused squat + 4 rft", """
            EMOM 8'
            2 SQUAT CLEAN @6-8
            EVERY 2' X 4
            3-5 FRONT SQUAT 2" PAUSE DOWN @6-8
            4 RFT (TC 13')
            3 POWER CLEAN 70/45
            30 DU / 60 SU
            3 SHOULDER TO OVERHEAD 70/45
            30 DU / 60 SU
            3 HANG SQUAT CLEAN 70/45
            30 DU / 60 SU
            """, 3),
            ("emom with rest + chipper", """
            EMOM 12'
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
            10 BTT
            """, 2),
            ("simple emom + back squat + amrap", """
            EMOM 10'
            1 SQUAT SNATCH @5-9
            BACK SQUAT
            FIND 5 RM (TC 10')
            AMRAP 10'
            5 BBJO
            7 POWER SNATCH 45/30
            9 T2B
            """, 3),
            ("warm up then emom then ladder", """
            WARM UP - 2 ROUNDS OF
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
            CAL ANY CARDIO
            """, 3),
            ("warm-up tabata + strength + wave", """
            WARM UP - TABATA 4'
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
            BURPEES OVER THE BAR
            """, 4),
            ("metcon 10 rft", """
            Metcon
            10 Rounds For Time: (25min Cap)
            3 Wall Walk
            5 Power Clean #60/40kg
            7 Chest to Bar
            9/8 Cal Row
            """, 1),
            ("accessory stations", """
            Accessory Work
            Every Minute for 12min (4 Rounds)
            Minute 1: 6 Double DB Z Press
            Minute 2: 10 Standing Landmine Anti-rotation
            Minute 3: 10 KB Alternating Goblet Cossack Squat
            *Lo más pesado posible
            """, 1),
            ("four interval amraps", """
            Metcon
            3min AMRAP (x4)
            5 Hang Power Snatch #40/25kg
            10 Pull Up
            15 Air Squat
            20 Double Under
            1mn Rest between AMRAPs
            *Continua por donde te quedaste en el AMRAP anterior
            """, 1),
            ("three interval amraps with buy in", """
            Metcon
            5min AMRAP (x3)
            Buy in... 400/320m Row
            Max Rounds of (Cindy):
            5 Pull up
            10 Push up
            15 Air Squat
            2min Rest entre AMRAPs
            *Retoma el Cindy por donde lo dejaste
            """, 1),
            ("weightlifting scheme", """
            Weightlifting "Squat Clean 1RM Test"
            Every 90s For 15min (10 Series)
            Sets 1-2: 3 Reps #75-80%
            Sets 3-4: 2 Reps #80-85%
            Sets 5-10: 1 Rep #Buscar la 1RM
            *NO Touch & Go. Trabaja a singles
            """, 1),
            ("short amrap", """
            Metcon
            12min AMRAP
            4 Wall Walk
            8 Deadlift #80/55kg
            200m Run
            """, 1),
        ]
        for (name, text, expected) in cases {
            let blocks = BoardScanLiteParser.parse(ocrText: text, catalog: catalog).blocks
            #expect(blocks.count == expected, "Board: \(name), got \(blocks.count) blocks")
        }
    }
}
