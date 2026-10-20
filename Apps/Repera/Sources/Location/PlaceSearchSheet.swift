import CoreLocation
import MapKit
import ReperaDomain
import SwiftUI

/// Buscador / editor de sitio MapKit.
/// - Sin pin: mapa + búsqueda (lugar opcional: se puede cerrar sin elegir).
/// - Con pin inicial: abre ya en ese sitio (papelera quita, buscador cambia, check guarda).
struct PlaceSearchSheet: View {
    /// Sitio ya guardado (p. ej. al tocar nombre/mapa en la fila).
    var initialPin: WorkoutLocationPin? = nil
    /// `nil` = sin lugar (papelera o nunca elegiste).
    var onSelect: (WorkoutLocationPin?) -> Void

    var body: some View {
        NavigationStack {
            PlaceSearchRoot(initialPin: initialPin, onSelect: onSelect)
        }
        .ogSheetCorners()
    }
}

// MARK: - Host

private struct PlaceSearchRoot: View {
    var initialPin: WorkoutLocationPin?
    var onSelect: (WorkoutLocationPin?) -> Void

    @StateObject private var completer = PlaceSearchCompleterModel()
    @State private var query = ""
    @State private var isSearchPresented = false
    @State private var pendingItem: MKMapItem?
    @State private var isResolving = false
    @State private var resolveError: String?
    @State private var recentPins: [WorkoutLocationPin] = RecentPlacesStore.load()
    @State private var cameraPosition: MapCameraPosition = .userLocation(
        followsHeading: false,
        fallback: .automatic
    )
    @State private var didApplyInitial = false

    var body: some View {
        PlaceSearchContent(
            onSelect: onSelect,
            completer: completer,
            query: $query,
            isSearchPresented: $isSearchPresented,
            pendingItem: $pendingItem,
            isResolving: $isResolving,
            resolveError: $resolveError,
            recentPins: $recentPins,
            cameraPosition: $cameraPosition
        )
        .searchable(
            text: $query,
            isPresented: $isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Buscar otro sitio…"
        )
        .onChange(of: query) { _, newValue in
            completer.update(query: newValue)
        }
        .task {
            recentPins = RecentPlacesStore.load()
            _ = await WorkoutLocationTracker.shared.ensureWhenInUseAuthorized()

            if !didApplyInitial, let initialPin {
                didApplyInitial = true
                await applyInitialPin(initialPin)
            } else if pendingItem == nil {
                cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
                if let pin = await WorkoutLocationTracker.shared.capturePin() {
                    completer.setRegion(
                        around: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                    )
                }
            }
        }
    }

    private func applyInitialPin(_ pin: WorkoutLocationPin) async {
        let coord = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        )
        completer.setRegion(around: coord)
        pendingItem = pin.asMapItemFallback
        if let resolved = await pin.resolveMapItem() {
            pendingItem = resolved
        }
    }
}

// MARK: - Contenido

private struct PlaceSearchContent: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSearch) private var dismissSearch

    var onSelect: (WorkoutLocationPin?) -> Void
    @ObservedObject var completer: PlaceSearchCompleterModel
    @Binding var query: String
    @Binding var isSearchPresented: Bool
    @Binding var pendingItem: MKMapItem?
    @Binding var isResolving: Bool
    @Binding var resolveError: String?
    @Binding var recentPins: [WorkoutLocationPin]
    @Binding var cameraPosition: MapCameraPosition

    private var isTyping: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Resultados / recientes bajo el buscador (también al buscar otro con sitio ya elegido).
    private var showsSearchPanel: Bool {
        isTyping || isSearchPresented || isResolving || resolveError != nil
    }

    /// Mapa de confirmación solo si hay sitio y no estás buscando.
    private var showsConfirmMap: Bool {
        pendingItem != nil && !isTyping && !isSearchPresented
    }

    var body: some View {
        Group {
            if showsConfirmMap, let item = pendingItem {
                preview(item)
            } else {
                browseMap
            }
        }
        .navigationTitle(showsConfirmMap ? "Lugar" : "Buscar lugar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if showsConfirmMap {
                    OGToolbarGlassButton(
                        systemName: "trash",
                        accessibilityLabel: "Quitar lugar",
                        tint: OG.label
                    ) {
                        clearPlaceAndDismiss()
                    }
                } else {
                    CloseToolbarButton(action: { dismiss() }, large: false)
                }
            }
            if showsConfirmMap {
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: "checkmark",
                        accessibilityLabel: "Guardar lugar",
                        tint: OG.label
                    ) {
                        confirmPending()
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if showsSearchPanel {
                resultsPanel
            }
        }
    }

    private var browseMap: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            UserAnnotation()
            if let item = pendingItem {
                Marker(item: item)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    private var resultsPanel: some View {
        VStack(spacing: 0) {
            Divider()
            if isResolving {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Buscando en Mapas…")
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            if let resolveError {
                Text(resolveError)
                    .font(.system(size: 14))
                    .foregroundStyle(OG.yellow)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }

            if isTyping {
                searchResultsList
            } else if isSearchPresented {
                recentResultsList
            }
        }
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    @ViewBuilder
    private var searchResultsList: some View {
        if !completer.results.isEmpty {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(completer.results, id: \.self) { completion in
                        Button {
                            Task { await select(completion) }
                        } label: {
                            placeResultLabel(title: completion.title, subtitle: completion.subtitle)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .disabled(isResolving)
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .frame(maxHeight: 280)
        } else if !isResolving, resolveError == nil {
            Text("Sin resultados cerca")
                .font(.system(size: 14))
                .foregroundStyle(OG.label3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
    }

    @ViewBuilder
    private var recentResultsList: some View {
        if recentPins.isEmpty {
            Text("Busca un gimnasio, parque o dirección")
                .font(.system(size: 14))
                .foregroundStyle(OG.label3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("Recientes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OG.label2)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                ForEach(recentPins, id: \.recentIdentity) { pin in
                    Button {
                        selectRecent(pin)
                    } label: {
                        HStack(spacing: 12) {
                            placeResultLabel(
                                title: pin.name?.nilIfBlank ?? "Lugar",
                                subtitle: nil
                            )
                            PlaceCategoryIcon(categoryRaw: pin.pointOfInterestCategory)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 16)
                }
            }
            .frame(maxHeight: 280)
        }
    }

    private func placeResultLabel(title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(OG.label)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func preview(_ item: MKMapItem) -> some View {
        let coordinate = item.location.coordinate
        return Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            Marker(item: item)
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                )
            )
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Lugar")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(OG.label)
                    if let subtitle = placeSubtitle(item), !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(OG.label2)
                    }
                }
                Spacer(minLength: 0)
                PlaceCategoryIcon(categoryRaw: item.pointOfInterestCategory?.rawValue)
            }
            .padding(16)
            .background(.bar)
        }
    }

    private func placeSubtitle(_ item: MKMapItem) -> String? {
        if let full = item.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true),
           !full.isEmpty {
            return full
        }
        return item.address?.shortAddress
    }

    private func beginConfirm(_ item: MKMapItem) {
        query = ""
        completer.clear()
        resolveError = nil
        isSearchPresented = false
        dismissSearch()
        pendingItem = item
        let coord = item.location.coordinate
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        )
    }

    private func select(_ completion: MKLocalSearchCompletion) async {
        isResolving = true
        resolveError = nil
        defer { isResolving = false }
        let request = MKLocalSearch.Request(completion: completion)
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                resolveError = "No se encontró ese lugar."
                return
            }
            beginConfirm(item)
        } catch {
            resolveError = "No se pudo abrir el lugar en Mapas."
        }
    }

    private func selectRecent(_ pin: WorkoutLocationPin) {
        beginConfirm(pin.asMapItemFallback)
        Task {
            if let resolved = await pin.resolveMapItem() {
                pendingItem = resolved
            }
        }
    }

    private func confirmPending() {
        guard let item = pendingItem else { return }
        let coord = item.location.coordinate
        let pin = WorkoutLocationPin(
            latitude: coord.latitude,
            longitude: coord.longitude,
            name: item.name,
            mapItemIdentifier: item.identifier?.rawValue,
            pointOfInterestCategory: item.pointOfInterestCategory?.rawValue
        )
        RecentPlacesStore.remember(pin)
        onSelect(pin)
        dismiss()
    }

    private func clearPlaceAndDismiss() {
        onSelect(nil)
        dismiss()
    }
}

// MARK: - Icono de categoría

struct PlaceCategoryIcon: View {
    var categoryRaw: String?

    private var style: (symbol: String, tint: Color)? {
        PlaceCategoryStyle.style(forRaw: categoryRaw)
    }

    var body: some View {
        if let style {
            Image(systemName: style.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(style.tint, in: Circle())
                .accessibilityHidden(true)
        }
    }
}

enum PlaceCategoryStyle {
    static func style(forRaw raw: String?) -> (symbol: String, tint: Color)? {
        guard let raw, !raw.isEmpty else { return nil }
        let cat = MKPointOfInterestCategory(rawValue: raw)
        switch cat {
        case .fitnessCenter:
            return ("figure.strengthtraining.traditional", .orange)
        case .park, .nationalPark:
            return ("tree.fill", .green)
        case .beach:
            return ("beach.umbrella.fill", .cyan)
        case .restaurant, .cafe, .bakery, .foodMarket:
            return ("fork.knife", .orange)
        case .hotel:
            return ("bed.double.fill", .purple)
        case .stadium, .nightlife:
            return ("sportscourt.fill", .blue)
        case .store:
            return ("bag.fill", .pink)
        case .school, .university, .library:
            return ("graduationcap.fill", .indigo)
        case .hospital, .pharmacy:
            return ("cross.case.fill", .red)
        case .airport, .publicTransport:
            return ("tram.fill", .blue)
        case .parking:
            return ("parkingsign", .blue)
        case .gasStation:
            return ("fuelpump.fill", Color(red: 0.2, green: 0.55, blue: 0.35))
        case .museum, .theater, .musicVenue:
            return ("building.columns.fill", .brown)
        default:
            return nil
        }
    }

    static func label(forRaw raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let cat = MKPointOfInterestCategory(rawValue: raw)
        switch cat {
        case .fitnessCenter: return "Gimnasio"
        case .park, .nationalPark: return "Parque"
        case .beach: return "Playa"
        case .restaurant: return "Restaurante"
        case .cafe: return "Café"
        case .bakery: return "Panadería"
        case .foodMarket: return "Mercado"
        case .hotel: return "Hotel"
        case .stadium: return "Estadio"
        case .nightlife: return "Ocio"
        case .store: return "Tienda"
        case .school: return "Colegio"
        case .university: return "Universidad"
        case .library: return "Biblioteca"
        case .hospital: return "Hospital"
        case .pharmacy: return "Farmacia"
        case .airport: return "Aeropuerto"
        case .publicTransport: return "Transporte"
        case .parking: return "Parking"
        case .gasStation: return "Gasolinera"
        case .museum: return "Museo"
        case .theater: return "Teatro"
        case .musicVenue: return "Sala de conciertos"
        default: return nil
        }
    }
}

// MARK: - Recientes

enum RecentPlacesStore {
    private static let key = "repera.places.recent.v1"
    private static let limit = 5

    static func load() -> [WorkoutLocationPin] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([WorkoutLocationPin].self, from: data)) ?? []
    }

    static func remember(_ pin: WorkoutLocationPin) {
        var next = load().filter { !$0.isSamePlace(as: pin) }
        next.insert(pin, at: 0)
        if next.count > limit { next = Array(next.prefix(limit)) }
        if let data = try? JSONEncoder().encode(next) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

private extension WorkoutLocationPin {
    var recentIdentity: String {
        mapItemIdentifier ?? "\(latitude),\(longitude),\(name ?? "")"
    }

    func isSamePlace(as other: WorkoutLocationPin) -> Bool {
        if let a = mapItemIdentifier, let b = other.mapItemIdentifier, !a.isEmpty, a == b {
            return true
        }
        return abs(latitude - other.latitude) < 0.0001
            && abs(longitude - other.longitude) < 0.0001
    }

    var asMapItemFallback: MKMapItem {
        let item = MKMapItem(
            location: CLLocation(latitude: latitude, longitude: longitude),
            address: nil
        )
        item.name = name ?? "Lugar"
        return item
    }

    func resolveMapItem() async -> MKMapItem? {
        guard let raw = mapItemIdentifier,
              let identifier = MKMapItem.Identifier(rawValue: raw)
        else { return nil }
        do {
            return try await MKMapItemRequest(mapItemIdentifier: identifier).mapItem
        } catch {
            return nil
        }
    }
}

// MARK: - Completer

@MainActor
final class PlaceSearchCompleterModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var results: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    func setRegion(around coordinate: CLLocationCoordinate2D) {
        completer.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    }

    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            completer.queryFragment = ""
            return
        }
        completer.queryFragment = trimmed
    }

    func clear() {
        results = []
        completer.queryFragment = ""
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.results = self.completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.results = []
        }
    }
}

// MARK: - Fila (apuntar / editar)

struct WorkoutPlacePickerRow: View {
    @Binding var pin: WorkoutLocationPin?
    @State private var showSearch = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showSearch = true
            } label: {
                HStack(spacing: 12) {
                    if let pin {
                        if PlaceCategoryStyle.style(forRaw: pin.pointOfInterestCategory) != nil {
                            PlaceCategoryIcon(categoryRaw: pin.pointOfInterestCategory)
                        } else {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(OG.label3)
                                .frame(width: 32, height: 32)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pin.name?.nilIfBlank ?? "Lugar en el mapa")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(OG.label)
                                .lineLimit(2)
                            if let category = PlaceCategoryStyle.label(forRaw: pin.pointOfInterestCategory) {
                                Text(category)
                                    .font(.system(size: 13))
                                    .foregroundStyle(OG.label2)
                            }
                        }
                        Spacer(minLength: 0)
                    } else {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.accent)
                            .frame(width: 32, height: 32)
                        Text("Añadir lugar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(OG.label)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OG.label3)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let pin {
                Button {
                    showSearch = true
                } label: {
                    WorkoutLocationPinMap(pin: pin, isInteractive: false)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Editar lugar en el mapa")
            }
        }
        .sheet(isPresented: $showSearch) {
            PlaceSearchSheet(initialPin: pin) { selected in
                pin = selected
            }
            .presentationDetents([.large])
            .ogSheetCorners()
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
