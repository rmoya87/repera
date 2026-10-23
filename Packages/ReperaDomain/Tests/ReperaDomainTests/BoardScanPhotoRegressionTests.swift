import Testing
@testable import ReperaDomain

struct BoardScanPhotoRegressionTests {
    private let catalog = Catalog.seed()

    @Test func metconForTimeKeepsThreeSequentialStages() {
        let result = BoardScanLiteParser.parse(ocrText: """
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
        """, catalog: catalog)
        #expect(result.blocks.count == 1)
        let wod = result.blocks[0]
        #expect(wod.wodFormat == .forTime)
        #expect(wod.timeCapMinutes == 20)
        #expect(wod.rounds == nil)
        #expect(wod.movements.count == 12)
        #expect(wod.movements.filter { $0.distanceMeters != nil }.map { $0.distanceMeters! } == [750,500,250])
        #expect(wod.movements.filter { $0.name == "Push jerk" }.count == 3)
        #expect(wod.movements.filter { $0.weightMaleKg != nil }.map { $0.weightMaleKg! } == [40,40,50,50,60,60])
    }

    @Test func squatSnatchIntervalHasEightDistinctPercentSets() {
        let result = BoardScanLiteParser.parse(ocrText: """
        Weightlifting "Squat Snatch Work"
        Every 90s For 12min (8 Series)
        Sets 1-2: 3 Squat Snatch #70%
        Sets 3-4: 2 Squat Snatch #75%
        Sets 5-8: 1 Squat Snatch #>80%
        *NO Touch & Go. Trabaja a singles
        """, catalog: catalog)
        #expect(result.blocks.count == 1)
        let block = result.blocks[0]
        #expect(block.kind == .strength)
        #expect(block.emomIntervalSeconds == 90)
        #expect(block.timeCapMinutes == 12)
        #expect(block.exercises.count == 1)
        #expect(block.exercises[0].plannedSets.map(\.targetReps) == [3,3,2,2,1,1,1,1])
        #expect(block.exercises[0].plannedSets.map(\.targetPercent1RM) == [70,70,75,75,80,80,80,80])
        #expect(block.exercises[0].plannedSets.map(\.targetPercent1RMIsMinimum) == [false,false,false,false,true,true,true,true])
        #expect(block.wodNotes?.contains(">80%") == true)
    }

    @Test func alternateWeightedPullupAndRingRowInFiveRounds() {
        let result = BoardScanLiteParser.parse(ocrText: """
        Pulling Strength & Power
        Every 90s For 15min (5 rondas) Alternando A y B
        A: 4 Weighted Pull Up #85% o RPE 8,5/10
        B: 8 Plyo Ring Row (Feet Elevated)
        Realiza ambos ejercicios a máxima velocidad.
        """,catalog:catalog)
        #expect(result.blocks.count == 1)
        let block = result.blocks[0]
        #expect(block.kind == .strength)
        #expect(block.timeCapMinutes == 15)
        #expect(block.emomIntervalSeconds == 90)
        #expect(block.exercises.count == 2)
        #expect(block.exercises.allSatisfy { $0.plannedSets.count == 5 })
        #expect(block.wodNotes?.contains("8,5/10") == true)
    }

    @Test func intervalMetconIsFourRoundsAndWorkRest() {
        let result = BoardScanLiteParser.parse(ocrText: """
        Metcon
        En intervalos de 4min ON y 1min OFF, completa:
        4 Rounds For Time:
        100 Double Under
        20 Deadlift #80/55kg
        20 Toes to bar
        *Cap: 4 Intervalos de 4min
        """,catalog:catalog)
        #expect(result.blocks.count == 1)
        let block = result.blocks[0]
        #expect(block.wodFormat == .forTime)
        #expect(block.rounds == 4)
        #expect(block.workSeconds == 240)
        #expect(block.restSeconds == 60)
        #expect(block.movements.count == 3)
    }

    @Test func betweenRoundsRestIsNotExtraMovement() {
        let result = BoardScanLiteParser.parse(ocrText: """
        Metcon
        6 Rounds For Time: (25min Cap)
        20 KB Goblet Alt Box Step Up
        20 American KB Swing #24/16kg
        10 Handstand Push Up
        1min rest entre rondas
        """,catalog:catalog)
        #expect(result.blocks.count == 1)
        let block = result.blocks[0]
        #expect(block.wodFormat == .forTime)
        #expect(block.rounds == 6)
        #expect(block.timeCapMinutes == 25)
        #expect(block.restBetweenRoundsSeconds == 60)
        #expect(block.movements.count == 3)
        #expect(block.movements.first?.name == "Kettlebell Goblet Box Step-Up")
    }
}
