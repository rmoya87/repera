"""Static regressions for workout location captions and Home calendar anchor.

The Swift layout still needs a device/Xcode build; these assertions guarantee
that UI spacing/scroll intent is represented in the checked-in code.
"""
from pathlib import Path
import unittest

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"


def swift(filename):
    return (SRC / filename).read_text(encoding="utf-8")


class WorkoutSummaryAndHomeCalendarTests(unittest.TestCase):
    def test_date_is_section_header_outside_rounded_list_row(self):
        history = swift("HistoryView.swift")
        header = history.split("private var detailList: some View {", 1)[1].split(
            "// El mapa va directamente debajo", 1
        )[0]
        # El header, no una fila redondeada, contiene la primera letra.
        self.assertIn("Section {", header)
        self.assertIn("} header: {", header)
        self.assertIn(".ogCardListRow(top: 0, bottom: 2)", header)
        self.assertLess(header.index("summaryCard(session)"), header.index("} header: {"))
        subtitle = header.split("} header: {", 1)[1]
        self.assertIn("Text(subtitle)", subtitle)
        self.assertIn(".fixedSize(horizontal: false, vertical: true)", subtitle)
        self.assertIn(".padding(.leading, 2)", subtitle)
        self.assertIn(".textCase(nil)", subtitle)
        self.assertNotIn(".offset(x: -6)", subtitle)

    def test_pin_label_is_not_repeated_below_map(self):
        history = swift("HistoryView.swift")
        section = history.split("SessionMapWeatherCard(", 1)[1].split(
            "// Plantilla única: métricas deportivas", 1
        )[0]
        self.assertIn("sessionMapView(session)", section)
        self.assertNotIn('Text("Ubicación")', section)
        self.assertNotIn('Text("Colores = velocidad', section)
        self.assertIn('WorkoutLocationPinMap(pin: pin, isInteractive: false)', history)
        self.assertNotIn("Text(name)", section)
        self.assertNotIn("session.locationPin?.name", section)

    def test_comenzar_splits_survive_private_supabase_restore(self):
        history = swift("HistoryView.swift")
        detail = history.split("private var detailList: some View {", 1)[1].split(
            "if isEditing {", 1
        )[0]
        # Hay distancia, tiempo y parciales aunque no haya puntos de ruta.
        self.assertIn("Recorrido no disponible en este dispositivo", detail)
        self.assertIn("session.liveKilometerSplitsSeconds", detail)
        self.assertIn("session.recordedDistanceMeters", detail)
        self.assertIn("session.activeDurationSeconds", detail)
        self.assertEqual(detail.count("CardioSplitsView("), 1)
        self.assertLess(detail.index("CardioSplitsView("), detail.index("HealthSessionMetricsCard("))
        self.assertIn('Text("Entreno")', detail)
        self.assertNotIn('Text("Parciales")', detail)
        self.assertIn("embedded: true", detail)
        self.assertIn("totalActiveSeconds: session.activeDurationSeconds", detail)
        self.assertIn("totalDistanceMeters: session.recordedDistanceMeters", detail)
        splits = swift("CardioRouteComponents.swift")
        self.assertIn('title: "Ritmo medio"', splits)
        self.assertIn('title: "Vel. media"', splits)
        self.assertIn('title: "Vel. máx"', splits)
        self.assertIn("if let recorded = activeKilometerSeconds", splits)

    def test_same_workout_template_for_repera_health_and_comenzar(self):
        history = swift("HistoryView.swift")
        live = swift("LiveActivityView.swift")
        # Mismo elemento visual de mapa y mismo destino interactivo.
        for code in (history, live):
            self.assertIn("SessionMapWeatherCard(", code)
            self.assertIn("HealthWorkoutRouteMap(", code)
            self.assertIn("WorkoutMapZoomDestination(", code)
            self.assertIn('Text("Entreno")', code)
            self.assertIn("CardioSplitsView(", code)
            self.assertIn("HealthSessionMetricsCard(", code)
            self.assertNotIn('Text("Parciales")', code)
            self.assertNotIn('Text("Colores = velocidad', code)
        tiles = swift("RegisterSessionChrome.swift")
        self.assertIn("struct WorkoutSummaryTile: View", tiles)
        self.assertEqual(history.count("WorkoutSummaryTile(title: title, value: value, icon: icon, tint: tint)"), 2)
        self.assertIn("WorkoutSummaryTile(title: label, value: value, icon: icon, tint: tint)", live)
        self.assertIn("struct WorkoutMapZoomDestination: View", history)
        self.assertIn("struct WorkoutMapTapTarget<MapPreview: View>: View", history)
        self.assertGreaterEqual(history.count("WorkoutMapTapTarget("), 3)
        self.assertIn("WorkoutMapTapTarget(", live)
        tap = history.split("struct WorkoutMapTapTarget<MapPreview: View>: View", 1)[1].split(
            "/// Único destino de mapa", 1
        )[0]
        self.assertIn("map()", tap)
        self.assertIn(".allowsHitTesting(false)", tap)
        self.assertIn(".overlay {", tap)
        self.assertIn("Button(action: action)", tap)
        self.assertIn(".contentShape(Rectangle())", tap)
        self.assertIn("matchedTransitionSource(id: sessionId, in: routeZoomNamespace)", history)
        self.assertIn("matchedTransitionSource(id: activityId, in: routeZoomNamespace)", history)

    def test_cardio_elevation_equal_heights_no_duplicate_speed_tiles(self):
        route = swift("CardioRouteComponents.swift")
        history = swift("HistoryView.swift")
        charts = route.split("struct CardioAltitudeChart: View {", 1)[1].split(
            "struct SessionSportMetricTile: View", 1
        )[0]
        cardio = charts.split("private var cardio: some View", 1)[1].split(
            "private var elevation: some View", 1
        )[0]
        elevation = charts.split("private var elevation: some View", 1)[1].split(
            "private var cardioStatTiles: some View", 1
        )[0]
        self.assertIn(".frame(height: 170)", cardio)
        self.assertIn(".frame(height: 170)", elevation)
        self.assertNotIn(".frame(height: 145)", charts)
        self.assertIn('miniStat("Media"', charts)
        self.assertNotIn('miniStat("Vel. media"', charts)
        self.assertNotIn('miniStat("Vel. máx"', charts)
        heart = history.split("private struct HealthHeartRateStatRow: View", 1)[1].split(
            "/// Superficie de toque independiente de MapKit.", 1
        )[0]
        self.assertNotIn('stat("Vel. media"', heart)
        self.assertNotIn('stat("Vel. máx"', heart)

    def test_sport_metrics_do_not_invent_gps_for_padel_or_tennis(self):
        splits = swift("CardioRouteComponents.swift")
        self.assertIn("sport?.usesGPS", splits)
        self.assertIn("healthStats?.isOutdoorRouteActivity == true", splits)
        self.assertIn('title: "Pulso medio"', splits)
        self.assertIn('"Pasos en horario"', splits)
        self.assertIn('"Dist. en horario"', splits)
        self.assertIn('title: "Vel. media"', splits)
        self.assertIn('title: "Vel. máx"', splits)
        self.assertIn('title: "Ritmo medio"', splits)
        self.assertIn('title: "Distancia"', splits)
        self.assertIn("recordedMaxSpeedKmh", splits)
        self.assertIn('value: recordedMaxSpeedKmh.map(decimal) ?? "—"', splits)
        self.assertNotIn("17,2", splits)

    def test_measured_steps_and_distance_for_all_workouts(self):
        health = swift("HealthKitStore.swift")
        splits = swift("CardioRouteComponents.swift")
        detail = swift("HistoryView.swift")

        for kind in (".stepCount", ".distanceWalkingRunning", ".distanceCycling",
                     ".distanceDownhillSnowSports", ".distanceSwimming"):
            self.assertIn(kind, health)
        self.assertIn("HKQuery.predicateForObjects(from: workout)", health)
        self.assertIn("withStart: workout.startDate, end: workout.endDate", health)
        self.assertIn("workout.statistics(for: candidate.type)", health)
        self.assertIn("workout.totalDistance?", health)
        self.assertIn("movementUsesTimeWindow", health)
        self.assertIn('case .surfingSports, .paddleSports, .rowing, .sailing:', health)
        self.assertIn('"Pasos en horario"', splits)
        self.assertIn('"Dist. en horario"', splits)
        self.assertIn('"Distancia a pie"', health)
        self.assertIn('title: "Ritmo medio"', splits)
        self.assertIn("hasMovement", detail)
        self.assertIn("stepsCount: stepsCount", detail)
        self.assertIn("movementDistanceMeters: movementDistanceMeters", detail)
        self.assertIn("movementDistanceLabel: movementDistanceLabel", detail)
        self.assertIn("movementUsesTimeWindow: movementUsesTimeWindow", detail)

    def test_finished_home_workout_uses_green_strength_icon_and_tighter_chips(self):
        home = swift("HomeView.swift")
        done = home.split("private func dayWorkoutCard(", 1)[1].split(
            "private func healthActivityCard(", 1
        )[0]
        self.assertIn('?? "figure.strengthtraining.traditional"', done)
        self.assertIn("tint: OG.accent", done)
        self.assertNotIn('?? "checkmark"', done)
        planned = home.split("private func plannedDayCard(", 1)[1].split(
            "private func dayWorkoutCard(", 1
        )[0]
        self.assertIn('systemName: "figure.strengthtraining.traditional"', planned)
        self.assertIn("tint: OG.label2", planned)
        self.assertIn(".frame(height: 24, alignment: .center)", home)
        swipe = swift("RegisterSwipeRevealCard.swift")
        self.assertIn("VStack(alignment: .leading, spacing: 0)", swipe)
        self.assertIn(".padding(.top, 0)", home)

    def test_home_day_workouts_are_oldest_first(self):
        home = swift("HomeView.swift")
        rebuild = home.split("private func rebuildDayBuckets() {", 1)[1].split(
            "var kcals:", 1
        )[0]
        # Chronological order both for Repera sessions and Health activities.
        self.assertIn(
            "($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)",
            rebuild,
        )
        self.assertIn("healthMap[key]?.sort { $0.start < $1.start }", rebuild)
        self.assertNotIn(
            "($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast)",
            rebuild,
        )
        self.assertNotIn("healthMap[key]?.sort { $0.start > $1.start }", rebuild)

    def test_summary_tiles_put_title_beside_icon_and_value_below(self):
        chrome = swift("RegisterSessionChrome.swift")
        summary = chrome.split("struct WorkoutSummaryTile: View {", 1)[1].split(
            "struct OGRegisterLeadingIcon:", 1
        )[0]
        header = summary.split("HStack(spacing: 6) {", 1)[1].split(
            ".frame(maxWidth: .infinity, alignment: .center)", 1
        )[0]
        self.assertIn("Image(systemName: icon)", header)
        self.assertIn("Text(title)", header)
        self.assertLess(header.index("Image(systemName: icon)"), header.index("Text(title)"))
        self.assertLess(summary.index("Text(title)"), summary.index("Text(value)"))
        self.assertNotIn("Text(title)", summary.split("Text(value)", 1)[1])
        # La altura se ajusta al contenido: sin altura mínima que cree
        # un hueco excesivo debajo del valor.
        self.assertIn("VStack(alignment: .leading, spacing: 7)", summary)
        self.assertIn(".padding(.vertical, 10)", summary)
        self.assertIn(".padding(.horizontal, 12)", summary)
        self.assertNotIn("minHeight: 64", summary)


        # También en los tres indicadores del pie del mapa meteorológico.
        cardio = swift("CardioRouteComponents.swift")
        weather = cardio.split("private func weatherStat(", 1)[1].split(
            "private func loadWeather()", 1
        )[0]
        self.assertLess(weather.index("Image(systemName: symbol)"), weather.index("Text(title)"))
        self.assertLess(weather.index("Text(title)"), weather.index('Text(value ?? "—")'))

        # Inicio y Progreso ya muestran el icono y su etiqueta en la cabecera.
        home = swift("HomeView.swift").split(
            "private func metricTile(", 1
        )[1].split("private func setLine(", 1)[0]
        stats = swift("StatsView.swift").split(
            "private func tile(", 1
        )[1].split("// MARK: - Activity", 1)[0]
        for component in (home, stats):
            self.assertLess(component.index("Image(systemName: icon)"),
                            component.index("Text(title)" if component is home else "Text(label)"))
            self.assertLess(component.index("Text(title)" if component is home else "Text(label)"),
                            component.index("Text(value)"))

    def test_all_key_metric_tiles_are_centered(self):
        summary = swift("RegisterSessionChrome.swift").split(
            "struct WorkoutSummaryTile: View {", 1
        )[1].split("struct OGRegisterLeadingIcon:", 1)[0]
        self.assertIn("VStack(alignment: .center, spacing: 7)", summary)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .center)", summary)

        home = swift("HomeView.swift")
        activity = home.split("private func homeActivityMetric(", 1)[1].split(
            "/// Entreno del día:", 1
        )[0]
        metric = home.split("private func metricTile(", 1)[1].split(
            "private func setLine(", 1
        )[0]
        self.assertIn("VStack(alignment: .center, spacing: 8)", activity)
        self.assertIn("VStack(alignment: .center, spacing: 12)", metric)

        stats = swift("StatsView.swift")
        tile = stats.split("private func tile(", 1)[1].split(
            "// MARK: - Activity", 1
        )[0]
        self.assertIn("VStack(alignment: .center, spacing: 4)", tile)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .center)", tile)
        self.assertIn("if let delta {", tile)
        self.assertNotIn(".opacity(0)", tile)

    def test_progress_compares_actual_total_minutes_in_all_tiers(self):
        stats = swift("StatsView.swift")
        free = stats.split("private var freeTilesGrid:", 1)[1].split(
            "@ViewBuilder", 1
        )[0]
        pro = stats.split("private var tilesGrid:", 1)[1].split(
            "private func tile(", 1
        )[0]
        for section in (free, pro):
            self.assertIn("summary.totalMinutes", section)
            self.assertIn('label: "Tiempo"', section)
            self.assertIn("delta: previous.map", section)
            self.assertNotIn('delta: nil', section)
        snapshot = swift("ProgressSnapshot.swift")
        self.assertIn("totalMinutes: baseSummary.totalMinutes", snapshot)
        self.assertIn("totalMinutes: basePrevious.totalMinutes", snapshot)
        self.assertIn("referenceDay: Date", snapshot)

    def test_home_initial_scroll_shows_yesterday_first_today_second(self):
        home = swift("HomeView.swift")
        rebuild = home.split("private func rebuildWeekChrome() {", 1)[1].split(
            "private func rebuildStreakChrome()", 1
        )[0]
        self.assertIn("if calendarScrollID == nil", rebuild)
        self.assertIn("calendar.date(byAdding: .day, value: -1, to: selectedDay)", rebuild)
        self.assertIn("cachedCalendarDays.first(where:", rebuild)
        self.assertIn("calendar.isDate($0.date, inSameDayAs: firstVisibleDate)", rebuild)
        self.assertIn("?.iso", rebuild)
        self.assertNotIn("calendarScrollID = makeWeekDays(offset: 0).first?.iso\n        }", rebuild)
        self.assertIn("@State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())", home)
        self.assertIn(".scrollPosition(id: $calendarScrollID, anchor: .leading)", home)


if __name__ == "__main__":
    unittest.main()
