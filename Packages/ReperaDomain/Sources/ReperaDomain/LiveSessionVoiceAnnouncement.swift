import Foundation

/// Mensajes breves para las acciones explícitas de Comenzar.
/// Se pronuncian solo al cambiar de fase por una acción del usuario, nunca
/// cuando SwiftUI vuelve a dibujar la pantalla o se restaura una sesión.
public enum LiveSessionVoiceAnnouncement {
    public static func started(sportName: String) -> String {
        let spokenSport = sportName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spokenSport.isEmpty else { return "Entrenamiento iniciado." }
        return "Iniciando \(spokenSport.lowercased(with: Locale(identifier: "es_ES")))."
    }

    public static let paused = "Entrenamiento pausado."
    public static let resumed = "Entrenamiento reanudado."
    public static let finished = "Entrenamiento finalizado."
}
