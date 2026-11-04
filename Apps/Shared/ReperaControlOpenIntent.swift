import AppIntents

/// The system dispatches this intent to the foreground Repera scene. It never
/// starts a HealthKit session from a widget or an extension process.
enum ReperaControlTarget: String, AppEnum {
    case today
    case live
    case tools
    case exercises
    case boardScan

    static let typeDisplayRepresentation = TypeDisplayRepresentation("Pantallas de Repera")
    static let caseDisplayRepresentations: [ReperaControlTarget: DisplayRepresentation] = [
        .today: DisplayRepresentation("Entrenamiento de hoy"),
        .live: DisplayRepresentation("Comenzar"),
        .tools: DisplayRepresentation("Temporizador"),
        .exercises: DisplayRepresentation("Ejercicios"),
        .boardScan: DisplayRepresentation("Escanear pizarra")
    ]
}

struct ReperaControlOpenIntent: OpenIntent, TargetContentProvidingIntent {
    static let title: LocalizedStringResource = "Abrir Repera"

    @Parameter(title: "Destino")
    var target: ReperaControlTarget

    var contentIdentifier: String { "repera.control.open" }

    init() {
        target = .today
    }

    init(target: ReperaControlTarget) {
        self.target = target
    }
}
