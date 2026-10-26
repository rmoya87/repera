import AVFoundation
import MediaPlayer
import SwiftUI

/// Información de reproducción disponible a Repera sin APIs privadas.
/// MediaPlayer expone la sesión de Música, NO el Now Playing global de Spotify.
@MainActor
private struct ReperaNowPlayingSnapshot {
    var title: String?
    var artist: String?
    var artwork: UIImage?
    var appleMusicAvailable = false
    var appleMusicPlaying = false
    var externalAudioPlaying = false
    var musicPermissionNeeded = false

    var isVisible: Bool {
        appleMusicAvailable || externalAudioPlaying || musicPermissionNeeded
    }

    static func capture() -> Self {
        let player = MPMusicPlayerController.systemMusicPlayer
        let state = player.playbackState
        let musicIsActive = state == .playing || state == .paused
        let permission = MPMediaLibrary.authorizationStatus()
        let otherAudio = AVAudioSession.sharedInstance().isOtherAudioPlaying
        // Si Spotify empieza a sonar mientras Música queda pausada,
        // no mostrar por error la canción anterior de Apple Music.
        let item = permission == .authorized && (state == .playing || !otherAudio)
            ? player.nowPlayingItem : nil
        return Self(
            title: item?.title,
            artist: item?.artist,
            artwork: item?.artwork?.image(at: CGSize(width: 100, height: 100)),
            appleMusicAvailable: item != nil,
            appleMusicPlaying: state == .playing,
            externalAudioPlaying: otherAudio,
            musicPermissionNeeded: permission == .notDetermined && musicIsActive
        )
    }
}

/// Componente común en reloj de entreno, temporizador libre y Comenzar.
/// No toma control de la sesión de audio: GPS/temporizadores no deben pausar
/// música ni publicar en Now Playing un entrenamiento como si fuera una canción.
struct ReperaNowPlayingBar: View {
    var darkAppearance = false
    var horizontalPadding: CGFloat = 0
    var showsSeparator = false
    var cardStyle = false
    var bottomPadding: CGFloat = 0

    @Environment(\.scenePhase) private var scenePhase
    @State private var snapshot = ReperaNowPlayingSnapshot()

    private var foreground: Color { darkAppearance ? .white : OG.label }
    private var secondary: Color { darkAppearance ? .white.opacity(0.7) : OG.label2 }

    var body: some View {
        Group {
            if snapshot.isVisible {
                VStack(spacing: 8) {
                    if showsSeparator {
                        Divider()
                            .overlay(darkAppearance ? Color.white.opacity(0.2) : OG.surface3)
                    }
                    HStack(spacing: 10) {
                    Group {
                        if let artwork = snapshot.artwork {
                            Image(uiImage: artwork)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(darkAppearance ? Color.white.opacity(0.14) : OG.surface2)
                        }
                    }
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(snapshot.title ?? (snapshot.musicPermissionNeeded
                            ? "Apple Music" : "Audio en reproducción"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(foreground)
                            .lineLimit(1)

                        Text(snapshot.artist ?? (snapshot.musicPermissionNeeded
                            ? "Autoriza Música para ver la canción"
                            : "Controles en el Centro de Control"))
                            .font(.system(size: 12))
                            .foregroundStyle(secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if snapshot.appleMusicAvailable {
                        HStack(spacing: 8) {
                            transportButton("backward.end.fill", label: "Canción anterior") {
                                MPMusicPlayerController.systemMusicPlayer.skipToPreviousItem()
                                refresh()
                            }
                            transportButton(
                                snapshot.appleMusicPlaying ? "pause.fill" : "play.fill",
                                label: snapshot.appleMusicPlaying ? "Pausar música" : "Reanudar música"
                            ) {
                                let player = MPMusicPlayerController.systemMusicPlayer
                                if snapshot.appleMusicPlaying { player.pause() }
                                else { player.play() }
                                refresh()
                            }
                            transportButton("forward.end.fill", label: "Siguiente canción") {
                                MPMusicPlayerController.systemMusicPlayer.skipToNextItem()
                                refresh()
                            }
                        }
                    } else if snapshot.musicPermissionNeeded {
                        Button("Permitir") {
                            // El bucle de observación refresca la vista al
                            // volver del diálogo; no capturar SwiftUI en este callback.
                            MPMediaLibrary.requestAuthorization { _ in }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(OG.accent)
                    } else {
                        // Ninguna API pública puede cambiar la pista de Spotify
                        // sin autorización e integración del propio servicio.
                        Image(systemName: "airplayaudio")
                            .font(.system(size: 17))
                            .foregroundStyle(secondary)
                            .accessibilityLabel("Reproducción externa; usa Centro de Control")
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 5)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Reproducción de música")
                    .padding(.vertical, cardStyle ? 8 : 0)
                    .background {
                        if cardStyle {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(OG.surface)
                        }
                    }
                    .padding(.bottom, bottomPadding)
                }
            }
        }
        .task {
            while !Task.isCancelled {
                refresh()
                try? await Task.sleep(for: .seconds(2))
            }
        }
        .onChange(of: scenePhase) { _, next in
            if next == .active { refresh() }
        }
    }

    private func transportButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: 32, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func refresh() {
        snapshot = ReperaNowPlayingSnapshot.capture()
    }
}
