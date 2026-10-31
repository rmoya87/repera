import Foundation
import HealthKit
import ReperaDomain

/// Catálogo de Comenzar en el Watch (mismos rawValue que `LiveSport` en iPhone).
enum WatchLiveSport: String, CaseIterable, Identifiable, Sendable {
    case running, cycling, walking, hiking, trail, mountainBike, gravel
    case crossfit, strength, hiit, hyrox, tennis, padel, surfing, swimming
    case windsurfing, kitesurfing, kayaking, rowing, canoeing, sailing
    case golf, skiing, iceSkating, snowboarding, crossCountrySkiing
    case soccer, basketball, volleyball
    case climbing, dance, pilates, skateboarding
    case boxing, kickboxing, martialArts, wrestling
    case badminton, pickleball, squash
    case functionalStrength, coreTraining, elliptical, stairClimbing
    case americanFootball, baseball, softball, hockey, lacrosse, rugby
    case yoga, mobility, other

    var id: String { rawValue }

    /// Paridad iPhone: ids persistidos, fuera del carrusel/picker.
    var isSelectable: Bool {
        switch self {
        case .elliptical, .stairClimbing, .softball: false
        default: true
        }
    }

    var title: String {
        switch self {
        case .running: "Carrera"
        case .cycling: "Ciclismo de carretera"
        case .walking: "Caminata"
        case .hiking: "Senderismo"
        case .trail: "Carrera de montaña"
        case .mountainBike: "Ciclismo de montaña"
        case .gravel: "Bicicleta de gravel"
        case .crossfit: "CrossFit"
        case .strength: "Entrenamiento"
        case .hiit: "HIIT"
        case .hyrox: "HYROX"
        case .tennis: "Tenis"
        case .padel: "Pádel"
        case .surfing: "Surf"
        case .swimming: "Natación"
        case .windsurfing: "Windsurf"
        case .kitesurfing: "Kitesurf"
        case .kayaking: "Kayak"
        case .rowing: "Remo"
        case .canoeing: "Piragua"
        case .sailing: "Vela"
        case .golf: "Golf"
        case .skiing: "Esquí alpino"
        case .iceSkating: "Patinaje sobre hielo"
        case .snowboarding: "Snowboard"
        case .crossCountrySkiing: "Esquí de fondo"
        case .soccer: "Fútbol"
        case .basketball: "Baloncesto"
        case .volleyball: "Voleibol"
        case .climbing: "Escalada"
        case .dance: "Baile"
        case .pilates: "Pilates"
        case .skateboarding: "Skateboard"
        case .yoga: "Yoga"
        case .mobility: "Movilidad"
        case .boxing: "Boxeo"
        case .kickboxing: "Kickboxing"
        case .martialArts: "Artes marciales"
        case .wrestling: "Lucha"
        case .badminton: "Bádminton"
        case .pickleball: "Pickleball"
        case .squash: "Squash"
        case .functionalStrength: "Fuerza funcional"
        case .coreTraining: "Core"
        case .elliptical: "Elíptica"
        case .stairClimbing: "Escaleras"
        case .americanFootball: "Fútbol americano"
        case .baseball: "Béisbol"
        case .softball: "Softbol"
        case .hockey: "Hockey"
        case .lacrosse: "Lacrosse"
        case .rugby: "Rugby"
        case .other: "Otra actividad"
        }
    }

    /// Mismos SF Symbols que `LiveSport.symbol` en iPhone (`LiveActivityView`).
    var symbolName: String {
        switch self {
        case .running, .trail: "figure.run"
        case .cycling: "figure.outdoor.cycle"
        case .mountainBike, .gravel: "bicycle"
        case .walking: "figure.walk"
        case .hiking: "figure.hiking"
        case .crossfit: "figure.cross.training"
        case .hyrox: "figure.run"
        case .strength: "figure.strengthtraining.traditional"
        case .hiit: "timer"
        case .tennis: "figure.tennis"
        case .padel: "figure.tennis"
        case .surfing: "surfboard"
        case .swimming: "figure.pool.swim"
        case .windsurfing: "figure.sailing"
        case .kitesurfing: "figure.surfing"
        case .kayaking: "figure.rower"
        case .rowing: "figure.outdoor.rowing"
        case .canoeing: "oar.2.crossed"
        case .sailing: "sailboat"
        case .golf: "figure.golf"
        case .skiing: "figure.skiing.downhill"
        case .iceSkating: "figure.ice.skating"
        case .skateboarding: "figure.skating"
        case .snowboarding: "figure.snowboarding"
        case .crossCountrySkiing: "figure.skiing.crosscountry"
        case .soccer: "figure.indoor.soccer"
        case .basketball: "figure.basketball"
        case .volleyball: "figure.volleyball"
        case .climbing: "figure.climbing"
        case .dance: "figure.dance"
        case .pilates: "figure.pilates"
        case .yoga: "figure.yoga"
        case .mobility: "figure.flexibility"
        case .boxing: "figure.boxing"
        case .kickboxing: "figure.kickboxing"
        case .martialArts: "figure.martial.arts"
        case .wrestling: "figure.wrestling"
        case .badminton: "figure.badminton"
        case .pickleball: "figure.pickleball"
        case .squash: "figure.squash"
        case .functionalStrength: "dumbbell"
        case .coreTraining: "figure.core.training"
        case .elliptical, .stairClimbing: "figure.mixed.cardio"
        case .americanFootball: "figure.american.football"
        case .baseball, .softball: "figure.baseball"
        case .hockey: "figure.field.hockey"
        case .lacrosse: "figure.lacrosse"
        case .rugby: "figure.rugby"
        case .other: "figure.mixed.cardio"
        }
    }

    var usesGPS: Bool {
        switch self {
        case .running, .cycling, .walking, .hiking, .trail, .mountainBike,
             .gravel, .surfing, .windsurfing, .kitesurfing, .kayaking,
             .rowing, .canoeing, .sailing, .golf, .skiing,
             .snowboarding, .crossCountrySkiing, .skateboarding:
            true
        default: false
        }
    }

    var displaysSpeed: Bool {
        switch self {
        case .cycling, .mountainBike, .gravel, .surfing, .windsurfing,
             .kitesurfing, .kayaking, .rowing, .canoeing, .sailing,
             .golf, .skiing, .snowboarding, .crossCountrySkiing, .skateboarding:
            true
        default: false
        }
    }

    var tracksElevation: Bool {
        switch self {
        case .hiking, .trail, .mountainBike, .skiing,
             .snowboarding, .crossCountrySkiing:
            true
        default: false
        }
    }

    var group: String {
        switch self {
        case .running, .trail, .walking, .hiking: "A pie"
        case .cycling, .mountainBike, .gravel: "Ciclismo"
        case .crossfit, .strength, .hiit, .hyrox: "Fuerza y fitness"
        case .tennis, .padel, .badminton, .pickleball, .squash: "Deportes de raqueta"
        case .surfing, .swimming, .windsurfing, .kitesurfing,
             .kayaking, .rowing, .canoeing, .sailing: "Deportes acuáticos"
        case .skiing, .iceSkating, .snowboarding, .crossCountrySkiing: "Deportes de invierno"
        case .soccer, .basketball, .volleyball, .americanFootball,
             .baseball, .softball, .hockey, .lacrosse, .rugby: "Deportes de equipo"
        case .boxing, .kickboxing, .martialArts, .wrestling: "Combate"
        case .functionalStrength, .coreTraining, .elliptical, .stairClimbing: "Cardio y gimnasio"
        default: "Otros deportes"
        }
    }

    var healthKitActivityType: HKWorkoutActivityType {
        switch self {
        case .running, .trail: .running
        case .walking: .walking
        case .hiking: .hiking
        case .cycling, .mountainBike, .gravel: .cycling
        case .swimming: .swimming
        case .rowing, .kayaking, .canoeing: .rowing
        case .yoga, .pilates, .mobility: .yoga
        case .hiit, .hyrox, .crossfit: .highIntensityIntervalTraining
        case .strength, .functionalStrength, .coreTraining: .traditionalStrengthTraining
        case .elliptical: .elliptical
        case .stairClimbing: .stairClimbing
        case .soccer: .soccer
        case .basketball: .basketball
        case .tennis, .padel, .badminton, .pickleball, .squash: .tennis
        case .boxing, .kickboxing, .martialArts, .wrestling: .martialArts
        case .skiing, .crossCountrySkiing: .downhillSkiing
        case .snowboarding: .snowboarding
        case .dance: .cardioDance
        default: .other
        }
    }
}

enum WatchHubItem: Identifiable, Equatable {
    case plan(WorkoutSession)
    case sport(WatchLiveSport)

    var id: String {
        switch self {
        case .plan(let session): "plan-\(session.id.uuidString)"
        case .sport(let sport): "sport-\(sport.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .plan(let session): session.title
        case .sport(let sport): sport.title
        }
    }

    var symbolName: String {
        switch self {
        case .plan: "figure.strengthtraining.traditional"
        case .sport(let sport): sport.symbolName
        }
    }
}
