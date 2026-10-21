import ReperaDomain
import SwiftUI
import UIKit

/// Tokens adaptativos: día (claro) y noche (oscuro) según el sistema.
/// Comunes a Diario, Center, progreso, modales y navegación.
enum OG {
    /// Lienzo de pantalla. Día = gris agrupado (como Ajustes de Apple); noche = negro.
    /// Las secciones / cards usan `surface` encima para diferenciarse (mismo patrón que en noche).
    static let bg = adaptive(
        light: UIColor(red: 242 / 255, green: 245 / 255, blue: 243 / 255, alpha: 1),
        dark: UIColor.black
    )
    static let bgEl = adaptive(
        light: UIColor(red: 235 / 255, green: 239 / 255, blue: 237 / 255, alpha: 1),
        dark: UIColor(red: 12 / 255, green: 12 / 255, blue: 12 / 255, alpha: 1)
    )
    /// Cards / filas de lista agrupada. Día = blanco sobre `bg` gris; noche = gris sobre negro.
    static let surface = adaptive(
        light: UIColor.white,
        dark: UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
    )
    static let surface2 = adaptive(
        light: UIColor(red: 242 / 255, green: 245 / 255, blue: 243 / 255, alpha: 1),
        dark: UIColor(red: 44 / 255, green: 44 / 255, blue: 46 / 255, alpha: 1)
    )
    static let surface3 = adaptive(
        light: UIColor(red: 220 / 255, green: 228 / 255, blue: 223 / 255, alpha: 1),
        dark: UIColor(red: 58 / 255, green: 58 / 255, blue: 60 / 255, alpha: 1)
    )

    static let label = adaptive(
        light: UIColor(red: 23 / 255, green: 38 / 255, blue: 32 / 255, alpha: 1),
        dark: UIColor(red: 245 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
    )
    /// UIKit (p. ej. `UITextField`): negro en día, casi blanco en noche.
    static let labelUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 245 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
            : UIColor(red: 23 / 255, green: 38 / 255, blue: 32 / 255, alpha: 1)
    }
    static let label2 = adaptive(
        light: UIColor(red: 93 / 255, green: 110 / 255, blue: 99 / 255, alpha: 1),
        dark: UIColor(red: 174 / 255, green: 174 / 255, blue: 178 / 255, alpha: 1)
    )
    static let label3 = adaptive(
        light: UIColor(red: 137 / 255, green: 153 / 255, blue: 143 / 255, alpha: 1),
        dark: UIColor(red: 120 / 255, green: 120 / 255, blue: 128 / 255, alpha: 1)
    )

    static let accent = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255) // #30d158
    static let onAccent = Color.black
    static let yellow = Color(red: 1, green: 214 / 255, blue: 10 / 255)
    static let orange = Color(red: 1, green: 159 / 255, blue: 10 / 255)
    static let blue = Color(red: 10 / 255, green: 132 / 255, blue: 1)
    static let red = Color(red: 1, green: 69 / 255, blue: 58 / 255)

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let radiusCard: CGFloat = 14
    static let radiusLG: CGFloat = 16
    /// Esquinas de sheets: radio continuo al estilo sheet nativo del iPhone.
    static let sheetCornerRadius: CGFloat = 44
    /// Diámetro liquid glass de botones en cabecera de contenido (= topbar del sistema).
    static let toolbarGlassSize: CGFloat = 44
    /// Glifo en esos botones glass.
    static let toolbarGlassIcon: CGFloat = 18
    static let pad: CGFloat = 16
}

/// Título de sección **encima** de una `OGCard` (gris, estilo Ajustes / Form).
struct OGCardSectionTitle: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(OG.label2)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

struct OGCard<Content: View>: View {
    var padding: CGFloat = OG.pad
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous).stroke(OG.surface3.opacity(0.75), lineWidth: 0.7))
    }
}

struct OGScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            OG.bg.ignoresSafeArea()
            content()
        }
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

/// Barra fija superior: título (+ subtítulo) a la izquierda; acciones a la derecha en la misma fila.
struct OGFixedTopBar<Trailing: View>: View {
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: subtitle == nil ? .center : .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    // Mismo cuerpo que el large title del sistema (p. ej. Ejercicios).
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(OG.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, OG.pad)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.bg.opacity(0.001))
    }
}

/// Cabecera de página estilo Inicio / Progreso: título grande en el scroll.
struct OGPageHeader<Leading: View, Trailing: View>: View {
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            leading()
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(OG.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

extension OGPageHeader where Leading == EmptyView, Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, leading: { EmptyView() }, trailing: { EmptyView() })
    }
}

extension OGPageHeader where Leading == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.init(title: title, subtitle: subtitle, leading: { EmptyView() }, trailing: trailing)
    }
}

extension View {
    /// Lista agrupada nativa (`insetGrouped`): fondo `OG.bg`, filas `OG.surface`.
    /// Las cajas de sección las dibuja el sistema; no envolver filas en `OGCard`.
    func ogListChrome() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background {
                OG.bg.ignoresSafeArea()
            }
            .listRowBackground(OG.surface)
            .tint(OG.accent)
            .contentMargins(.all, EdgeInsets(top: 0, leading: OG.pad, bottom: 0, trailing: OG.pad), for: .scrollContent)
            .listSectionSpacing(12)
    }

    /// Top bar transparente: sin fondo sólido al hacer scroll.
    func ogTransparentNav() -> some View {
        self
            .toolbarBackground(.hidden, for: .navigationBar)
    }

    /// Topbar fijo como Ejercicios: título large que colapsa; botones del toolbar no se van con el scroll.
    /// Usar cuando hay volver / acciones en la barra (el título queda debajo de esos botones).
    /// Fuerza la barra visible: Inicio/Progreso ocultan el toolbar del sistema (`ogContentTitleNav`);
    /// sin esto, al pushear Ajustes/Historial queda el hueco del large title sin el texto «Ajustes».
    func ogPinnedTransparentNav(_ title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.visible, for: .navigationBar)
            .ogTransparentNav()
    }

    /// Título arriba del todo (sin franja vacía). Acciones opcionales a la derecha, misma fila.
    /// Para roots sin volver, o cuando no hay botones encima del título.
    func ogFixedTopBar(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> some View
    ) -> some View {
        self
            .ogContentTitleNav()
            .safeAreaInset(edge: .top, spacing: 0) {
                OGFixedTopBar(title: title, subtitle: subtitle, trailing: trailing)
            }
    }

    func ogFixedTopBar(_ title: String, subtitle: String? = nil) -> some View {
        ogFixedTopBar(title, subtitle: subtitle) { EmptyView() }
    }

    /// Título en el contenido (`OGPageHeader`); sin barra del sistema.
    func ogContentTitleNav() -> some View {
        self
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .ogTransparentNav()
            .toolbar(.hidden, for: .navigationBar)
    }

    /// Cabecera de página dentro de `List` (misma geometría que Inicio / Progreso).
    func ogListPageHeaderRow() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            .listRowSeparator(.hidden)
    }

    /// Segmented control a ancho de contenido (sin doble padding respecto a `ogListChrome`).
    func ogSegmentedListRow() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
            .listRowSeparator(.hidden)
    }

    /// Card / fila custom a ancho de `ogListChrome` (leading 0: el margen ya lo pone el chrome).
    func ogCardListRow(top: CGFloat = 4, bottom: CGFloat = 4) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 0, bottom: bottom, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    /// Sheet tipo menú: alto = contenido (no pantalla completa).
    /// El contenido raíz debe tener tamaño intrínseco (VStack), no `List`/`NavigationStack` vacío.
    /// `expanded: true` → pantalla casi completa (p. ej. push a Favoritos).
    /// `freezeHeight: true` → deja de reaccionar a preferencias (p. ej. mientras hay galería).
    func ogFittedSheet(expanded: Bool = false, freezeHeight: Bool = false) -> some View {
        modifier(OGFittedSheetModifier(expanded: expanded, freezeHeight: freezeHeight))
    }

    /// Esquinas + fondo Liquid Glass del sheet (`.presentationBackground`).
    /// Usar en **todas** las `.sheet` (fitted o medium/large). No duplicar glass en botones del `.toolbar`.
    func ogSheetCorners() -> some View {
        self
            .presentationCornerRadius(OG.sheetCornerRadius)
            .presentationBackground {
                RoundedRectangle(cornerRadius: OG.sheetCornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(
                        .regular,
                        in: .rect(cornerRadius: OG.sheetCornerRadius)
                    )
                    .ignoresSafeArea()
            }
    }

    /// Sheet a altura media/grande con el mismo glass y radio que el sistema.
    func ogSheetChrome(
        detents: Set<PresentationDetent> = [.medium, .large],
        dragIndicator: Visibility = .visible
    ) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(dragIndicator)
            .ogSheetCorners()
    }

    /// Confirmación corta (eliminar, vaciar…) con liquid glass vía `ogFittedSheet`.
    func ogConfirmSheetChrome() -> some View {
        ogFittedSheet()
    }

    /// Mide la altura del contenido y la publica para `ogFittedSheet`.
    func ogFittedHeight() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(key: OGFittedSheetHeightKey.self, value: proxy.size.height)
            }
        }
    }
}

private struct OGFittedSheetHeightKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct OGFittedSheetModifier: ViewModifier {
    var expanded: Bool
    var freezeHeight: Bool = false
    @State private var contentHeight: CGFloat = 280
    @State private var frozenHeight: CGFloat?

    private var maxHeight: CGFloat {
        let height = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen.bounds.height
            ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen.bounds.height
            ?? 844
        return (height * 0.9).rounded()
    }

    private var activeHeight: CGFloat {
        frozenHeight ?? contentHeight
    }

    private var fittedDetent: PresentationDetent {
        // Margen para el drag indicator / safe area inferior.
        let h = min(max(activeHeight + 28, 160), maxHeight)
        return .height(h)
    }

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(OGFittedSheetHeightKey.self) { height in
                guard height > 1 else { return }
                if freezeHeight {
                    if frozenHeight == nil {
                        frozenHeight = contentHeight > 1 ? contentHeight : height
                    }
                    return
                }
                if frozenHeight != nil { frozenHeight = nil }
                guard abs(height - contentHeight) > 8 else { return }
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    contentHeight = height
                }
            }
            .onChange(of: freezeHeight) { _, freeze in
                if freeze {
                    frozenHeight = contentHeight
                } else {
                    frozenHeight = nil
                }
            }
            .presentationDetents(expanded ? [.large] : [fittedDetent])
            .presentationDragIndicator(.visible)
            .ogSheetCorners()
    }
}

/// Acción swipe: por defecto destructiva (rojo). Las X de quitar usan `tint: OG.label`.
struct OGSwipeDeleteButton: View {
    var systemImage: String = "trash"
    var accessibilityLabel: String = "Eliminar"
    var tint: Color = OG.red
    var action: () -> Void

    var body: some View {
        Button(role: tint == OG.red ? .destructive : nil, action: action) {
            Image(systemName: systemImage)
        }
        .tint(tint)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Modal de confirmación (eliminar / vaciar…) con liquid glass.
struct OGConfirmSheet: View {
    var systemImage: String = "trash.circle.fill"
    var iconTint: Color = OG.red
    var title: String
    var message: String
    var confirmTitle: String = "Eliminar"
    var confirmTint: Color = OG.red
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(iconTint)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(OG.label)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(OG.label2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .glassEffect(.regular.tint(confirmTint).interactive(), in: .capsule)
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Text("Cancelar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(OG.label)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, OG.pad)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .ogFittedHeight()
        .ogConfirmSheetChrome()
    }
}

/// Botón de icono en top bar.
/// En la barra del sistema no aplicar glass (iOS ya pone el círculo); en cabeceras
/// custom del contenido usar `appliesGlass: true`. SF Symbols sin `.circle` embebido.
struct OGToolbarGlassButton: View {
    var systemName: String
    var accessibilityLabel: String
    var tint: Color = OG.label
    /// Tamaño del glifo. `nil` → 18 con glass de contenido, 17 en toolbar del sistema.
    var iconSize: CGFloat? = nil
    /// Diámetro del hit / glass. `nil` → 44 con glass de contenido (igual que topbar iOS).
    var hitSize: CGFloat? = nil
    /// Solo en cabeceras dentro del contenido. En `.toolbar` dejar `false`.
    var appliesGlass: Bool = false
    /// Tinte del círculo glass (p. ej. verde acento en el + de añadir).
    var glassTint: Color? = nil
    var action: () -> Void

    private var resolvedIcon: CGFloat {
        iconSize ?? (appliesGlass ? OG.toolbarGlassIcon : 17)
    }

    private var resolvedHit: CGFloat {
        hitSize ?? (appliesGlass ? OG.toolbarGlassSize : 36)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: resolvedIcon, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.monochrome)
                .frame(width: resolvedHit, height: resolvedHit)
                .contentShape(Circle())
                .modifier(OGToolbarGlassModifier(enabled: appliesGlass, tint: glassTint))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Liquid Glass manual (`.glassEffect`) solo fuera del `.toolbar` del sistema; ahí iOS 27 ya envuelve el ítem.
private struct OGToolbarGlassModifier: ViewModifier {
    var enabled: Bool
    var tint: Color?

    func body(content: Content) -> some View {
        if enabled {
            if let tint {
                content.glassEffect(.regular.tint(tint).interactive(), in: .circle)
            } else {
                content.glassEffect(.regular.interactive(), in: .circle)
            }
        } else {
            content
        }
    }
}

/// Botón de cierre unificado: X en color de etiqueta (negro día / blanco noche).
/// Por defecto con liquid glass (cabeceras de sheet / contenido). En `.toolbar` del sistema: `large: false`.
struct CloseToolbarButton: View {
    var action: () -> Void
    /// Cabecera de página en el contenido (aplica glass). Default `true`.
    var large: Bool = true

    var body: some View {
        OGToolbarGlassButton(
            systemName: "xmark",
            accessibilityLabel: "Cerrar",
            tint: OG.label,
            appliesGlass: large,
            action: action
        )
    }
}

/// Botón volver (chevron) para subpáginas con nav oculta (`ogContentTitleNav`).
struct BackToolbarButton: View {
    var action: () -> Void
    var large: Bool = true

    var body: some View {
        OGToolbarGlassButton(
            systemName: "chevron.left",
            accessibilityLabel: "Volver",
            tint: OG.label,
            appliesGlass: large,
            action: action
        )
    }
}

/// Subpágina: topbar con volver (+ trailing opcional) y título grande debajo.
struct OGBackPageHeader<Trailing: View>: View {
    var title: String
    var subtitle: String? = nil
    var onBack: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                BackToolbarButton(action: onBack, large: true)
                Spacer(minLength: 8)
                trailing()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(OG.label2)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

extension OGBackPageHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, onBack: @escaping () -> Void) {
        self.init(title: title, subtitle: subtitle, onBack: onBack, trailing: { EmptyView() })
    }
}

/// Stepper − / valor / +: respuesta inmediata, repetición al mantener, toque en el número → teclado.
struct OGRepeatStepper: View {
    var display: String
    var enabled: Bool = true
    /// Filas densas (peso/reps en Form): botones algo más estrechos; la altura sigue en 48 pt.
    var compact: Bool = false
    var keyboard: UIKeyboardType = .decimalPad
    var onMinus: () -> Void
    var onPlus: () -> Void
    /// Texto del centro al confirmar (vacío / "—" → nil o 0 según el caller).
    var onCommitText: (String) -> Void

    @State private var editing = false
    @State private var draft = ""
    @State private var holdTask: Task<Void, Never>?
    @State private var holdingSide: HoldSide?
    /// Evita que el `Button` dispare otro paso al soltar tras una repetición por mantener.
    @State private var holdDidRepeat = false

    private enum HoldSide { case minus, plus }

    var body: some View {
        HStack(spacing: 0) {
            holdButton(systemName: "minus", side: .minus, action: onMinus)
            centerValue
            holdButton(systemName: "plus", side: .plus, action: onPlus)
        }
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(enabled ? 1 : 0.45)
        .disabled(!enabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Valor")
        .accessibilityValue(display)
        .accessibilityAdjustableAction { direction in
            guard enabled else { return }
            switch direction {
            case .increment: onPlus()
            case .decrement: onMinus()
            @unknown default: break
            }
        }
        .onDisappear { stopHold() }
    }

    private var controlHeight: CGFloat { 48 }
    private var buttonWidth: CGFloat { compact ? 36 : 44 }

    @ViewBuilder
    private var centerValue: some View {
        if editing {
            OGNumericTextField(
                text: $draft,
                allowsDecimal: keyboard == .decimalPad || keyboard == .numbersAndPunctuation,
                textAlignment: .center,
                onCommit: { commitEdit() }
            )
            .font(.system(size: 18, weight: .semibold).monospacedDigit())
            .frame(maxWidth: .infinity)
            .frame(height: controlHeight)
        } else {
            Text(display)
                .font(.system(size: 18, weight: .semibold).monospacedDigit())
                .foregroundStyle(OG.label)
                .frame(maxWidth: .infinity)
                .frame(height: controlHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard enabled else { return }
                    draft = (display == "—" || display.isEmpty) ? "" : display
                    editing = true
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    /// Tap → `Button`; mantener → repetición sin `highPriorityGesture` (no bloquea scroll vertical).
    private func holdButton(systemName: String, side: HoldSide, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            if holdDidRepeat {
                holdDidRepeat = false
                return
            }
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: compact ? 14 : 15, weight: .bold))
                .foregroundStyle(OG.label2)
                .frame(width: buttonWidth, height: controlHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.28, pressing: { pressing in
            guard enabled else { return }
            if pressing {
                if holdingSide != side {
                    startHold(side: side, action: action)
                }
            } else {
                stopHold()
            }
        }, perform: {})
        .accessibilityLabel(side == .minus ? "Menos" : "Más")
    }

    private func startHold(side: HoldSide, action: @escaping () -> Void) {
        stopHold()
        holdingSide = side
        holdDidRepeat = false
        holdTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled else { return }
            holdDidRepeat = true
            action()
            var interval: UInt64 = 90_000_000
            while !Task.isCancelled {
                action()
                try? await Task.sleep(nanoseconds: interval)
                interval = max(28_000_000, interval * 82 / 100)
            }
        }
    }

    private func stopHold() {
        holdTask?.cancel()
        holdTask = nil
        holdingSide = nil
    }

    private func commitEdit() {
        guard editing else { return }
        onCommitText(draft.trimmingCharacters(in: .whitespacesAndNewlines))
        editing = false
    }
}

/// Teclado de números con accesorio nativo Siguiente / ✓.
/// A diferencia de numberPad SwiftUI, siempre permite confirmar el último campo.
struct OGNumericTextField: UIViewRepresentable {
    @Binding var text: String
    var allowsDecimal: Bool = true
    var allowsTimeSeparator: Bool = false
    var textAlignment: NSTextAlignment = .center
    var fontSize: CGFloat = 15
    var textColor: UIColor? = nil
    var autoFocus: Bool = true
    var isFocused: Bool? = nil
    var submitTitle: String = "✓"
    var onFocused: () -> Void = {}
    var onFocusLost: (() -> Void)? = nil
    var onCommit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            allowsDecimal: allowsDecimal,
            allowsTimeSeparator: allowsTimeSeparator,
            onFocused: onFocused,
            onFocusLost: onFocusLost,
            onCommit: onCommit
        )
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        context.coordinator.field = field
        configure(field, coordinator: context.coordinator)
        field.text = text
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barTintColor = UIColor.systemBackground
        var buttons: [UIBarButtonItem] = []
        if allowsTimeSeparator {
            let colon = UIBarButtonItem(
                title: ":",
                style: .plain,
                target: context.coordinator,
                action: #selector(Coordinator.insertColon)
            )
            buttons.append(colon)
        }
        buttons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        let submit = UIBarButtonItem(
            title: submitTitle,
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.commitFromKeyboard)
        )
        submit.tintColor = UIColor(OG.accent)
        buttons.append(submit)
        toolbar.items = buttons
        field.inputAccessoryView = toolbar
        context.coordinator.submitButton = submit

        if autoFocus && isFocused == nil {
            DispatchQueue.main.async { field.becomeFirstResponder(); field.selectAll(nil) }
        }
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        let c = context.coordinator
        c.text = $text
        c.allowsDecimal = allowsDecimal
        c.allowsTimeSeparator = allowsTimeSeparator
        c.onFocused = onFocused
        c.onFocusLost = onFocusLost
        c.onCommit = onCommit
        c.submitButton?.title = submitTitle
        configure(field, coordinator: c)
        if field.text != text {
            field.text = text
        }
        if let isFocused {
            c.desiredFocus = isFocused
            if isFocused && !field.isFirstResponder {
                DispatchQueue.main.async { [weak field, weak c] in
                    guard c?.desiredFocus == true else { return }
                    field?.becomeFirstResponder()
                    field?.selectAll(nil)
                }
            } else if !isFocused && field.isFirstResponder {
                DispatchQueue.main.async { [weak field, weak c] in
                    guard c?.desiredFocus == false else { return }
                    field?.resignFirstResponder()
                }
            }
        }
    }

    private func configure(_ field: UITextField, coordinator: Coordinator) {
        field.keyboardType = allowsTimeSeparator ? .numberPad : (allowsDecimal ? .decimalPad : .numberPad)
        field.keyboardAppearance = .default
        field.textAlignment = textAlignment
        field.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold)
        field.textColor = textColor ?? OG.labelUIColor
        field.tintColor = UIColor(OG.accent)
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.returnKeyType = .done
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var allowsDecimal: Bool
        var allowsTimeSeparator: Bool
        var onFocused: () -> Void
        var onFocusLost: (() -> Void)?
        var onCommit: () -> Void
        var desiredFocus: Bool?
        weak var field: UITextField?
        weak var submitButton: UIBarButtonItem?

        init(
            text: Binding<String>,
            allowsDecimal: Bool,
            allowsTimeSeparator: Bool,
            onFocused: @escaping () -> Void,
            onFocusLost: (() -> Void)?,
            onCommit: @escaping () -> Void
        ) {
            self.text = text
            self.allowsDecimal = allowsDecimal
            self.allowsTimeSeparator = allowsTimeSeparator
            self.onFocused = onFocused
            self.onFocusLost = onFocusLost
            self.onCommit = onCommit
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            onFocused()
            textField.selectAll(nil)
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
            (onFocusLost ?? onCommit)()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            commitFromKeyboard()
            return false
        }

        @objc func commitFromKeyboard() {
            guard let field else { return }
            text.wrappedValue = field.text ?? ""
            onCommit()
            // Para campos autónomos; en una fila con Siguiente, el foco
            // pasa al próximo campo desde la propia acción onCommit.
            if desiredFocus == nil { field.resignFirstResponder() }
        }

        @objc func insertColon() {
            field?.insertText(":")
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            if string.isEmpty { return true }
            let characters = "0123456789"
                + (allowsDecimal ? ".," : "")
                + (allowsTimeSeparator ? ":" : "")
            let allowed = CharacterSet(charactersIn: characters)
            guard string.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
            let current = textField.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            let next = current.replacingCharacters(in: swiftRange, with: string)
            if !allowsTimeSeparator && allowsDecimal {
                if next.filter({ $0 == "." || $0 == "," }).count > 1 { return false }
            }
            if allowsTimeSeparator && next.filter({ $0 == ":" }).count > 1 { return false }
            return true
        }
    }
}

extension View {
    /// Teclado con **intro** para `TextField` SwiftUI (sin barra «Listo»).
    /// Ojo: no combines con `.keyboardType(.decimalPad)` — ese gana y pierdes el intro.
    func ogNumericKeyboard(
        allowsDecimal: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) -> some View {
        self
            .keyboardType(allowsDecimal ? .decimalPad : .numberPad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        onSubmit?()
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                    }
                    .tint(OG.accent)
                    .accessibilityLabel("Confirmar número")
                }
            }
    }

    /// Compat: antes era la barra «Listo»; ahora cierra con intro del teclado.
    func ogKeyboardDone(action: @escaping () -> Void = {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }) -> some View {
        ogNumericKeyboard(allowsDecimal: true, onSubmit: action)
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

    /// Cabecera de semana en calendario: «Octubre», «Octubre – noviembre», o con año si no es el actual.
    static func monthHeadline(from start: Date, to end: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "LLLL"

        let startMonth = calendar.component(.month, from: start)
        let endMonth = calendar.component(.month, from: end)
        let startYear = calendar.component(.year, from: start)
        let endYear = calendar.component(.year, from: end)
        let currentYear = calendar.component(.year, from: Date())

        func capitalizedMonth(_ date: Date) -> String {
            let raw = f.string(from: date)
            guard let first = raw.first else { return raw }
            return String(first).uppercased() + raw.dropFirst()
        }

        if startYear == endYear, startMonth == endMonth {
            let name = capitalizedMonth(start)
            return startYear == currentYear ? name : "\(name) \(startYear)"
        }
        if startYear == endYear {
            let title = "\(capitalizedMonth(start)) – \(f.string(from: end))"
            return startYear == currentYear ? title : "\(title) \(startYear)"
        }
        return "\(capitalizedMonth(start)) \(startYear) – \(capitalizedMonth(end)) \(endYear)"
    }

    static func short(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    /// Subtítulo de detalle: «Viernes 16 octubre · 7:03–8:00».
    static func sessionSubtitle(start: Date, end: Date?) -> String {
        var parts = [long(start)]
        if let end {
            parts.append("\(time(start))–\(time(end))")
        } else {
            parts.append(time(start))
        }
        return parts.joined(separator: " · ")
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }

    /// Minutos desde medianoche → "18:30".
    static func time(minutesFromMidnight: Int) -> String {
        let start = Calendar.current.startOfDay(for: Date())
        let date = Calendar.current.date(byAdding: .minute, value: minutesFromMidnight, to: start) ?? Date()
        return time(date)
    }
}

// MARK: - Series compactas (incluido en Theme.swift para targets Xcode existentes)

/// Identidad estable del campo para avanzar horizontalmente con la tecla Siguiente.
struct OGSetFieldID: Hashable {
    var rowID: UUID
    var column: Int
}

/// Cabecera compacta compartida por planificación, registro final y sesión en curso.
struct OGSetEntryHeader: View {
    var firstTitle: String
    var secondTitle: String? = nil
    var showsConfirmation = false
    var showsRIR = false

    var body: some View {
        HStack(spacing: 4) {
            caption("SERIE").frame(width: 30)
            caption("ANTERIOR").frame(width: 52)
            caption(firstTitle.uppercased()).frame(maxWidth: .infinity)
            if let secondTitle {
                caption(secondTitle.uppercased()).frame(maxWidth: .infinity)
            }
            if showsRIR {
                caption("RIR").frame(width: 43)
            }
            if showsConfirmation {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(OG.label3)
                    .frame(width: 34)
                    .accessibilityHidden(true)
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(OG.label3)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .multilineTextAlignment(.center)
    }
}

/// Misma retícula para editar objetivos y apuntar series reales. Sin +/-.
struct OGSetEntryRow: View {
    var rowID: UUID
    var index: Int
    var previous: String?
    var firstValue: String
    var secondValue: String? = nil
    var firstAllowsDecimal = true
    var secondAllowsDecimal = false
    var enabled = true
    var showsConfirmation = false
    var completed = false
    var rir: Double? = nil
    var showsRIR = false
    var onRIRChange: (Double?) -> Void = { _ in }
    var focus: FocusState<OGSetFieldID?>.Binding
    var onFirstCommit: (String) -> Void
    var onSecondCommit: (String) -> Void = { _ in }
    var onConfirm: () -> Void = {}

    var body: some View {
        HStack(spacing: 4) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(OG.label)
                .frame(width: 30, height: 36)
                .background(OG.surface2, in: Circle())
                .accessibilityLabel("Serie \(index)")

            Text(previous ?? "—")
                .font(.system(size: 10, weight: .medium).monospacedDigit())
                .foregroundStyle(previous == nil ? OG.label3 : OG.label2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 52, height: 44)
                .accessibilityLabel(previous.map { "Anterior: \($0)" } ?? "Sin registro anterior")

            OGSetNumericCell(
                display: firstValue,
                allowsDecimal: firstAllowsDecimal,
                fieldID: OGSetFieldID(rowID: rowID, column: 0),
                nextID: secondValue == nil ? nil : OGSetFieldID(rowID: rowID, column: 1),
                enabled: enabled && !completed,
                focus: focus,
                onCommit: onFirstCommit,
                onLastSubmit: onConfirm
            )
            .frame(maxWidth: .infinity)

            if let secondValue {
                OGSetNumericCell(
                    display: secondValue,
                    allowsDecimal: secondAllowsDecimal,
                    fieldID: OGSetFieldID(rowID: rowID, column: 1),
                    nextID: nil,
                    enabled: enabled && !completed,
                    focus: focus,
                    onCommit: onSecondCommit,
                    onLastSubmit: onConfirm
                )
                .frame(maxWidth: .infinity)
            }

            if showsRIR {
                Menu {
                    Button("Sin RIR") { onRIRChange(nil) }
                    ForEach(0...5, id: \.self) { value in
                        Button("RIR \(value)") { onRIRChange(Double(value)) }
                    }
                } label: {
                    Text(rir.map { "\(Int($0.rounded()))" } ?? "—")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(rir == nil ? OG.label3 : OG.label)
                        .frame(width: 43, height: 44)
                        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(!enabled || completed)
                .accessibilityLabel("RIR serie \(index)")
            }

            if showsConfirmation {
                Button(action: onConfirm) {
                    Image(systemName: completed ? "checkmark.circle.fill" : "checkmark")
                        .font(.system(size: completed ? 20 : 17, weight: .bold))
                        .foregroundStyle(completed ? OG.onAccent : OG.accent)
                        .frame(width: 34, height: 44)
                        .background(
                            completed ? OG.accent : OG.surface2,
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(completed ? "Serie completada" : "Completar serie \(index)")
            }
        }
    }

    static func previousText(_ set: ExerciseLastSession.WorkSet?) -> String? {
        guard let set else { return nil }
        if let weight = set.weightKg, weight > 0 {
            return "\(String(format: "%g", weight)) kg"
        }
        if let duration = set.durationSeconds, duration > 0 {
            return DurationText.format(duration)
        }
        return "\(set.reps) rep"
    }
}

/// Campo con el teclado nativo de Repera y retorno contextual Siguiente / Listo.
/// La confirmación consolida el dato antes de mover el foco o marcar la serie.
private struct OGSetNumericCell: View {
    var display: String
    var allowsDecimal: Bool
    var fieldID: OGSetFieldID
    var nextID: OGSetFieldID?
    var enabled: Bool
    var focus: FocusState<OGSetFieldID?>.Binding
    var onCommit: (String) -> Void
    var onLastSubmit: () -> Void

    @State private var draft = ""

    var body: some View {
        OGNumericTextField(
            text: $draft,
            allowsDecimal: allowsDecimal,
            allowsTimeSeparator: display.contains(":"),
            textAlignment: .center,
            fontSize: 17,
            autoFocus: false,
            isFocused: focus.wrappedValue == fieldID,
            submitTitle: nextID == nil ? "✓" : "Siguiente",
            onFocused: { focus.wrappedValue = fieldID },
            onFocusLost: {
                onCommit(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                if focus.wrappedValue == fieldID { focus.wrappedValue = nil }
            },
            onCommit: {
                onCommit(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                if let nextID {
                    focus.wrappedValue = nextID
                } else {
                    focus.wrappedValue = nil
                    onLastSubmit()
                }
            }
        )
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .opacity(enabled ? 1 : 0.55)
        .disabled(!enabled)
        .onAppear { draft = normalized(display) }
        .onChange(of: display) { _, newValue in
            if focus.wrappedValue != fieldID {
                draft = normalized(newValue)
            }
        }
        .onChange(of: draft) { _, value in
            let valid = value.filter {
                $0.isNumber
                    || (allowsDecimal && ($0 == "." || $0 == ","))
                    || (display.contains(":") && $0 == ":")
            }
            if valid != value { draft = valid }
        }
    }

    private func normalized(_ value: String) -> String {
        value == "—" ? "" : value
    }
}


/// Número editable sin botones +/- para configurar duración, rondas e intervalos.
/// Emplea el mismo teclado contextual que la retícula de series.
struct OGFormatNumberField: View {
    var title: String
    var unit: String = ""
    @Binding var value: Int
    var range: ClosedRange<Int>
    var focus: FocusState<OGSetFieldID?>.Binding
    var fieldID: OGSetFieldID
    var nextID: OGSetFieldID? = nil
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(OG.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 2) {
                OGNumericTextField(
                    text: $draft,
                    allowsDecimal: false,
                    fontSize: 16,
                    autoFocus: false,
                    isFocused: focus.wrappedValue == fieldID,
                    submitTitle: nextID == nil ? "✓" : "Siguiente",
                    onFocused: { focus.wrappedValue = fieldID },
                    onFocusLost: {
                        commit()
                        if focus.wrappedValue == fieldID { focus.wrappedValue = nil }
                    },
                    onCommit: {
                        commit()
                        focus.wrappedValue = nextID
                    }
                )
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(OG.label3)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 7)
            .frame(maxWidth: .infinity)
            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .onAppear { draft = String(value) }
        .onChange(of: value) { _, newValue in
            if focus.wrappedValue != fieldID {
                draft = String(newValue)
            }
        }
        .onChange(of: draft) { _, text in
            let cleaned = text.filter { $0.isNumber }
            if cleaned != text { draft = cleaned }
        }
    }

    private func commit() {
        if let entered = Int(draft) {
            value = min(range.upperBound, max(range.lowerBound, entered))
        }
        draft = String(value)
    }
}
