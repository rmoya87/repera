import AppIntents

/// The system dispatches this intent to the foreground Repera scene. It never
/// starts a HealthKit session from a widget or an extension process.
enum ReperaControlTarget: String, AppEnum {
    case today
    case live
    case tools
    case exercises

    static var typeDisplayRepresentation = TypeDisplayRepresentation("Pantallas de Repera")
    static var caseDisplayRepresentations: [ReperaControlTarget: DisplayRepresentation] = [
        .today: "Entrenamiento de hoy",
        .live: "Comenzar",
        .tools: "Temporizador",
        .exercises: "Ejercicios"
    ]
}

struct ReperaControlOpenIntent: OpenIntent, TargetContentProvidingIntent {
    static var title: LocalizedStringResource = "Abrir Repera"

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
