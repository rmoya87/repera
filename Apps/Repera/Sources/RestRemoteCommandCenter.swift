import Foundation
import MediaPlayer

/// Now Playing / headphone remote controls for rest countdown and series UI.
/// Only pause / resume / skip the rest timer — never HealthKit, GPS or set logging.
@MainActor
enum RestRemoteCommandCenter {
    private static var enabled = false

    static func publish(active: Bool, exerciseName: String?, remaining: Int, total: Int, paused: Bool) {
        let center = MPRemoteCommandCenter.shared()
        if active, !enabled {
            center.playCommand.addTarget { _ in
                NotificationCenter.default.post(name: .reperaRestRemote, object: RestRemoteAction.resume)
                return .success
            }
            center.pauseCommand.addTarget { _ in
                NotificationCenter.default.post(name: .reperaRestRemote, object: RestRemoteAction.pause)
                return .success
            }
            center.nextTrackCommand.addTarget { _ in
                NotificationCenter.default.post(name: .reperaRestRemote, object: RestRemoteAction.skip)
                return .success
            }
            center.togglePlayPauseCommand.addTarget { _ in
                NotificationCenter.default.post(
                    name: .reperaRestRemote,
                    object: paused ? RestRemoteAction.resume : RestRemoteAction.pause
                )
                return .success
            }
            enabled = true
        }

        center.playCommand.isEnabled = active && paused
        center.pauseCommand.isEnabled = active && !paused
        center.nextTrackCommand.isEnabled = active
        center.togglePlayPauseCommand.isEnabled = active
        center.previousTrackCommand.isEnabled = false
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false

        if !active {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: exerciseName?.isEmpty == false ? "Descanso · \(exerciseName!)" : "Descanso Repera",
            MPMediaItemPropertyArtist: "Repera",
            MPMediaItemPropertyPlaybackDuration: Double(max(total, remaining)),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(max(0, total - remaining)),
            MPNowPlayingInfoPropertyPlaybackRate: paused ? 0.0 : 1.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        _ = info
    }

    static func clear() {
        publish(active: false, exerciseName: nil, remaining: 0, total: 0, paused: false)
    }
}

enum RestRemoteAction: String {
    case pause, resume, skip
}

extension Notification.Name {
    static let reperaRestRemote = Notification.Name("repera.rest.remoteCommand")
}
