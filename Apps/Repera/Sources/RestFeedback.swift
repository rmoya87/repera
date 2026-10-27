import AVFoundation
import Foundation
import UIKit

/// Única familia de tonos para Comenzar, Temporizador y descansos.
/// Los tres pitidos y el aviso largo comparten frecuencia y timbre.
@MainActor
enum RestFeedback {
    private static var tonePlayer: AVAudioPlayer?
    private static var releaseAudioTask: Task<Void, Never>?
    private static var currentToneID = UUID()
    /// Serializa cambios de AVAudioSession FUERA de MainActor: nunca bloquear
    /// animaciones, scroll o controles de Comenzar con setActive/setCategory.
    private static let audioSessionQueue = DispatchQueue(
        label: "com.app.repera.rest-feedback.audio-session",
        qos: .userInitiated
    )

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
        releaseAudioTask?.cancel()
        releaseAudioTask = nil
        tonePlayer?.stop()
        tonePlayer = nil
        let id = UUID()
        currentToneID = id

        // setCategory/setActive pueden esperar a la ruta de audio física
        // (Bluetooth, AirPods, interrupciones). No ejecutarlos en MainActor.
        // La cola evita que varios pitidos activen/desactiven en paralelo.
        audioSessionQueue.async {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                try session.setActive(true)
            } catch {
                let message = String(describing: error)
                Task { @MainActor in
                    guard currentToneID == id else { return }
                    NSLog("[Repera] No se pudo activar el audio deportivo: %@", message)
                }
                return
            }
            Task { @MainActor in
                // Un pitido posterior sustituye al anterior incluso si la
                // activación asíncrona del primero termina más tarde.
                guard currentToneID == id else { return }
                do {
                    let player = try AVAudioPlayer(data: data)
                    player.volume = 0.75
                    player.prepareToPlay()
                    tonePlayer = player
                    guard player.play() else {
                        tonePlayer = nil
                        deactivateAudioWhenIdle()
                        return
                    }
                } catch {
                    tonePlayer = nil
                    NSLog("[Repera] No se pudo reproducir el tono deportivo: %@", String(describing: error))
                    deactivateAudioWhenIdle()
                    return
                }
                releaseAudioTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(duration + 0.15))
                    guard !Task.isCancelled, currentToneID == id else { return }
                    tonePlayer = nil
                    releaseAudioTask = nil
                    deactivateAudioWhenIdle()
                }
            }
        }
    }

    private static func deactivateAudioWhenIdle() {
        audioSessionQueue.async {
            let session = AVAudioSession.sharedInstance()
            // Una locución GPS puede empezar mientras termina el tono.
            // No desactivar su sesión al terminar el pitido.
            if session.mode != .spokenAudio {
                try? session.setActive(false, options: .notifyOthersOnDeactivation)
            }
        }
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
