import Observation
import SwiftUI

/// Detecta layout Duo/iPad (raíl vertical nativo del sistema).
/// No dibuja overlays sobre el raíl: status + tabs son de Apple; las
/// acciones contextuales viven en el contenido o en `.toolbar`.
@MainActor
@Observable
final class OGDuoContextRailStore {
    var isExpanded = false
}
