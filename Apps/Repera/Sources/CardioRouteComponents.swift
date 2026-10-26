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
                .frame(height: 170)
        }
    }

    @ViewBuilder
    private var elevation: some View {
        HStack {
            Label("Perfil del recorrido", systemImage: "mountain.2.fill")
                .foregroundStyle(OG.accent)
            Spacer(minLength: 6)
            if let point = pickedAltitude {
                Text("\(ReperaNumberFormat.decimal(point.altitudeMeters, maximumFractionDigits: 0)) m · \(ReperaNumberFormat.decimal(point.distanceKm)) km")
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
        } else {
            ContentUnavailableView("Altitud no disponible", systemImage: "mountain.2",
                                   description: Text("La ruta no incluye altitudes GPS válidas."))
                .frame(height: 170)
        }
    }

    @ViewBuilder
    private var cardioStatTiles: some View {
        // Misma retícula/alto que Altitud: solo FC, nunca repetir
        // velocidad media o máxima que ya están en Entreno.
        HStack(spacing: 7) {
            miniStat("Mín", value: extras.minHeartRateBpm.map { "\(Int($0.rounded()))" },
                     unit: "lpm", tint: OG.accent)
            miniStat("Media", value: extras.averageHeartRateBpm.map { "\(Int($0.rounded()))" },
                     unit: "lpm", tint: OG.blue)
            miniStat("Máx", value: extras.maxHeartRateBpm.map { "\(Int($0.rounded()))" },
                     unit: "lpm", tint: OG.red)
        }
    }

    @ViewBuilder
    private var altitudeStatTiles: some View {
        HStack(spacing: 7) {
            miniStat("Mín", value: altitudeStats.map { "\(Int($0.min.rounded()))" },
                     unit: "m", tint: OG.label2)
            miniStat("Media", value: altitudeStats.map { "\(Int($0.avg.rounded()))" },
                     unit: "m", tint: OG.blue)
            miniStat("Máx", value: altitudeStats.map { "\(Int($0.max.rounded()))" },
                     unit: "m", tint: OG.accent)
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
        .frame(height: 72)
        .background(OG.surface2.opacity(0.85),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Una sola plantilla de tile para métricas de cada deporte.
struct SessionSportMetricTile: View {
    var title: String
    var value: String
    var unit: String
    var tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(OG.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(OG.surface2.opacity(0.85),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Km terminados: interpolación en el cruce de cada kilómetro, no medias generales.
struct CardioSplitsView: View {
    var routePoints: [HealthKitStore.RoutePoint]
    var heartRate: [HealthKitStore.HeartRatePoint]
    var cycling: Bool = false
    /// Si Repera midió los parciales con su reloj activo, preferirlos sobre
    /// los timestamps GPS que incluyen intervalos en pausa.
    var activeKilometerSeconds: [Double]? = nil
    /// Totales de la actividad completa, no solo los kilómetros cerrados.
    var totalActiveSeconds: Double? = nil
    var totalDistanceMeters: Double? = nil
    var maxSpeedKmh: Double? = nil
    var healthStats: HealthKitStore.SessionHealthExtras? = nil
    var sport: LiveSport? = nil
    /// Dentro de una única card que también contiene las gráficas de Salud.
    var embedded: Bool = false

    private var recordedMaxSpeedKmh: Double? {
        if let maxSpeedKmh, maxSpeedKmh > 0 { return maxSpeedKmh }
        return routePoints.compactMap(\.speedMps)
            .filter { $0.isFinite && $0 > 0 && $0 <= 50 }
            .max().map { $0 * 3.6 }
    }

    private func decimal(_ number: Double) -> String {
        ReperaNumberFormat.decimal(number)
    }

    private var healthMovementMeters: Double? {
        if let totalDistanceMeters, totalDistanceMeters > 0 { return totalDistanceMeters }
        return healthStats?.movementDistanceMeters
    }

    private var stepsCount: Int? { healthStats?.stepsCount }

    private var hasGPSMetrics: Bool {
        let isOutdoorMovement = sport?.usesGPS
            ?? (healthStats?.isOutdoorRouteActivity == true || routePoints.count >= 2)
        return isOutdoorMovement &&
            ((healthMovementMeters ?? 0) > 0 || routePoints.count >= 2 || !displayedSplits.isEmpty)
    }

    private var averageSpeedKmh: Double? {
        guard let seconds = totalActiveSeconds, seconds > 0,
              let meters = healthMovementMeters, meters > 0 else { return nil }
        return meters / seconds * 3.6
    }

    private var averagePace: String? {
        guard let seconds = totalActiveSeconds, seconds > 0,
              let meters = healthMovementMeters, meters > 0 else { return nil }
        let secondsPerKm = Int((seconds / (meters / 1000)).rounded())
        return String(format: "%d:%02d min/km", secondsPerKm / 60, secondsPerKm % 60)
    }

    private struct DisplaySplit: Identifiable {
        var id: Int { kilometer }
        var kilometer: Int
        var seconds: Double
        var averageBpm: Double?
    }

    private var displayedSplits: [DisplaySplit] {
        if let recorded = activeKilometerSeconds, !recorded.isEmpty {
            return recorded.enumerated().compactMap { index, seconds in
                guard seconds.isFinite && seconds > 0 else { return nil }
                let km = index + 1
                return DisplaySplit(
                    kilometer: km, seconds: seconds,
                    averageBpm: splits.first { $0.kilometer == km }?.averageBpm
                )
            }
        }
        return splits.map {
            DisplaySplit(kilometer: $0.kilometer, seconds: $0.seconds,
                         averageBpm: $0.averageBpm)
        }
    }

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
        VStack(alignment: .leading, spacing: 12) {
            if hasGPSMetrics {
                HStack(spacing: 7) {
                    SessionSportMetricTile(
                        title: "Vel. media",
                        value: averageSpeedKmh.map(decimal) ?? "—",
                        unit: "km/h", tint: OG.blue
                    )
                    SessionSportMetricTile(
                        title: "Vel. máx",
                        value: recordedMaxSpeedKmh.map(decimal) ?? "—",
                        unit: "km/h", tint: OG.accent
                    )
                    if cycling || sport?.displaysSpeed == true {
                        // Ciclismo y deportes acuáticos priorizan distancia
                        // frente a un ritmo por kilómetro poco representativo.
                        SessionSportMetricTile(
                            title: "Distancia",
                            value: healthMovementMeters.map { decimal($0 / 1000) } ?? "—",
                            unit: "km", tint: OG.label
                        )
                    } else {
                        SessionSportMetricTile(
                            title: "Ritmo medio",
                            value: averagePace.map {
                                $0.replacingOccurrences(of: " min/km", with: "")
                            } ?? "—",
                            unit: "min/km", tint: OG.label
                        )
                    }
                }

                if let stepsCount, !(sport?.isWaterSport ?? false),
                   stepsCount > 0 {
                    SessionSportMetricTile(
                        title: healthStats?.movementUsesTimeWindow == true
                            ? "Pasos en horario" : "Pasos",
                        value: ReperaNumberFormat.integer(stepsCount),
                        unit: "pasos", tint: OG.accent
                    )
                }

                if !displayedSplits.isEmpty {
                    HStack(spacing: 6) {
                        Text("KM").frame(width: 38, alignment: .leading)
                        Text("Tiempo").frame(maxWidth: .infinity, alignment: .leading)
                        Text(cycling ? "km/h" : "Ritmo").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Frec. cardiaca").frame(width: 88, alignment: .trailing)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(OG.label3)
                    .padding(.vertical, 8)

                    ForEach(displayedSplits) { split in
                        Divider().opacity(0.30)
                        HStack(spacing: 6) {
                            Text("\(split.kilometer)")
                                .fontWeight(.semibold)
                                .frame(width: 38, alignment: .leading)
                            Text(Self.clock(split.seconds))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(cycling
                                 ? ReperaNumberFormat.decimal(3600 / max(1, split.seconds))
                                 : "\(Self.clock(split.seconds))/km")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(split.averageBpm.map { "\(Int($0.rounded())) LPM" } ?? "—")
                                .frame(width: 88, alignment: .trailing)
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(OG.label)
                        .padding(.vertical, 12)
                    }
                }
            } else if let healthStats {
                // Tenis/pádel y sesiones de fuerza con cardio: pasos y
                // distancia medidos. No equivale a metros de pista exactos.
                HStack(spacing: 7) {
                    if let steps = healthStats.stepsCount, steps > 0 {
                        SessionSportMetricTile(
                            title: healthStats.movementUsesTimeWindow
                                ? "Pasos en horario" : "Pasos",
                            value: ReperaNumberFormat.integer(steps), unit: "pasos", tint: OG.accent
                        )
                    }
                    if let meters = healthStats.movementDistanceMeters, meters > 0 {
                        SessionSportMetricTile(
                            title: healthStats.movementUsesTimeWindow
                                ? "Dist. en horario"
                                : (healthStats.movementDistanceLabel ?? "Distancia"),
                            value: meters >= 1000 ? decimal(meters / 1000) : "\(Int(meters.rounded()))",
                            unit: meters >= 1000 ? "km" : "m", tint: OG.blue
                        )
                    }
                    if let bpm = healthStats.averageHeartRateBpm, bpm > 0 {
                        SessionSportMetricTile(
                            title: "Pulso medio",
                            value: "\(Int(bpm.rounded()))",
                            unit: "lpm", tint: OG.red
                        )
                    }
                }
            }
        }
        .padding(embedded ? 0 : OG.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if !embedded {
                RoundedRectangle(cornerRadius: OG.radiusCard).fill(OG.surface)
            }
        }
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
    @State private var windKmh: Double?
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
                    value: temperatureC.map { "\(ReperaNumberFormat.decimal($0, maximumFractionDigits: 0)) °C" },
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
                weatherStat(
                    symbol: "wind", title: "Viento",
                    value: windKmh.map { "\(ReperaNumberFormat.decimal($0, maximumFractionDigits: 0)) km/h" },
                    loading: isLoading
                )
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
                Text("Datos meteorológicos no disponibles.")
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label2)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OG.label2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadWeather() async {
        humidity = nil
        windKmh = nil
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
        windKmh = hour.wind.speed.converted(to: .kilometersPerHour).value
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
