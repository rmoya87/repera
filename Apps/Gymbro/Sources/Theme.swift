import SwiftUI

/// Tokens alineados con openGym `index.css` (dark default).
enum OG {
    static let bg = Color.black
    static let bgEl = Color(red: 14 / 255, green: 14 / 255, blue: 16 / 255)
    static let surface = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let surface2 = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
    static let surface3 = Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255)

    static let label = Color.white
    static let label2 = Color.white.opacity(0.60)
    static let label3 = Color.white.opacity(0.32)

    static let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255) // #30d158
    static let onAccent = Color.black
    static let yellow = Color(red: 1, green: 214 / 255, blue: 10 / 255)
    static let orange = Color(red: 1, green: 159 / 255, blue: 10 / 255)
    static let blue = Color(red: 10 / 255, green: 132 / 255, blue: 1)
    static let red = Color(red: 1, green: 69 / 255, blue: 58 / 255)

    static let radiusCard: CGFloat = 14
    static let radiusLG: CGFloat = 16
    static let pad: CGFloat = 16
}

struct OGCard<Content: View>: View {
    var padding: CGFloat = OG.pad
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }
}

struct OGScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            OG.bg.ignoresSafeArea()
            content()
        }
        .preferredColorScheme(.dark)
    }
}

struct OGPrimaryButton: View {
    let title: String
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: compact ? 15 : 17, weight: .semibold))
                .foregroundStyle(OG.onAccent)
                .padding(.horizontal, compact ? 14 : 18)
                .padding(.vertical, compact ? 8 : 12)
                .background(OG.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Cabecera de página estilo Inicio: título grande en el scroll (no en la top bar opaca).
struct OGPageHeader<Trailing: View>: View {
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(OG.label)
                    .tracking(-0.4)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
}

extension OGPageHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

extension View {
    /// Lista agrupada estilo openGym (superficie #1c1c1e sobre negro).
    func ogListChrome() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(OG.bg)
            .listRowBackground(OG.surface)
            .tint(OG.accent)
    }

    /// Top bar transparente: sin fondo sólido al hacer scroll.
    func ogTransparentNav() -> some View {
        self
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    /// Título en el contenido (`OGPageHeader`); barra vacía y transparente.
    func ogContentTitleNav() -> some View {
        self
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .ogTransparentNav()
    }

    /// Cabecera de página dentro de `List` (misma tipografía que Inicio).
    func ogListPageHeaderRow() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: OG.pad, bottom: 8, trailing: OG.pad))
            .listRowSeparator(.hidden)
    }
}

/// Botón de icono en top bar con liquid glass (fondo transparente del nav).
/// Usar SF Symbols *sin* `.circle` embebido: el glass ya aporta el círculo.
struct OGToolbarGlassButton: View {
    var systemName: String
    var accessibilityLabel: String
    var tint: Color = OG.label
    /// Tamaño del glifo.
    var iconSize: CGFloat = 17
    /// Diámetro del hit target / glass.
    var hitSize: CGFloat = 36
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.monochrome)
                .frame(width: hitSize, height: hitSize)
                .contentShape(Circle())
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Botón de cierre unificado: X roja con liquid glass.
struct CloseToolbarButton: View {
    var action: () -> Void
    /// Variante más grande (sheets de plan / entreno).
    var large: Bool = false

    var body: some View {
        OGToolbarGlassButton(
            systemName: "xmark",
            accessibilityLabel: "Cerrar",
            tint: OG.red,
            iconSize: large ? 20 : 17,
            hitSize: large ? 44 : 36,
            action: action
        )
    }
}

enum SpanishDate {
    static func long(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE d MMMM"
        let raw = f.string(from: date)
            .replacingOccurrences(of: " de ", with: " ")
        guard let first = raw.first else { return raw }
        return String(first).uppercased() + raw.dropFirst()
    }

    static func short(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}
