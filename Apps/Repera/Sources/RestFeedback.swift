import AVFoundation
import Foundation
import UIKit

/// Única familia de tonos para Comenzar, Temporizador y descansos.
/// Los tres pitidos y el aviso largo comparten frecuencia y timbre.
@MainActor
enum RestFeedback {
    /// El hilo principal solo genera hápticos y encola peticiones de sonido.
    /// AVAudioPlayer.prepareToPlay() también puede activar el hardware y bloquear.
    private static let audioEngine = RestToneAudioEngine()

    // Tono medio (Do5), menos grave que el anterior Sol4 (392 Hz).
    // Los avisos usan la misma nota: solo cambia la duración.
    private static let shortTone = makeTone(duration: 0.16)
    private static let completedTone = makeTone(duration: 0.49)

    static func tick(remaining: Int, sound: Bool, haptic: Bool) {
        guard remaining > 0, remaining <= 3 else { return }
        if haptic {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if sound { playTone(shortTone, duration: 0.16) }
    }

    static func restComplete(sound: Bool, haptic: Bool) {
        if haptic {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if sound { playTone(completedTone, duration: 0.49) }
    }

    static func intervalBeep(sound: Bool, haptic: Bool) {
        if haptic {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        if sound { playTone(shortTone, duration: 0.16) }
    }

    private static func playTone(_ data: Data, duration: TimeInterval) {
        audioEngine.play(data: data, duration: duration)
    }

    /// WAV PCM mono generado localmente, sin recursos remotos ni sonidos
    /// del sistema que varíen entre versiones de iOS o dispositivos.
    private static func makeTone(duration: TimeInterval) -> Data {
        let sampleRate = 22_050
        let samples = Int(Double(sampleRate) * duration)
        let audioLength = UInt32(samples * 2)
        var data = Data(capacity: 44 + Int(audioLength))

        func appendLE<T: FixedWidthInteger>(_ value: T) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }

        data.append(contentsOf: "RIFF".utf8)
        appendLE(UInt32(36) + audioLength)
        data.append(contentsOf: "WAVEfmt ".utf8)
        appendLE(UInt32(16))
        appendLE(UInt16(1))
        appendLE(UInt16(1))
        appendLE(UInt32(sampleRate))
        appendLE(UInt32(sampleRate * 2))
        appendLE(UInt16(2))
        appendLE(UInt16(16))
        data.append(contentsOf: "data".utf8)
        appendLE(audioLength)

        for index in 0..<samples {
            let seconds = Double(index) / Double(sampleRate)
            let attack = min(1, seconds / 0.012)
            let release = min(1, (duration - seconds) / 0.075)
            let envelope = max(0, min(attack, release))
            let base = sin(2 * Double.pi * 523.25 * seconds)
            let overtone = 0.16 * sin(2 * Double.pi * 1046.5 * seconds)
            let value = Int16((max(-1, min(1, (base + overtone) * envelope * 0.55)) * 32767).rounded())
            appendLE(UInt16(bitPattern: value))
        }
        return data
    }
}


/// AVAudioSession y AVAudioPlayer se usan solo desde la misma cola serial.
/// No hacer `prepareToPlay`, `play`, `stop` ni destruir el player en MainActor:
/// `prepareToPlay` puede activar el hardware de forma síncrona.
private final class RestToneAudioEngine: @unchecked Sendable {
    private let queue = DispatchQueue(
        label: "com.app.repera.rest-feedback.audio-session",
        qos: .userInitiated
    )
    /// El ID se consulta al entrar/salir de operaciones que pueden tardar
    /// (Bluetooth, cambio de ruta). Nunca se bloquea el main thread con AVAudio.
    private let identityLock = NSLock()
    private var currentToneID = UUID()
    /// Propiedad confinada a `queue`; justifica @unchecked Sendable.
    private var tonePlayer: AVAudioPlayer?

    func play(data: Data, duration: TimeInterval) {
        let id = UUID()
        identityLock.lock()
        currentToneID = id
        identityLock.unlock()

        queue.async { [self] in
            guard isCurrent(id) else { return }
            tonePlayer?.stop()
            tonePlayer = nil

            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                try session.setActive(true)
                guard isCurrent(id) else { return }

                let player = try AVAudioPlayer(data: data)
                player.volume = 0.75
                // Este método también activa la sesión internamente: solo cola.
                guard player.prepareToPlay(), player.play() else {
                    deactivateWhenIdle(session, id: id)
                    return
                }
                tonePlayer = player
            } catch {
                NSLog("[Repera] No se pudo reproducir el tono deportivo: %@", String(describing: error))
                deactivateWhenIdle(session, id: id)
                return
            }

            queue.asyncAfter(deadline: .now() + duration + 0.15) { [self] in
                guard isCurrent(id) else { return }
                tonePlayer = nil
                deactivateWhenIdle(AVAudioSession.sharedInstance(), id: id)
            }
        }
    }

    private func isCurrent(_ id: UUID) -> Bool {
        identityLock.lock()
        defer { identityLock.unlock() }
        return currentToneID == id
    }

    /// Solo se invoca desde `queue`. No cerrar la sesión de una locución GPS.
    private func deactivateWhenIdle(_ session: AVAudioSession, id: UUID) {
        guard isCurrent(id), session.mode != .spokenAudio else { return }
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}
