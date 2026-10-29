import ReperaDomain
import SwiftUI

/// Página de Repera Pro. Se integra en la navegación de la app sin sheet.
struct PaywallView: View {
    enum Mode {
        case sheet // Compatibilidad con los flujos existentes; ahora es una página.
        case onboarding
    }

    var mode: Mode = .sheet
    var onContinueFree: (() -> Void)?
    var onPurchaseSuccess: (() -> Void)?

    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedProductID: String?
    @State private var showError = false
    @State private var mascotRaised = false

    private var context: PaywallContext {
        mode == .onboarding ? .onboarding : subscriptions.paywall.context
    }
    private var packages: [CommercialPackageInfo] { subscriptions.offerings.packages }
    private var annual: CommercialPackageInfo? { packages.first(where: \.isAnnual) }
    private var monthly: CommercialPackageInfo? { packages.first(where: { !$0.isAnnual }) }

    private let highlights: [(symbol: String, title: String, detail: String)] = [
        ("chart.line.uptrend.xyaxis", "Tu evolución, al detalle", "Historial completo por ejercicio, marcas y e1RM."),
        ("chart.bar.xaxis", "Entiende cómo progresas", "Todos los periodos, métricas avanzadas y mapa muscular."),
        ("square.stack", "Más espacio para entrenar", "Rutinas, favoritos y ejercicios propios sin límites."),
        ("camera.viewfinder", "Escanea cualquier WOD", "Escáner de pizarras ilimitado y comparativas de resultados."),
        ("arrow.up.right", "Progresa con criterio", "Sugerencias de carga basadas en tus entrenamientos.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    navigationHeader
                    hero
                    benefitSection
                    comparison
                    plansSection
                    secondaryActions
                    legalFooter
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: OG.contentColumnMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                purchaseFooter
            }
            .background(OG.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task {
                // El onboarding no debe disparar de nuevo el paywall global.
                await subscriptions.start()
                await subscriptions.loadOfferings()
                reconcileSelectedProduct()
            }
            .onChange(of: packages.map(\.productID)) { _, _ in
                reconcileSelectedProduct()
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    mascotRaised = true
                }
            }
            .alert("No se pudo completar", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptions.lastErrorMessage ?? "Inténtalo de nuevo.")
            }
        }
    }

    private var navigationHeader: some View {
        HStack(spacing: 12) {
            if mode == .sheet {
                Button {
                    subscriptions.dismissPaywall()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(OG.label)
                .accessibilityLabel("Volver")
            }
            Text("Repera Pro")
                .font(.headline)
                .foregroundStyle(OG.label)
            Spacer()
            Text(mode == .onboarding ? "TU SIGUIENTE PASO" : "DESBLOQUEA MÁS")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(OG.label2)
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Entrena sin límites.")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(OG.label)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Descubre todo lo que hay detrás de cada entrenamiento.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ReperaMascot(pose: .hero, maxHeight: 152)
                .frame(width: 142, height: 160)
                .offset(y: mascotRaised ? -5 : 4)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .background(alignment: .trailing) {
            Circle()
                .fill(OG.accent.opacity(0.11))
                .frame(width: 174, height: 174)
                .blur(radius: 44)
                .offset(x: 5, y: mascotRaised ? -8 : 5)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private var benefitSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeading("ESTO CAMBIA CON PRO")
            if context != .generic && context != .settings && context != .onboarding {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundStyle(OG.accent)
                    Text(context.headline)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(OG.label)
                }
            }
            ForEach(highlights.indices, id: \.self) { index in
                let item = highlights[index]
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(OG.accent)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                        Text(item.detail)
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                if index < highlights.count - 1 {
                    Divider()
                        .padding(.leading, 42)
                }
            }
        }
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("GRATIS FRENTE A PRO")
            HStack(alignment: .top, spacing: 12) {
                comparisonColumn(
                    name: "Gratis",
                    title: "Empieza",
                    detail: "Progreso de la semana y herramientas esenciales.",
                    pro: false
                )
                comparisonColumn(
                    name: "Pro",
                    title: "Evoluciona",
                    detail: "Todos tus datos, análisis y herramientas sin límites.",
                    pro: true
                )
            }
            Text("En Gratis: 3 rutinas, 3 favoritos, 5 ejercicios propios y 4 escaneos al mes.")
                .font(.caption)
                .foregroundStyle(OG.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func comparisonColumn(name: String, title: String, detail: String, pro: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(name.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(pro ? OG.accent : OG.label2)
            Text(title)
                .font(.headline)
                .foregroundStyle(OG.label)
            Text(detail)
                .font(.caption)
                .foregroundStyle(OG.label2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 115, alignment: .topLeading)
        .padding(14)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: OG.radiusCard)
                .strokeBorder(pro ? OG.accent.opacity(0.7) : OG.surface3, lineWidth: 1)
        }
    }

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("ELIGE TU PLAN")
            if packages.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Compras no disponibles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.label)
                    Text(subscriptions.offerings.unavailableReason
                         ?? "No se han podido cargar las suscripciones. Comprueba la conexión.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(OG.pad)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
            } else {
                if let annual {
                    planRow(annual, badge: savingsBadge(annual: annual, monthly: monthly))
                }
                if let monthly {
                    planRow(monthly, badge: nil)
                }
            }
        }
    }

    private func planRow(_ package: CommercialPackageInfo, badge: String?) -> some View {
        let selected = selectedProductID == package.productID
        return Button {
            selectedProductID = package.productID
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? OG.accent : OG.label3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(package.isAnnual ? "Anual" : "Mensual")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(OG.accent)
                        }
                    }
                    if let intro = package.introductoryOfferSummary {
                        Text(intro)
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    }
                }
                Spacer(minLength: 6)
                Text(package.localizedPrice + (package.isAnnual ? " / año" : " / mes"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            .padding(OG.pad)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
            .overlay {
                RoundedRectangle(cornerRadius: OG.radiusCard)
                    .strokeBorder(selected ? OG.accent : OG.surface3, lineWidth: selected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(package.isAnnual ? "Anual" : "Mensual"), \(package.localizedPrice), \(selected ? "seleccionado" : "no seleccionado")")
    }

    private var purchaseFooter: some View {
        Button {
            Task {
                guard let id = selectedProductID else { return }
                let ok = await subscriptions.purchase(productID: id)
                if ok {
                    if mode == .sheet { subscriptions.dismissPaywall() }
                    onPurchaseSuccess?()
                } else if subscriptions.lastErrorMessage != nil {
                    showError = true
                }
            }
        } label: {
            HStack(spacing: 8) {
                if subscriptions.purchaseInFlight {
                    ProgressView().tint(OG.onAccent)
                }
                Text(selectedPackage?.hasFreeTrial == true ? "Probar Repera Pro" : "Continuar con Pro")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(OG.onAccent)
            .background(OG.accent, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(selectedProductID == nil || subscriptions.purchaseInFlight || packages.isEmpty)
        .padding(.horizontal, OG.pad)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: OG.contentColumnMaxWidth)
        .frame(maxWidth: .infinity)
        .background(OG.bg)
    }

    private var selectedPackage: CommercialPackageInfo? {
        packages.first(where: { $0.productID == selectedProductID })
    }

    private var secondaryActions: some View {
        VStack(spacing: 12) {
            if mode == .onboarding {
                Button("Seguir con Gratis") { onContinueFree?() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.label)
            }
            Button("Restaurar compras") {
                Task {
                    let ok = await subscriptions.restorePurchases()
                    if ok {
                        if mode == .onboarding { onPurchaseSuccess?() }
                    } else {
                        showError = true
                    }
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(OG.accent)
            .disabled(subscriptions.purchaseInFlight)

            if mode == .sheet {
                Button("Gestionar suscripción") {
                    openURL(CommercialConfig.manageSubscriptionsURL)
                }
                .font(.footnote)
                .foregroundStyle(OG.label2)
            }
            HStack(spacing: 20) {
                Button("Privacidad") { openURL(CommercialConfig.privacyPolicyURL) }
                Button("Términos") { openURL(CommercialConfig.termsOfUseURL) }
            }
            .font(.caption)
            .foregroundStyle(OG.label2)
        }
        .frame(maxWidth: .infinity)
    }

    private var legalFooter: some View {
        Text(legalText)
            .font(.caption2)
            .foregroundStyle(OG.label3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legalText: String {
        var parts = [
            "El pago se cargará en tu cuenta de Apple al confirmar la compra.",
            "La suscripción se renueva automáticamente salvo cancelación al menos 24 horas antes del final del periodo."
        ]
        if let pkg = selectedPackage {
            parts.append("Renovación: \(pkg.localizedPrice) \(pkg.isAnnual ? "al año" : "al mes").")
            if pkg.hasFreeTrial, let intro = pkg.introductoryOfferSummary {
                parts.append("\(intro). Tras la prueba se aplicará el precio de renovación indicado.")
            }
        }
        parts.append("Puedes cancelar desde Ajustes → Apple ID → Suscripciones.")
        return parts.joined(separator: " ")
    }

    private func sectionHeading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1)
            .foregroundStyle(OG.label2)
            .accessibilityAddTraits(.isHeader)
    }

    private func reconcileSelectedProduct() {
        if selectedProductID == nil || !packages.contains(where: { $0.productID == selectedProductID }) {
            selectedProductID = annual?.productID ?? monthly?.productID
        }
    }

    private func savingsBadge(annual: CommercialPackageInfo, monthly: CommercialPackageInfo?) -> String? {
        guard let monthly,
              let annualPrice = annual.priceValue,
              let monthlyPrice = monthly.priceValue,
              monthlyPrice > 0 else { return nil }
        let yearOfMonthly = monthlyPrice * 12
        guard yearOfMonthly > annualPrice else { return nil }
        let value = Int(NSDecimalNumber(decimal: (yearOfMonthly - annualPrice) / yearOfMonthly * 100).doubleValue.rounded())
        return value > 0 ? "Ahorra \(value)%" : nil
    }
}
