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
            } else {
                elevation
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
            .frame(height: 170)
        } else {
            ContentUnavailableView("Sin curva de pulso", systemImage: "heart",
                                   description: Text("No hay suficientes muestras de frecuencia cardíaca."))
                .frame(height: 145)
        }
    }

    private var elevationRange: ClosedRange<Double> {
        let values = result.profile.map(\.altitudeMeters)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 1
        let padding = max(4, (maximum - minimum) * 0.14)
        return (minimum - padding)...(maximum + padding)
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
                    AreaMark(x: .value("Distancia", point.distanceKm),
                             y: .value("Altitud", point.altitudeMeters))
                        .interpolationMethod(.linear)
                        .foregroundStyle(LinearGradient(colors: [OG.accent.opacity(0.26), OG.accent.opacity(0.015)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Distancia", point.distanceKm),
                             y: .value("Altitud", point.altitudeMeters))
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
            .chartYScale(domain: elevationRange)
            .chartXAxisLabel("km")
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                    AxisGridLine().foregroundStyle(OG.surface3)
                    AxisValueLabel()
                }
            }
            .frame(height: 170)
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
                Text(cycling ? "km/h" : "min/km").frame(maxWidth: .infinity, alignment: .leading)
                Text("FC").frame(width: 55, alignment: .trailing)
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
                             : Self.clock(split.paceSecondsPerKm))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(split.averageBpm.map { "\(Int($0.rounded()))" } ?? "—")
                            .frame(width: 55, alignment: .trailing)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(OG.label)
                    .padding(.vertical, 12)
                }
            }
            Text("FC: media de las muestras disponibles en cada parcial. Ritmo y tiempos basados en GPS.")
                .font(.caption2)
                .foregroundStyle(OG.label3)
                .padding(.top, 12)
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

/// Condiciones en la fecha de entrenamiento: consulta efímera Apple WeatherKit.
/// El proveedor no ofrece en esta integración un AQI histórico verificado.
struct RouteWeatherStrip: View {
    var latitude: Double
    var longitude: Double
    var workoutDate: Date

    @State private var temperatureC: Double?
    @State private var humidity: Double?
    @State private var symbol = "cloud.sun"
    @State private var attributionURL: URL?
    @State private var attributionMarkURL: URL?

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                weatherStat(symbol: symbol, title: "Tiempo",
                            value: temperatureC.map { String(format: "%.0f °C", $0) } ?? "—")
                Divider().frame(height: 38)
                weatherStat(symbol: "humidity", title: "Humedad",
                            value: humidity.map { "\(Int(($0 * 100).rounded())) %" } ?? "—")
                Divider().frame(height: 38)
                weatherStat(symbol: "aqi.medium", title: "Calidad aire", value: "—")
            }
            if let attributionURL, let attributionMarkURL {
                Link(destination: attributionURL) {
                    HStack(spacing: 6) {
                        AsyncImage(url: attributionMarkURL) { image in
                            image.resizable().scaledToFit().frame(height: 13)
                        } placeholder: {
                            Text("Apple Weather").font(.caption2)
                        }
                        Text("· Histórico por hora")
                            .font(.caption2)
                            .foregroundStyle(OG.label3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                Text("Tiempo histórico no disponible · Calidad del aire sin fuente histórica.")
                    .font(.caption2)
                    .foregroundStyle(OG.label3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 9)
        .task(id: "\(latitude),\(longitude),\(workoutDate.timeIntervalSince1970)") {
            await loadWeather()
        }
        .accessibilityElement(children: .contain)
    }

    private func weatherStat(symbol: String, title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(OG.accent)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(OG.label)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(OG.label2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadWeather() async {
        humidity = nil
        temperatureC = nil
        attributionURL = nil
        attributionMarkURL = nil
        // No solicitar predicciones actuales como si fueran condiciones pasadas.
        guard workoutDate <= Date(),
              Date().timeIntervalSince(workoutDate) < 365 * 24 * 3600,
              (-90...90).contains(latitude), (-180...180).contains(longitude)
        else { return }
        do {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let hourly = try await WeatherService.shared.weather(
                for: location,
                including: .hourly(startDate: workoutDate.addingTimeInterval(-3600),
                                   endDate: workoutDate.addingTimeInterval(3600))
            )
            guard let hour = hourly.forecast.min(by: {
                abs($0.date.timeIntervalSince(workoutDate)) < abs($1.date.timeIntervalSince(workoutDate))
            }), abs(hour.date.timeIntervalSince(workoutDate)) <= 3600 else { return }
            let attribution = try await WeatherService.shared.attribution
            // Nunca mostrar información de WeatherKit sin su atribución legal.
            attributionURL = attribution.legalPageURL
            attributionMarkURL = attribution.combinedMarkLightURL
            temperatureC = hour.temperature.converted(to: .celsius).value
            humidity = hour.humidity
            symbol = hour.symbolName
        } catch {
            // Denegación de WeatherKit, histórico no cubierto o red: mostrar —.
        }
    }
}
