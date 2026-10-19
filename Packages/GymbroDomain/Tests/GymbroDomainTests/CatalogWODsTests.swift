import Testing
@testable import GymbroDomain

struct CatalogWODsTests {
    @Test func seedHasKnownBenchmarks() {
        let seed = CatalogWODs.seed()
        #expect(seed.count >= 25)
        let ids = Set(seed.map(\.id))
        #expect(ids.contains("fran"))
        #expect(ids.contains("cindy"))
        #expect(ids.contains("murph"))
        #expect(ids.contains("helen"))
        #expect(ids.contains("dt"))
    }

    @Test func franMakesForTimeBlock() {
        let fran = CatalogWODs.template(id: "fran")
        #expect(fran != nil)
        let block = fran!.makeBlock()
        #expect(block.kind == .wod)
        #expect(block.wodFormat == .forTime)
        #expect(block.wodTemplateId == "fran")
        #expect(block.movements.count == 6)
        #expect(block.title == "Fran")
    }

    @Test func searchFiltersByName() {
        let hits = CatalogWODs.search("murph")
        #expect(hits.count == 1)
        #expect(hits.first?.id == "murph")
    }

    @Test func resultCaptureMatchesFormat() {
        #expect(WODFormat.amrap.resultCapture == .totalReps)
        #expect(WODFormat.forTime.resultCapture == .elapsedTime)
        #expect(WODFormat.emom.resultCapture == .perMovementSets)
    }
}
