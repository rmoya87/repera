import SwiftUI

/// Tokens del Apple Watch, espejo de `OG` en `Apps/Repera/Sources/Theme.swift`.
/// La complicación (otro target) conserva su propio verde de marca en el logo.
enum WatchTheme {
    /// `OG.accent` (#30D158).
    static let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)
    /// `OG.onAccent`: texto e iconos sobre relleno verde.
    static let onAccent = Color.black
    static let warning = Color.orange
    static let cardFill = Color.white.opacity(0.07)
    static let neutralFill = Color(white: 0.18)
}
