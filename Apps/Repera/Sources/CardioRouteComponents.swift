import Charts
import CoreLocation
import HealthKit
import ReperaDomain
import SwiftUI
import WeatherKit

/// Gráficas nativas dentro de la misma tarjeta de Entreno, con selección táctil.
struct CardioAltitudeChart: View {
    var extras: HealthKitStore.SessionHealthExtras
    @State private var selection: Topic = .cardio
    @State private var selectedTime: Date?
    @State private var selectedDistance: Double?

    private enum Topic: String, CaseIterable {
        case cardio = "Cardio"
        case altitude = "Altitud"
    }

    private var result: CardioRouteAnalysis.Result {
        CardioRouteAnalysis.analyze(route: extras.routePoints.map {
            CardioRouteAnalysis.Sample(date: $0.date, latitude: $0.latitude,
                                       longitude: $0.longitude, altitudeMeters: $0.altitudeMeters)
        })
    }

    private var pickedHeart: HealthKitStore.HeartRatePoint? {
        guard let selectedTime else { return nil }
        return extras.heartRateSeries.min {
            abs($0.date.timeIntervalSince(selectedTime)) < abs($1.date.timeIntervalSince(selectedTime))
        }
    }

    private var pickedAltitude: CardioRouteAnalysis.ProfilePoint? {
        guard let selectedDistance else { return nil }
        return result.profile.min {
            abs($0.distanceKm - selectedDistance) < abs($1.distanceKm - selectedDistance)
        }
    }

    private var altitudeStats: (min: Double, max: Double, avg: Double)? {
        let values = result.profile.map(\.altitudeMeters)
        guard !values.isEmpty else { return nil }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        let avg = values.reduce(0, +) / Double(values.count)
        return (minV, maxV, avg)
    }

    private var distanceDomain: ClosedRange<Double> {
        let maxKm = max(result.profile.last?.distanceKm ?? 0, 0.01)
        return 0...maxKm
    }

    private var elevationRange: ClosedRange<Double> {
        let values = result.profile.map(\.altitudeMeters)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 1
        let padding = max(4, (maximum - minimum) * 0.14)
        return (minimum - padding)...(maximum + padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Perfil", selection: $selection) {
                ForEach(Topic.allCases, id: \.self) { topic in
                    Text(topic.rawValue).tag(topic)
                }
            }
            .pickerStyle(.segmented)

            if selection == .cardio {
                cardio
                cardioStatTiles
            } else {
                elevation
                altitudeStatTiles
            }
        }
    }

    @ViewBuilder
    private var cardio: some View {
        HStack {
            Label("Ritmo cardíaco", systemImage: "heart.fill")
                .foregroundStyle(OG.red)
            Spacer(minLength: 8)
            if let point = pickedHeart {
                Text("\(Int(point.bpm.rounded())) lpm")
                    .foregroundStyle(OG.red)
                    .contentTransition(.numericText())
            } else if let average = extras.averageHeartRateBpm {
                Text("Media \(Int(average.rounded())) lpm")
                    .foregroundStyle(OG.label2)
            }
        }
        .font(.system(size: 13, weight: .semibold).monospacedDigit())

        if extras.heartRateSeries.count >= 2 {
            Chart {
                ForEach(extras.heartRateSeries) { point in
                    AreaMark(x: .value("Hora", point.date), y: .value("Pulso", point.bpm))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(colors: [OG.red.opacity(0.28), OG.red.opacity(0.02)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Hora", point.date), y: .value("Pulso", point.bpm))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(OG.red)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                if let point = pickedHeart {
                    RuleMark(x: .value("Selección", point.date))
                        .foregroundStyle(OG.label2.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(x: .value("Hora", point.date), y: .value("Pulso", point.bpm))
                        .symbolSize(70)
                        .foregroundStyle(OG.red)
                }
            }
            .chartXSelection(value: $selectedTime)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) {
                    AxisGridLine().foregroundStyle(OG.surface3)
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                    AxisGridLine().foregroundStyle(OG.surface3)
                    AxisValueLabel()
                }
            }
            .chartPlotStyle { $0.clipped() }
            .frame(height: 170)
            .frame(maxWidth: .infinity)
            .clipped()
        } else {
            ContentUnavailableView("Sin curva de pulso", systemImage: "heart",
                                   description: Text("No hay suficientes muestras de frecuencia cardíaca."))
                .frame(height: 145)
        }
    }

    @ViewBuilder
    private var elevation: some View {
        HStack {
            Label("Perfil del recorrido", systemImage: "mountain.2.fill")
                .foregroundStyle(OG.accent)
            Spacer(minLength: 6)
            if let point = pickedAltitude {
                Text(String(format: "%.0f m · %.2f km", point.altitudeMeters, point.distanceKm))
                    .foregroundStyle(OG.accent)
                    .contentTransition(.numericText())
            } else if result.profile.count >= 2 {
                Text("↑ \(Int(result.ascentMeters.rounded())) m")
                    .foregroundStyle(OG.label2)
            }
        }
        .font(.system(size: 13, weight: .semibold).monospacedDigit())

        if result.profile.count >= 2 {
            Chart {
                ForEach(result.profile) { point in
                    AreaMark(
                        x: .value("Distancia", point.distanceKm),
                        yStart: .value("Base", elevationRange.lowerBound),
                        yEnd: .value("Altitud", point.altitudeMeters)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [OG.accent.opacity(0.26), OG.accent.opacity(0.015)],
                                                    startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Distancia", point.distanceKm),
                             y: .value("Altitud", point.altitudeMeters))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(OG.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                if let point = pickedAltitude {
                    RuleMark(x: .value("Km", point.distanceKm))
                        .foregroundStyle(OG.label2.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(x: .value("Km", point.distanceKm), y: .value("m", point.altitudeMeters))
                        .foregroundStyle(OG.accent)
                        .symbolSize(70)
                }
            }
            .chartXSelection(value: $selectedDistance)
            .chartXScale(domain: distanceDomain)
            .chartYScale(domain: elevationRange)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisGridLine().foregroundStyle(OG.surface3)
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                    AxisGridLine().foregroundStyle(OG.surface3)
                    AxisValueLabel()
                }
            }
            .chartPlotStyle { $0.clipped() }
            .frame(height: 170)
            .frame(maxWidth: .infinity)
            .clipped()
            HStack(spacing: 16) {
                Label("+\(Int(result.ascentMeters.rounded())) m", systemImage: "arrow.up.right")
                Label("−\(Int(result.descentMeters.rounded())) m", systemImage: "arrow.down.right")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(OG.label2)
        } else {
            ContentUnavailableView("Altitud no disponible", systemImage: "mountain.2",
                                   description: Text("La ruta no incluye altitudes GPS válidas."))
                .frame(height: 145)
        }
    }

    @ViewBuilder
    private var cardioStatTiles: some View {
        if extras.minHeartRateBpm != nil || extras.maxHeartRateBpm != nil ||
            extras.averageSpeedKmh != nil || extras.maxSpeedKmh != nil {
            HStack(spacing: 7) {
                if extras.minHeartRateBpm != nil {
                    miniStat("Mín", value: extras.minHeartRateBpm.map { "\(Int($0.rounded()))" },
                             unit: "lpm", tint: OG.label2)
                }
                if extras.maxHeartRateBpm != nil {
                    miniStat("Máx", value: extras.maxHeartRateBpm.map { "\(Int($0.rounded()))" },
                             unit: "lpm", tint: OG.red)
                }
                if extras.averageSpeedKmh != nil {
                    miniStat("Vel. media",
                             value: extras.averageSpeedKmh.map { String(format: "%.1f", $0) },
                             unit: "km/h", tint: OG.blue)
                }
                if extras.maxSpeedKmh != nil {
                    miniStat("Vel. máx",
                             value: extras.maxSpeedKmh.map { String(format: "%.1f", $0) },
                             unit: "km/h", tint: OG.accent)
                }
            }
        }
    }

    @ViewBuilder
    private var altitudeStatTiles: some View {
        if let stats = altitudeStats {
            HStack(spacing: 7) {
                miniStat("Máx", value: "\(Int(stats.max.rounded()))", unit: "m", tint: OG.accent)
                miniStat("Mín", value: "\(Int(stats.min.rounded()))", unit: "m", tint: OG.label2)
                miniStat("Media", value: "\(Int(stats.avg.rounded()))", unit: "m", tint: OG.blue)
            }
        }
    }

    private func miniStat(_ title: String, value: String?, unit: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(OG.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value ?? "—")
                .font(.system(size: 17, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(unit).font(.system(size: 10)).foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(OG.surface2.opacity(0.85),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Km terminados: interpolación en el cruce de cada kilómetro, no medias generales.
struct CardioSplitsView: View {
    var routePoints: [HealthKitStore.RoutePoint]
    var heartRate: [HealthKitStore.HeartRatePoint]
    var cycling: Bool = false

    private var splits: [CardioRouteAnalysis.Split] {
        CardioRouteAnalysis.analyze(
            route: routePoints.map {
                .init(date: $0.date, latitude: $0.latitude, longitude: $0.longitude,
                      altitudeMeters: $0.altitudeMeters)
            },
            heart: heartRate.map { .init(date: $0.date, bpm: $0.bpm) }
        ).splits
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("KM").frame(width: 38, alignment: .leading)
                Text("Tiempo").frame(maxWidth: .infinity, alignment: .leading)
                Text(cycling ? "km/h" : "Ritmo").frame(maxWidth: .infinity, alignment: .leading)
                Text("Frec. cardiaca").frame(width: 88, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(OG.label3)
            .padding(.vertical, 8)

            if splits.isEmpty {
                Text("No hay kilómetros completos con GPS válido.")
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
                    .padding(.vertical, 16)
            } else {
                ForEach(splits) { split in
                    Divider().opacity(0.30)
                    HStack(spacing: 6) {
                        Text("\(split.kilometer)")
                            .fontWeight(.semibold)
                            .frame(width: 38, alignment: .leading)
                        Text(Self.clock(split.seconds))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(cycling
                             ? String(format: "%.1f", split.speedKmh)
                             : "\(Self.clock(split.paceSecondsPerKm))/km")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(split.averageBpm.map { "\(Int($0.rounded())) LPM" } ?? "—")
                            .frame(width: 88, alignment: .trailing)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(OG.pad)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
    }

    static func clock(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let min = total / 60
        let sec = total % 60
        if min >= 60 { return String(format: "%d:%02d:%02d", min / 60, min % 60, sec) }
        return String(format: "%d:%02d", min, sec)
    }
}

/// Pie meteorológico anclado al mapa (misma card): icono a la izquierda, valor + título.
/// Condiciones en la fecha del entreno vía WeatherKit histórico (AQI histórico no disponible).
/// No se persiste: se consulta al abrir el detalle.
struct RouteWeatherStrip: View {
    var latitude: Double
    var longitude: Double
    var workoutDate: Date

    @Environment(\.colorScheme) private var colorScheme
    @State private var temperatureC: Double?
    @State private var humidity: Double?
    @State private var symbol = "cloud.sun"
    @State private var attributionURL: URL?
    @State private var attributionMarkURL: URL?
    @State private var isLoading = true
    @State private var failureHint: String?

    private var hasWeather: Bool { temperatureC != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                weatherStat(
                    symbol: symbol,
                    title: "Tiempo",
                    value: temperatureC.map { String(format: "%.0f °C", $0) },
                    loading: isLoading
                )
                Divider().frame(height: 36).padding(.horizontal, 4)
                weatherStat(
                    symbol: "humidity.fill",
                    title: "Humedad",
                    value: humidity.map { "\(Int(($0 * 100).rounded())) %" },
                    loading: isLoading
                )
                Divider().frame(height: 36).padding(.horizontal, 4)
                // AQI histórico: WeatherKit no lo ofrece → siempre «—» a propósito.
                weatherStat(symbol: "aqi.medium", title: "Calidad aire", value: nil, loading: false)
            }
            if let attributionURL, let attributionMarkURL, hasWeather {
                Link(destination: attributionURL) {
                    HStack(spacing: 6) {
                        AsyncImage(url: attributionMarkURL) { image in
                            image.resizable().scaledToFit().frame(height: 12)
                        } placeholder: {
                            Text("Apple Weather")
                                .font(.caption2)
                                .foregroundStyle(OG.label3)
                        }
                        Text("· Histórico por hora")
                            .font(.caption2)
                            .foregroundStyle(OG.label3)
                    }
                }
                .buttonStyle(.plain)
            } else if let failureHint {
                Text(failureHint)
                    .font(.caption2)
                    .foregroundStyle(OG.label3)
            } else if isLoading {
                Text("Consultando tiempo histórico…")
                    .font(.caption2)
                    .foregroundStyle(OG.label3)
            } else {
                Text("Calidad del aire histórica no disponible.")
                    .font(.caption2)
                    .foregroundStyle(OG.label3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface)
        .task(id: taskKey) {
            await loadWeather()
        }
        .accessibilityElement(children: .contain)
    }

    private var taskKey: String {
        "\(latitude),\(longitude),\(workoutDate.timeIntervalSince1970)"
    }

    private func weatherStat(symbol: String, title: String, value: String?, loading: Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(OG.label)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                if loading, value == nil {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(OG.label2)
                        .frame(height: 18, alignment: .leading)
                } else {
                    Text(value ?? "—")
                        .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(OG.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OG.label2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadWeather() async {
        humidity = nil
        temperatureC = nil
        attributionURL = nil
        attributionMarkURL = nil
        failureHint = nil
        isLoading = true
        defer { isLoading = false }

        // WeatherKit histórico desde 2021-08-01.
        let weatherEpoch = Date(timeIntervalSince1970: 1_627_776_000)
        let queryDate: Date = {
            if workoutDate > Date() { return Date() }
            if workoutDate < weatherEpoch { return weatherEpoch }
            return workoutDate
        }()
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            failureHint = "Coordenadas no válidas para consultar el tiempo."
            return
        }

        let location = CLLocation(
            latitude: (latitude * 100).rounded() / 100,
            longitude: (longitude * 100).rounded() / 100
        )

        let hour: HourWeather
        do {
            // Ventana ±3 h: más tolerante a husos y alineación de horas.
            let hourly = try await WeatherService.shared.weather(
                for: location,
                including: .hourly(
                    startDate: queryDate.addingTimeInterval(-3 * 3600),
                    endDate: queryDate.addingTimeInterval(3 * 3600)
                )
            )
            guard let match = hourly.forecast.min(by: {
                abs($0.date.timeIntervalSince(queryDate)) < abs($1.date.timeIntervalSince(queryDate))
            }), abs(match.date.timeIntervalSince(queryDate)) <= 3 * 3600 else {
                failureHint = "Sin datos horarios para esa fecha y lugar."
                return
            }
            hour = match
        } catch {
            #if DEBUG
            print("WeatherKit error: \(error)")
            #endif
            failureHint = Self.hint(for: error)
            return
        }

        temperatureC = hour.temperature.converted(to: .celsius).value
        humidity = hour.humidity
        symbol = hour.symbolName

        // Atribución aparte: si falla, igual mostramos temperatura/humedad.
        do {
            let attribution = try await WeatherService.shared.attribution
            attributionURL = attribution.legalPageURL
            attributionMarkURL = colorScheme == .dark
                ? attribution.combinedMarkDarkURL
                : attribution.combinedMarkLightURL
        } catch {
            #if DEBUG
            print("WeatherKit attribution error: \(error)")
            #endif
        }
    }

    /// Mensaje accionable: el vacío casi siempre es portal/provisioning, no «dato perdido».
    private static func hint(for error: Error) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("auth") || text.contains("entitlement") || text.contains("permission")
            || text.contains("not entitled") || text.contains("401") || text.contains("403") {
            return "WeatherKit no autorizado · activa App Services → WeatherKit en el App ID y regenera el perfil."
        }
        if text.contains("network") || text.contains("internet") || text.contains("offline")
            || text.contains("timed out") {
            return "Sin red para consultar el tiempo histórico."
        }
        return "Tiempo no disponible (\(error.localizedDescription))."
    }
}

/// Mapa + franja de clima en una sola card (el clima «sale» del mapa).
struct SessionMapWeatherCard<MapContent: View>: View {
    var mapHeight: CGFloat = 240
    var latitude: Double?
    var longitude: Double?
    var workoutDate: Date
    @ViewBuilder var map: () -> MapContent

    var body: some View {
        VStack(spacing: 0) {
            map()
                .frame(height: mapHeight)
                .frame(maxWidth: .infinity)
                .clipped()
            if let latitude, let longitude {
                Divider().opacity(0.35)
                RouteWeatherStrip(
                    latitude: latitude,
                    longitude: longitude,
                    workoutDate: workoutDate
                )
            }
        }
        .background(OG.surface)
        .clipShape(RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
    }
}
