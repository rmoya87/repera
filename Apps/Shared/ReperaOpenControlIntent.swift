import AppIntents

/// Acción de apertura, sin efectos secundarios sobre HealthKit, GPS o sesiones.
enum ReperaControlScreen: String, AppEnum {
    case home

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Repera"
    static var caseDisplayRepresentations: [ReperaControlScreen: DisplayRepresentation] = [
        .home: "Inicio"
    ]
}

struct ReperaOpenControlIntent: OpenIntent {
    static var title: LocalizedStringResource = "Abrir Repera"

    @Parameter(title: "Pantalla")
    var target: ReperaControlScreen

    init() { target = .home }
}
