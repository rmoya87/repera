import MapKit
import ReperaDomain
import SwiftUI

/// Buscador de sitios con el motor de Apple Maps (`MKLocalSearchCompleter`) + preview MapKit.
struct PlaceSearchSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onSelect: (WorkoutLocationPin) -> Void

    @StateObject private var completer = PlaceSearchCompleterModel()
    @State private var query = ""
    @State private var pendingItem: MKMapItem?
    @State private var isResolving = false
    @State private var resolveError: String?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if let item = pendingItem {
                    preview(item)
                } else {
                    searchList
                }
            }
            .navigationTitle(pendingItem == nil ? "Buscar lugar" : "Confirmar lugar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if pendingItem != nil {
                        Button("Atrás") {
                            pendingItem = nil
                            resolveError = nil
                        }
                    } else {
                        Button("Cancelar") { dismiss() }
                    }
                }
                if pendingItem != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Usar") { confirmPending() }
                            .fontWeight(.semibold)
                    }
                }
            }
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
        }
        .ogSheetCorners()
    }

    private var searchList: some View {
        List {
            if isResolving {
                HStack {
                    ProgressView()
                    Text("Buscando en Mapas…")
                        .foregroundStyle(OG.label2)
                }
            }
            if let resolveError {
                Text(resolveError)
                    .font(.system(size: 14))
                    .foregroundStyle(OG.yellow)
            }
            ForEach(completer.results, id: \.self) { completion in
                Button {
                    Task { await select(completion) }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(completion.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(OG.label)
                        if !completion.subtitle.isEmpty {
                            Text(completion.subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .disabled(isResolving)
            }
        }
        .ogListChrome()
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
            .frame(maxWidth: .infinity, alignment: .leading)
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

    private func confirmPending() {
        guard let item = pendingItem else { return }
        let coord = item.location.coordinate
        let pin = WorkoutLocationPin(
            latitude: coord.latitude,
            longitude: coord.longitude,
            name: item.name,
            mapItemIdentifier: item.identifier?.rawValue
        )
        onSelect(pin)
        dismiss()
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
            // Leer en MainActor: `MKLocalSearchCompletion` no es Sendable.
            self.results = self.completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.results = []
        }
    }
}

// MARK: - Fila reutilizable (apuntar / editar)

struct WorkoutPlacePickerRow: View {
    @Binding var pin: WorkoutLocationPin?
    @State private var showSearch = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showSearch = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(OG.accent)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pin?.name?.nilIfBlank ?? (pin == nil ? "Añadir lugar" : "Lugar en el mapa"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(OG.label)
                        Text(pin == nil ? "Buscar en Apple Mapas" : "Cambiar sitio")
                            .font(.system(size: 13))
                            .foregroundStyle(OG.label2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(OG.label3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let pin {
                WorkoutLocationPinMap(pin: pin)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button(role: .destructive) {
                    self.pin = nil
                } label: {
                    Text("Quitar lugar")
                        .font(.system(size: 15, weight: .medium))
                }
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
