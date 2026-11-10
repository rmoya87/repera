import ReperaDomain
import StoreKit
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
    @State private var isLoadingPlans = false
    @State private var mascotRaised = false
    @State private var showOfferCodeRedemption = false

    private var context: PaywallContext {
        mode == .onboarding ? .onboarding : subscriptions.paywall.context
    }
    private var packages: [CommercialPackageInfo] { subscriptions.offerings.packages }
    private var annual: CommercialPackageInfo? { packages.first(where: \.isAnnual) }
    private var monthly: CommercialPackageInfo? { packages.first(where: { !$0.isAnnual }) }

    /// Comparativa real: una única sección, sin ventajas duplicadas.
    /// Debe coincidir con `FeatureAccessPolicy` / gates UI (no marketing inventado).
    private var comparisonRows: [(label: String, free: String, pro: String)] {
        [
            ("Navegación mapa", "2D", "2D + 3D"),
            ("Progreso", "Últimos 7 días", "Completo"),
            ("Por ejercicio", "Última + récord", "Historial completo"),
            ("Progresión de carga", "Sugerida en ficha", "Automática"),
            ("Rutinas / favoritos", "\(FreePlanLimits.maxLibraryRoutines) / \(FreePlanLimits.maxFavoriteItems)", "Sin límites"),
            ("Ejercicios propios", "\(FreePlanLimits.maxCustomExercises)", "Sin límites"),
            ("Escáner WOD", "\(FreePlanLimits.maxBoardScansPerMonth)/mes", "Ilimitado")
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    navigationHeader
                    hero
                    comparison
                    plansSection
                    offerCodeBox
                    secondaryActions
                    legalFooter
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 6)
                .padding(.bottom, 12)
                .frame(maxWidth: OG.contentColumnMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                purchaseFooter
            }
            .background(OG.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .offerCodeRedemption(isPresented: $showOfferCodeRedemption) { _ in
                Task { await handleOfferCodeRedemptionFinished() }
            }
            .task {
                // El onboarding no debe disparar de nuevo el paywall global.
                await subscriptions.start()
                await reloadPlans()
            }
            .onChange(of: packages.map(\.productID)) { _, _ in
                reconcileSelectedProduct()
            }
            .onAppear {
                // Con reducir movimiento: pose fija. Si no: balanceo ambient (no es token UI).
                guard !reduceMotion else {
                    mascotRaised = true
                    return
                }
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

    /// Caja de canje: Apple muestra la hoja del sistema (el código se escribe ahí).
    private var offerCodeBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("¿TIENES UN CÓDIGO?")
            Button {
                showOfferCodeRedemption = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "giftcard.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(OG.accent)
                        .frame(width: 28, alignment: .center)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Canjear código")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                        Text("Introduce el código aquí.")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(OG.label3)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, OG.pad)
                .padding(.vertical, 12)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
                .overlay {
                    RoundedRectangle(cornerRadius: OG.radiusCard)
                        .strokeBorder(OG.surface3, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Canjear código de oferta")
            .accessibilityIdentifier("pro-redeem-offer-code")
            .disabled(subscriptions.purchaseInFlight)
        }
    }

    @MainActor
    private func handleOfferCodeRedemptionFinished() async {
        await subscriptions.refreshEntitlementsForFeatureAction()
        guard subscriptions.isPro else { return }
        if mode == .sheet { subscriptions.dismissPaywall() }
        onPurchaseSuccess?()
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
            if mode == .onboarding {
                Text("TU SIGUIENTE PASO")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(OG.label2)
            }
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Todo tu progreso.")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(OG.label)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Desbloquea el siguiente nivel de Repera.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ReperaMascot(pose: .hero, maxHeight: 96)
                .frame(width: 100, height: 106)
                .offset(y: mascotRaised ? -5 : 4)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
        .background(alignment: .trailing) {
            Circle()
                .fill(OG.accent.opacity(0.11))
                .frame(width: 114, height: 114)
                .blur(radius: 32)
                .offset(x: 5, y: mascotRaised ? -8 : 5)
                .accessibilityHidden(true)
        }
        .ogChartAppear()
        .accessibilityElement(children: .combine)
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("FUNCIÓN")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(OG.label2)
                Text("GRATIS")
                    .frame(width: 99, alignment: .center)
                    .foregroundStyle(OG.label2)
                Text("PRO")
                    .frame(width: 102, alignment: .center)
                    .foregroundStyle(OG.accent)
            }
            .font(.system(size: 10, weight: .semibold))
            .padding(.bottom, 3)

            ForEach(comparisonRows.indices, id: \.self) { index in
                let item = comparisonRows[index]
                HStack(alignment: .center, spacing: 8) {
                    Text(item.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(OG.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.free)
                        .foregroundStyle(OG.label2)
                        .frame(width: 99, alignment: .center)
                    Text(item.pro)
                        .foregroundStyle(OG.label)
                        .frame(width: 102, alignment: .center)
                }
                .font(.system(size: 11))
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 3)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.label): Gratis, \(item.free); Pro, \(item.pro)")
                Divider()
                    .overlay(OG.surface3.opacity(0.45))
            }
        }
    }

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionHeading("ELIGE TU PLAN")
            if subscriptions.isPro {
                Label(
                    subscriptions.snapshot.status == .unknown
                        ? "Acceso Pro conservado desde tu última compra verificada"
                        : "Tu suscripción Repera Pro está activa",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(OG.pad)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
            } else if packages.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    if isLoadingPlans {
                        ProgressView("Consultando App Store…")
                            .font(.footnote)
                    } else {
                        Text("Compras no disponibles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                        Text(subscriptions.offerings.unavailableReason
                             ?? "No se han podido cargar los planes desde Apple.")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                        Button("Reintentar") {
                            Task { await reloadPlans() }
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(OG.accent)
                        .accessibilityIdentifier("pro-retry-products")
                    }
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
            .padding(.horizontal, OG.pad)
            .padding(.vertical, 10)
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
        Group {
            if subscriptions.isPro {
                Label("Ya tienes acceso a Repera Pro", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OG.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .accessibilityIdentifier("pro-active-entitlement")
            } else {
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
                    .padding(.vertical, 13)
                    .foregroundStyle(OG.onAccent)
                    .background(OG.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(selectedProductID == nil || subscriptions.purchaseInFlight || packages.isEmpty)
            }
        }
        .padding(.horizontal, OG.pad)
        .padding(.top, 6)
        .padding(.bottom, 5)
        .frame(maxWidth: OG.contentColumnMaxWidth)
        .frame(maxWidth: .infinity)
        .background(OG.bg)
    }

    private var selectedPackage: CommercialPackageInfo? {
        packages.first(where: { $0.productID == selectedProductID })
    }

    private var secondaryActions: some View {
        VStack(spacing: 6) {
            if mode == .onboarding {
                Button("Seguir con Gratis") { onContinueFree?() }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(OG.label)
            }

            // Una línea en anchura normal. Accesibilidad y pantallas muy
            // estrechas conservan todos los enlaces mediante fallback 2×2.
            ViewThatFits(in: .horizontal) {
                actionLinksRow
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 6) {
                    actionLinks
                }
                .font(.footnote)
                .foregroundStyle(OG.label2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actionLinksRow: some View {
        HStack(spacing: 8) {
            actionLinks
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(OG.label2)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var actionLinks: some View {
        Button("Restaurar") {
            Task {
                let restored = await subscriptions.restorePurchases()
                if restored {
                    if mode == .onboarding { onPurchaseSuccess?() }
                } else {
                    showError = true
                }
            }
        }
        .disabled(subscriptions.purchaseInFlight)
        .accessibilityLabel("Restaurar compras")
        Button("Gestionar") { openURL(CommercialConfig.manageSubscriptionsURL) }
            .accessibilityLabel("Gestionar suscripción")
        Button("Privacidad") { openURL(CommercialConfig.privacyPolicyURL) }
        Button("Términos") { openURL(CommercialConfig.termsOfUseURL) }
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
            if let intro = pkg.introductoryOfferSummary {
                let suffix = pkg.hasFreeTrial
                    ? "Tras la prueba se aplicará el precio de renovación indicado."
                    : "Luego se aplicará el precio de renovación indicado."
                parts.append("\(intro). \(suffix)")
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

    @MainActor
    private func reloadPlans() async {
        guard !isLoadingPlans else { return }
        isLoadingPlans = true
        defer { isLoadingPlans = false }
        await subscriptions.loadOfferings()
        reconcileSelectedProduct()
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
