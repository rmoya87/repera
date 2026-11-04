import AppIntents

/// Acción de apertura, sin efectos secundarios sobre HealthKit, GPS o sesiones.
enum ReperaControlScreen: String, AppEnum {
    case home

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Repera"
    static let caseDisplayRepresentations: [ReperaControlScreen: DisplayRepresentation] = [
        .home: "Inicio"
    ]
}

struct ReperaOpenControlIntent: OpenIntent {
    static let title: LocalizedStringResource = "Abrir Repera"

    @Parameter(title: "Pantalla")
    var target: ReperaControlScreen

    init() { target = .home }
}
