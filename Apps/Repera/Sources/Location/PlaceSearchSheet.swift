import CoreLocation
import MapKit
import ReperaDomain
import SwiftUI

/// Buscador de sitios con Apple Mapas. Al abrir, mapa en tu ubicación;
/// al enfocar el buscador, últimos 5 sitios usados.
struct PlaceSearchSheet: View {
    var onSelect: (WorkoutLocationPin) -> Void

    var body: some View {
        NavigationStack {
            PlaceSearchRoot(onSelect: onSelect)
        }
        .ogSheetCorners()
    }
}

// MARK: - Host (posee estado + `.searchable`)

private struct PlaceSearchRoot: View {
    var onSelect: (WorkoutLocationPin) -> Void

    @StateObject private var completer = PlaceSearchCompleterModel()
    @State private var query = ""
    @State private var pendingItem: MKMapItem?
    @State private var isResolving = false
    @State private var resolveError: String?
    @State private var recentPins: [WorkoutLocationPin] = RecentPlacesStore.load()
    @State private var cameraPosition: MapCameraPosition = .userLocation(
        followsHeading: false,
        fallback: .automatic
    )

    var body: some View {
        PlaceSearchContent(
            onSelect: onSelect,
            completer: completer,
            query: $query,
            pendingItem: $pendingItem,
            isResolving: $isResolving,
            resolveError: $resolveError,
            recentPins: $recentPins,
            cameraPosition: $cameraPosition
        )
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Gimnasio, parque, dirección…"
        )
        .onChange(of: query) { _, newValue in
            if pendingItem == nil {
                completer.update(query: newValue)
            }
        }
        .task {
            _ = await WorkoutLocationTracker.shared.ensureWhenInUseAuthorized()
            cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
            if let pin = await WorkoutLocationTracker.shared.capturePin() {
                completer.setRegion(
                    around: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                )
            }
            recentPins = RecentPlacesStore.load()
        }
    }
}

// MARK: - Contenido (lee `isSearching`)

private struct PlaceSearchContent: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isSearching) private var isSearchFieldActive

    var onSelect: (WorkoutLocationPin) -> Void
    @ObservedObject var completer: PlaceSearchCompleterModel
    @Binding var query: String
    @Binding var pendingItem: MKMapItem?
    @Binding var isResolving: Bool
    @Binding var resolveError: String?
    @Binding var recentPins: [WorkoutLocationPin]
    @Binding var cameraPosition: MapCameraPosition

    private var isTyping: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showsBottomPanel: Bool {
        isTyping || isSearchFieldActive || isResolving || resolveError != nil
    }

    var body: some View {
        Group {
            if let item = pendingItem {
                preview(item)
            } else {
                browseMap
            }
        }
        .navigationTitle(pendingItem == nil ? "Buscar lugar" : "Confirmar lugar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if pendingItem != nil {
                    // Descartar este sitio y volver al mapa (mismo chrome que el resto).
                    OGToolbarGlassButton(
                        systemName: "trash",
                        accessibilityLabel: "Quitar lugar",
                        tint: OG.label
                    ) {
                        pendingItem = nil
                        resolveError = nil
                        cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
                    }
                } else {
                    CloseToolbarButton(action: { dismiss() }, large: false)
                }
            }
            if pendingItem != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    OGToolbarGlassButton(
                        systemName: "checkmark",
                        accessibilityLabel: "Usar este lugar",
                        tint: OG.label
                    ) {
                        confirmPending()
                    }
                }
            }
        }
    }

    private var browseMap: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsBottomPanel {
                resultsPanel
            }
        }
    }

    private var resultsPanel: some View {
        VStack(spacing: 0) {
            if isResolving {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Buscando en Mapas…")
                        .font(.system(size: 14))
                        .foregroundStyle(OG.label2)
                    Spacer(minLength: 0)
                }
                .padding(14)
            }
            if let resolveError {
                Text(resolveError)
                    .font(.system(size: 14))
                    .foregroundStyle(OG.yellow)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }

            if isTyping {
                searchResultsList
            } else if isSearchFieldActive {
                recentResultsList
            }
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var searchResultsList: some View {
        if !completer.results.isEmpty {
            List {
                ForEach(completer.results, id: \.self) { completion in
                    Button {
                        Task { await select(completion) }
                    } label: {
                        placeResultLabel(title: completion.title, subtitle: completion.subtitle)
                    }
                    .disabled(isResolving)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxHeight: 280)
        } else if !isResolving, resolveError == nil {
            Text("Sin resultados cerca")
                .font(.system(size: 14))
                .foregroundStyle(OG.label3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
        }
    }

    @ViewBuilder
    private var recentResultsList: some View {
        if recentPins.isEmpty {
            Text("Busca un gimnasio, parque o dirección")
                .font(.system(size: 14))
                .foregroundStyle(OG.label3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
        } else {
            List {
                Section {
                    ForEach(recentPins, id: \.recentIdentity) { pin in
                        Button {
                            selectRecent(pin)
                        } label: {
                            HStack(spacing: 12) {
                                placeResultLabel(
                                    title: pin.name?.nilIfBlank ?? "Lugar",
                                    subtitle: nil
                                )
                                PlaceMapGlyph(pin: pin)
                                    .frame(width: 32, height: 40)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Recientes")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(OG.label2)
                        .textCase(nil)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
        .contentShape(Rectangle())
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
                PlaceMapGlyph(mapItem: item)
                    .frame(width: 36, height: 44)
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
            pendingItem = item
            query = ""
            completer.clear()
        } catch {
            resolveError = "No se pudo abrir el lugar en Mapas."
        }
    }

    private func selectRecent(_ pin: WorkoutLocationPin) {
        pendingItem = pin.asMapItemFallback
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
}

// MARK: - Glyph nativo (mismo Marker que Mapas)

/// Mini `Marker(item:)` — icono y tint del sitio en Apple Mapas.
struct PlaceMapGlyph: View {
    private let pin: WorkoutLocationPin?
    private let seedItem: MKMapItem?

    @State private var resolved: MKMapItem?

    init(pin: WorkoutLocationPin) {
        self.pin = pin
        self.seedItem = nil
    }

    init(mapItem: MKMapItem) {
        self.pin = nil
        self.seedItem = mapItem
    }

    private var item: MKMapItem {
        resolved ?? seedItem ?? pin?.asMapItemFallback
            ?? MKMapItem(location: CLLocation(latitude: 0, longitude: 0), address: nil)
    }

    private var coordinate: CLLocationCoordinate2D { item.location.coordinate }

    var body: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
                )
            )
        ) {
            Marker(item: item)
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
        .disabled(true)
        .allowsHitTesting(false)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .task(id: pin?.mapItemIdentifier ?? seedItem?.identifier?.rawValue) {
            if let seedItem {
                resolved = seedItem
            } else if let pin {
                resolved = await pin.resolveMapItem() ?? pin.asMapItemFallback
            }
        }
    }
}

// MARK: - Recientes (últimos 5)

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
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pin?.name?.nilIfBlank ?? (pin == nil ? "Añadir lugar" : "Lugar en el mapa"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(OG.label)
                        Text(pin == nil ? "Buscar en Apple Mapas" : "Cambiar sitio")
                            .font(.system(size: 13))
                            .foregroundStyle(OG.label2)
                    }
                    Spacer(minLength: 0)
                    if let pin {
                        PlaceMapGlyph(pin: pin)
                            .frame(width: 36, height: 44)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OG.label3)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let pin {
                WorkoutLocationPinMap(pin: pin)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .sheet(isPresented: $showSearch) {
            PlaceSearchSheet { selected in
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
