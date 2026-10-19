import Testing
@testable import ReperaDomain

struct ExerciseLoggingStyleTests {
    @Test func jumpRopeUsesRepsAndTime() {
        let du = Exercise(name: "Dobles de comba", muscleGroup: "Cardio", equipment: "Comba")
        #expect(du.loggingStyle == .repsAndTime)
        #expect(Exercise.loggingStyle(name: "Simples de comba", equipment: "Comba") == .repsAndTime)
    }

    @Test func bodyweightUsesRepsOnly() {
        #expect(Exercise.loggingStyle(name: "Burpee", equipment: "Peso corporal") == .repsOnly)
    }

    @Test func pullUpsAllowWeight() {
        let pu = Exercise(name: "Dominadas", muscleGroup: "Espalda", equipment: "Peso corporal")
        #expect(pu.loggingStyle == .loadAndReps)
        #expect(pu.loadField == .weightKg)
        #expect(Exercise.loadStepperTitle(name: "Dominadas", equipment: "Peso corporal") == "Lastre (kg)")
    }

    @Test func hspuAllowsDeficit() {
        #expect(Exercise.loggingStyle(name: "HSPU", equipment: "Peso corporal") == .loadAndReps)
        #expect(Exercise.loadField(name: "HSPU") == .deficitCm)
        #expect(Exercise.loadStepperTitle(name: "HSPU") == "Déficit (cm)")
    }

    @Test func jumpRopeQuantityLabelIsVeces() {
        let du = Exercise(name: "Dobles de comba", muscleGroup: "Cardio", equipment: "Comba")
        #expect(du.quantityFieldLabel == "Veces")
    }

    @Test func barbellUsesLoadAndReps() {
        let thruster = Exercise(name: "Thruster", muscleGroup: "Piernas", equipment: "Barra")
        #expect(thruster.loggingStyle == .loadAndReps)
    }

    @Test func airBikeUsesMachineWorkCalories() {
        #expect(Exercise.loggingStyle(name: "Air bike", equipment: nil) == .machineWork)
        #expect(Exercise.defaultQuantityUnit(name: "Air bike") == .calories)
        #expect(Exercise.allowsCalorieOrDistanceToggle(name: "Air bike") == true)
        #expect(Exercise.loggingStyle(name: "Echo bike", equipment: nil) == .machineWork)
        #expect(Exercise.defaultQuantityUnit(name: "Echo bike") == .calories)
    }

    @Test func skiErgUsesMachineWorkCalories() {
        #expect(Exercise.loggingStyle(name: "SkiErg", equipment: "Máquina") == .machineWork)
        #expect(Exercise.defaultQuantityUnit(name: "SkiErg") == .calories)
        #expect(Exercise.allowsCalorieOrDistanceToggle(name: "SkiErg") == true)
    }

    @Test func rowerUsesMachineWorkMeters() {
        #expect(Exercise.loggingStyle(name: "Remo máquina", equipment: "Máquina") == .machineWork)
        #expect(Exercise.defaultQuantityUnit(name: "Remo máquina") == .meters)
        #expect(Exercise.loggingStyle(name: "Remo", equipment: nil) == .machineWork)
        #expect(Exercise.allowsCalorieOrDistanceToggle(name: "Remo") == true)
    }

    @Test func strengthRowsStayLoadOrReps() {
        #expect(Exercise.loggingStyle(name: "Remo con barra", equipment: "Barra") == .loadAndReps)
        #expect(Exercise.loggingStyle(name: "Remo mancuerna", equipment: "Mancuernas") == .loadAndReps)
        #expect(Exercise.loggingStyle(name: "Remo sentado", equipment: "Polea") == .loadAndReps)
        #expect(Exercise.loggingStyle(name: "Remo invertido", equipment: "Peso corporal") == .repsOnly)
    }

    @Test func runUsesMachineWorkMetersOnly() {
        #expect(Exercise.loggingStyle(name: "Cinta / carrera", equipment: nil) == .machineWork)
        #expect(Exercise.defaultQuantityUnit(name: "Cinta / carrera") == .meters)
        #expect(Exercise.allowsCalorieOrDistanceToggle(name: "Cinta / carrera") == false)
        #expect(Exercise.loggingStyle(name: "Shuttle run", equipment: "Peso corporal") == .machineWork)
    }

    @Test func wodPlannedSetsKeepCaloriesAndMeters() {
        let cal = WODMovement(name: "Air bike", calories: 15)
        #expect(cal.plannedSetsFromReps.first?.targetReps == 15)
        #expect(cal.prescribedQuantityUnit == .calories)

        let meters = WODMovement(name: "Remo", distanceMeters: 1000)
        #expect(meters.plannedSetsFromReps.first?.targetReps == 1000)
        #expect(meters.prescribedQuantityUnit == .meters)
    }
}
