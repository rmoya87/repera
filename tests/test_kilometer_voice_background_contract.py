"""Contrato de los avisos por kilómetro de Comenzar en iOS 27.

No sustituye una prueba de GPS, Bluetooth y audio en un iPhone físico.
"""
import pathlib
import plistlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
LIVE = (ROOT / "Apps/Repera/Sources/LiveActivityView.swift").read_text(encoding="utf-8")
DOMAIN = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/KilometerVoiceAnnouncement.swift").read_text(encoding="utf-8")


class KilometerVoiceBackgroundContractTests(unittest.TestCase):
    def test_crossing_notifies_immediately_using_gps_crossing_seconds(self):
        self.assertIn("reportKilometer(split, elapsedActiveSeconds: crossingSeconds)", LIVE)
        self.assertIn("KilometerVoiceAnnouncement.message(", LIVE)
        self.assertIn("splitSeconds: split.seconds", LIVE)
        self.assertIn("elapsedSeconds: elapsedActiveSeconds", LIVE)
        self.assertIn("let didSpeak = speakNavigation(message)", LIVE)

    def test_every_gps_sport_including_walking_gets_speed_in_kmh(self):
        self.assertIn("case .walking: \"Caminata\"", LIVE)
        self.assertIn("case .walking, .hiking", LIVE)
        self.assertIn("Velocidad media del tramo:", DOMAIN)
        self.assertIn("Velocidad media desde el inicio:", DOMAIN)
        self.assertNotIn("sport.displaysSpeed\n                ?", LIVE)

    def test_pending_speech_is_not_deactivated_between_utterances(self):
        self.assertIn("pendingGuidanceUtterances: Set<ObjectIdentifier>", LIVE)
        self.assertIn("pendingGuidanceUtterances.insert(ObjectIdentifier(phrase))", LIVE)
        self.assertIn("guard pendingGuidanceUtterances.isEmpty, guidanceAudioActive", LIVE)
        self.assertIn("finishGuidanceUtterance(id)", LIVE)
        self.assertIn("private func stopGuidanceAudio()", LIVE)

    def test_pause_and_resume_are_completely_silent(self):
        # Al pausar o reanudar solo cambia el estado, sin voz ni pitidos.
        for name, next_name in [("pause", "resume"), ("resume", "var durationSeconds")]:
            body = LIVE.split(f"func {name}() {{", 1)[1].split(next_name, 1)[0]
            self.assertNotIn("speakNavigation(", body)
            self.assertNotIn("RestFeedback.tick(", body)
            self.assertNotIn("RestFeedback.restComplete(", body)
            self.assertIn("stopGuidanceAudio()", body)
        self.assertNotIn("LiveSessionVoiceAnnouncement", LIVE)
        self.assertIn("guard spokenGuidanceEnabled, !message.isEmpty else", LIVE)
        # Se conservan los anuncios de navegación GPS y parciales.
        self.assertIn("let didSpeak = speakNavigation(message)", LIVE)
        self.assertIn("let didSpeak = speakNavigation(spokenTurn)", LIVE)

    def test_start_and_finish_announcements_are_not_lifecycle_duplicates(self):
        # Solo se habla al pulsar los botones, no al recuperar el GPS,
        # volver a primer plano ni redibujar SwiftUI.
        recover = LIVE.split("func resumeInterruptedRecordingIfNeeded() {", 1)[1].split(
            "func toggleSpokenGuidance()", 1
        )[0]
        self.assertNotIn("speakNavigation(", recover)
        refresh = LIVE.split("func refreshWhenActive() {", 1)[1].split(
            "func pause() {", 1
        )[0]
        self.assertNotIn("speakNavigation(", refresh)
        self.assertIn("RestFeedback.restComplete(sound: spokenGuidanceEnabled, haptic: true)", LIVE)
        self.assertIn("recorder.phase != .review", LIVE)
        self.assertIn("metricsTrailingActions", LIVE)
        self.assertNotIn('else if recorder.sport.usesGPS {\n                        metricsCircleButton("map", label: "Ver mapa")', LIVE)
        self.assertIn("Desactivar avisos por voz", LIVE)

    def test_audio_visible_before_start_and_preference_persists(self):
        self.assertIn("private var showGuidanceToggle: Bool", LIVE)
        self.assertIn("recorder.phase != .review", LIVE)
        # Hay un altavoz en mapa y otro en métricas; ambos usan el mismo recorder.
        self.assertIn("if showGuidanceToggle {", LIVE)
        self.assertGreaterEqual(LIVE.count("recorder.toggleSpokenGuidance()"), 2)
        self.assertIn('private let spokenGuidanceKey = "repera.live.spokenGuidance.enabled"', LIVE)
        self.assertIn("private(set) var spokenGuidanceEnabled = true", LIVE)
        self.assertIn("UserDefaults.standard.bool(forKey: spokenGuidanceKey)", LIVE)
        self.assertIn("UserDefaults.standard.set(spokenGuidanceEnabled, forKey: spokenGuidanceKey)", LIVE)
        self.assertIn("guard spokenGuidanceEnabled, !message.isEmpty else", LIVE)

    def test_map_starts_flat_and_persists_previous_selection(self):
        self.assertIn(
            '@AppStorage("repera.live.map.navigation3D.enabled") private var navigationMapEnabled = false',
            LIVE
        )
        self.assertNotIn("@State private var navigationMapEnabled = true", LIVE)
        self.assertIn("navigationMapEnabled.toggle()", LIVE)
        self.assertIn(".mapStyle(.standard(elevation: navigationMapEnabled ? .realistic : .flat))", LIVE)
        self.assertIn("if !navigationMapEnabled {", LIVE)
        self.assertIn("pitch: 0", LIVE)
        self.assertIn("pitch: 67", LIVE)
        self.assertIn("center3DMap(on: user)", LIVE)

    def test_metrics_header_stays_fixed_during_recording_and_pause(self):
        # El texto no cambia de anchura ni genera una tercera línea al aparecer
        # Finalizar; en ambas fases Pausa/Play comparte la misma posición.
        header = LIVE.split("private var metricsView: some View", 1)[1].split(
            "private var metricsTrailingActions: some View", 1
        )[0]
        self.assertIn(".frame(width: 28)", header)
        self.assertIn(".lineLimit(2)", header)
        self.assertIn(".minimumScaleFactor(0.68)", header)
        self.assertIn("GeometryReader { header in", header)
        self.assertIn("width: min(126, max(48, header.size.width - 240))", header)
        self.assertIn("Spacer(minLength: 0)", header)
        self.assertIn(".padding(.horizontal, OG.topBarHorizontalInset)", header)
        self.assertIn(".frame(maxWidth: .infinity, alignment: .trailing)", header)
        self.assertIn(".fixedSize(horizontal: true, vertical: false)", header)
        self.assertNotIn('Text("En pausa")', header)
        self.assertNotIn('Text("Grabando actividad")', header)
        actions = LIVE.split("private var metricsTrailingActions: some View", 1)[1].split(
            "private var selectionCircleBackground: Color", 1
        )[0]
        self.assertIn("HStack(spacing: 6)", actions)
        self.assertNotIn("metricsActionPlaceholder", actions)
        self.assertIn("if recorder.phase == .recording {", actions)
        self.assertEqual(actions.count("if recorder.phase == .paused {"), 1)
        # En pausa el orden es Audio · Mapa · Finalizar · Play.
        # La bandera negra está directamente a la izquierda del botón verde;
        # ambos pertenecen a la misma rama condicional de pausa.
        self.assertLess(actions.index("guidanceSymbol"), actions.index('metricsCircleButton("map"'))
        self.assertLess(actions.index('metricsCircleButton("map"'), actions.index('"flag.checkered"'))
        self.assertLess(actions.index('"flag.checkered"'), actions.index('"play.fill"'))
        paused = actions.split("} else if recorder.phase == .paused {", 1)[1]
        self.assertIn('"flag.checkered"', paused)
        self.assertIn('"play.fill"', paused)
        self.assertLess(paused.index("finishAndShowSave()"), paused.index("recorder.resume()"))
        self.assertNotIn('"flag.checkered"', actions.split("if showGuidanceToggle", 1)[0])

    def test_finish_button_uses_visible_charcoal_liquid_glass_in_dark_mode(self):
        # Flag mantiene su icono blanco pero recibe una superficie carbón
        # visible frente al mapa oscuro y al fondo nocturno de Métricas.
        button = LIVE.split("private func sessionMapButton(", 1)[1].split(
            "private func metricsCircleButton(", 1
        )[0]
        self.assertIn('symbol == "flag.checkered" && colorScheme == .dark', button)
        self.assertIn(".background(OG.surface2, in: Circle())", button)
        self.assertIn(
            ".glassEffect(.regular.tint(OG.surface2).interactive(), in: .circle)",
            button,
        )
        self.assertIn(".background(background, in: Circle())", button)
        self.assertIn(".foregroundStyle(foreground)", button)
        self.assertIn(".frame(width: 44, height: 44)", button)
        # En mapa y Métricas se comparte el mismo componente.
        self.assertEqual(LIVE.count('"flag.checkered", label: "Finalizar y guardar"'), 2)
        self.assertEqual(LIVE.count("background: .black, foreground: .white"), 2)

    def test_three_seconds_countdown_reuses_timer_sound_before_gps_starts(self):
        feedback = (ROOT / "Apps/Repera/Sources/RestFeedback.swift").read_text(encoding="utf-8")
        timer = (ROOT / "Apps/Repera/Sources/StandaloneTimerView.swift").read_text(encoding="utf-8")
        self.assertIn("RestFeedback.tick(remaining: remaining, sound: true, haptic: true)", timer)
        self.assertIn("RestFeedback.restComplete(sound: true, haptic: true)", timer)
        self.assertIn("RestFeedback.tick(remaining: preCountdown, sound: true, haptic: true)", timer)
        self.assertIn("import AVFoundation", feedback)
        self.assertIn("AVAudioPlayer(data: data)", feedback)
        self.assertIn("private static let shortTone = makeTone(duration: 0.16)", feedback)
        self.assertIn("private static let completedTone = makeTone(duration: 0.49)", feedback)
        self.assertIn("if sound { playTone(shortTone, duration: 0.16) }", feedback)
        self.assertIn("if sound { playTone(completedTone, duration: 0.49) }", feedback)
        self.assertIn("sin(2 * Double.pi * 523.25 * seconds)", feedback)
        self.assertIn("sin(2 * Double.pi * 1046.5 * seconds)", feedback)
        # 0,49 s es el punto medio entre el pitido breve de 0,16 s
        # y el aviso largo anterior de 0,82 s.
        self.assertAlmostEqual((0.16 + 0.82) / 2, 0.49)
        self.assertNotIn("makeTone(duration: 0.82)", feedback)
        self.assertNotIn("392 * seconds", feedback)
        self.assertNotIn("AudioServicesPlaySystemSound", feedback)
        self.assertIn("session.mode != .spokenAudio", feedback)
        countdown = LIVE.split("func beginStartCountdown() {", 1)[1].split(
            "func cancelStartCountdown()", 1
        )[0]
        self.assertIn("startCountdownRemaining = 3", countdown)
        self.assertIn("for second in [2, 1, 0]", countdown)
        self.assertIn("try? await Task.sleep(for: .seconds(1))", countdown)
        self.assertIn("RestFeedback.tick(remaining: 3, sound: spokenGuidanceEnabled", countdown)
        self.assertIn("sound: self.spokenGuidanceEnabled", countdown)
        self.assertIn("RestFeedback.restComplete(sound: self.spokenGuidanceEnabled", countdown)
        self.assertIn("self.start()", countdown)
        self.assertIn("guard phase == .idle, !isStartCountingDown else", LIVE)
        self.assertIn("recorder.beginStartCountdown()", LIVE)
        self.assertIn("recorder.cancelStartCountdown()", LIVE)
        self.assertIn("recorder.startCountdownRemaining", LIVE)
        self.assertIn("if previous == .idle && next == .recording", LIVE)

    def test_audio_player_and_session_do_not_block_main_actor(self):
        feedback = (ROOT / "Apps/Repera/Sources/RestFeedback.swift").read_text(encoding="utf-8")
        main, audio = feedback.split("private final class RestToneAudioEngine:", 1)

        # AVAudioPlayer.prepareToPlay y stop también pueden activar hardware.
        # Todas las operaciones sobre el reproductor, no solo setActive, van a la cola.
        self.assertIn("@MainActor\nenum RestFeedback", main)
        self.assertIn("audioEngine.play(data: data, duration: duration)", main)
        for name in ("AVAudioPlayer(data:", "prepareToPlay()", "player.play()",
                     "tonePlayer?.stop()", "setActive(", "setCategory("):
            # Los comentarios pueden explicar las llamadas; buscar solo código.
            lines = [line.strip() for line in main.splitlines()
                     if line.strip() and not line.strip().startswith(("///", "//"))]
            self.assertFalse(any(name in line for line in lines), name)

        self.assertIn("private let queue = DispatchQueue(", audio)
        self.assertIn('label: "com.app.repera.rest-feedback.audio-session"', audio)
        self.assertIn("queue.async { [self] in", audio)
        self.assertIn("let player = try AVAudioPlayer(data: data)", audio)
        self.assertIn("guard player.prepareToPlay(), player.play() else", audio)
        self.assertIn("tonePlayer?.stop()", audio)
        self.assertIn("queue.asyncAfter(deadline:", audio)
        self.assertIn("guard isCurrent(id) else { return }", audio)
        self.assertIn("identityLock.lock()", audio)
        self.assertIn("identityLock.unlock()", audio)
        self.assertIn("try session.setCategory(", audio)
        self.assertIn("try session.setActive(true)", audio)
        self.assertIn("try? session.setActive(false, options: .notifyOthersOnDeactivation)", audio)
        self.assertIn("session.mode != .spokenAudio", audio)
        # Si mañana alguien mueve prepareToPlay a MainActor, este test falla.
        self.assertLess(audio.index("queue.async { [self] in"), audio.index("player.prepareToPlay()"))

    def test_favorites_swipe_edit_uses_existing_template(self):
        favorites = (ROOT / "Apps/Repera/Sources/FavoritesHubView.swift").read_text(encoding="utf-8")
        self.assertIn(".swipeActions(edge: .leading, allowsFullSwipe: false)", favorites)
        self.assertIn('Image(systemName: "pencil.circle.fill")', favorites)
        self.assertIn(".tint(OG.blue)", favorites)
        self.assertIn("editing = routine", favorites)
        self.assertIn("mode: .favorite(isNew: isCreating)", favorites)
        self.assertIn(".swipeActions(edge: .trailing, allowsFullSwipe: false)", favorites)
        self.assertIn("store.removeFavorite(routine.id)", favorites)
        plan = (ROOT / "Apps/Repera/Sources/PlanView.swift").read_text(encoding="utf-8")
        self.assertIn("case .favorite:", plan)
        self.assertIn("guard store.saveRoutine(draft) else", plan)

    def test_finish_uses_single_completion_sound_and_no_speech(self):
        finish = LIVE.split("func finish() {", 1)[1].split(
            "func makeSession(", 1
        )[0]
        self.assertIn("RestFeedback.restComplete(sound: spokenGuidanceEnabled, haptic: true)", finish)
        self.assertNotIn("speakNavigation(", finish)
        self.assertIn("stopGuidanceAudio()", finish)

    def test_weather_row_uses_tall_icons_left_of_title_and_value(self):
        cardio = (ROOT / "Apps/Repera/Sources/CardioRouteComponents.swift").read_text(encoding="utf-8")
        stat = cardio.split("private func weatherStat(", 1)[1].split(
            "private func loadWeather()", 1
        )[0]
        self.assertIn("HStack(alignment: .center, spacing: 9)", stat)
        self.assertIn("Image(systemName: symbol)", stat)
        self.assertIn(".frame(width: 30, height: 44)", stat)
        self.assertIn("VStack(alignment: .leading, spacing: 3)", stat)
        self.assertIn("Text(title)", stat)
        self.assertIn("Text(value ??", stat)
        self.assertNotIn('Link("Apple Weather"', stat)
        self.assertIn("AsyncImage(url: mark)", cardio)
        self.assertIn("Fuentes y atribución legal", cardio)
        self.assertIn("guard let attribution = try? await WeatherService.shared.attribution else", cardio)
        self.assertIn("attribution.legalPageURL", cardio)
        self.assertIn("attribution.combinedMarkLightURL", cardio)
        self.assertIn("attribution.combinedMarkDarkURL", cardio)

    def test_route_preview_gives_top_curve_breathing_room(self):
        history = (ROOT / "Apps/Repera/Sources/HistoryView.swift").read_text(encoding="utf-8")
        route = history.split("struct HealthWorkoutRouteMap: View", 1)[1]
        camera = route.split("private var cameraPosition: MapCameraPosition", 1)[1].split(
            "private var modes:", 1
        )[0]
        self.assertIn("let preview = !isInteractive", camera)
        self.assertIn("latitudeRange * 0.05", camera)
        self.assertIn("preview ? 2.15 : 1.65", camera)
        self.assertIn("preview ? 1.85 : 1.65", camera)
        self.assertIn("MKCoordinateRegion(", camera)

    def test_native_background_modes_are_present_in_source_and_xcodegen(self):
        info = plistlib.loads((ROOT / "Apps/Repera/Resources/Info.plist").read_bytes())
        self.assertIn("location", info["UIBackgroundModes"])
        self.assertNotIn("audio", info["UIBackgroundModes"])
        project = (ROOT / "project.yml").read_text(encoding="utf-8")
        self.assertIn("UIBackgroundModes:", project)
        self.assertIn("          - location", project)
        self.assertNotIn("          - audio", project)
        self.assertIn("CLBackgroundActivitySession()", (
            ROOT / "Apps/Repera/Sources/Location/WorkoutLocationTracker.swift"
        ).read_text(encoding="utf-8"))

    def test_speech_failure_fallback_is_not_a_duplicate_notification(self):
        self.assertIn("if spokenGuidanceEnabled && !didSpeak", LIVE)
        self.assertIn("fallbackWhenSpeechFailed: true", LIVE)
        self.assertIn("(!spokenGuidanceEnabled || fallbackWhenSpeechFailed)", LIVE)


if __name__ == "__main__":
    unittest.main()
