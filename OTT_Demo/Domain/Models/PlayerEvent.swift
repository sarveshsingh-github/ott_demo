import Foundation

// MARK: - PlayerEvent (Domain Model)
// Represents distinct playback lifecycle and telemetry events.
// These are pure domain representations, completely decoupled from AVFoundation.

public enum PlayerEvent: Equatable {
    case playerReady
    case playbackStarted
    case playbackPaused
    case seekPerformed(toSeconds: Double)
    case bufferingStarted
    case bufferingEnded
    case playbackCompleted
    case playbackError(message: String)

    /// Standard string representation for logging and analytics.
    public var eventName: String {
        switch self {
        case .playerReady:
            return "PLAYER_READY"
        case .playbackStarted:
            return "PLAYER_STARTED"
        case .playbackPaused:
            return "PLAYER_PAUSED"
        case .seekPerformed(let time):
            return "PLAYER_SEEKED (to: \(String(format: "%.1f", time))s)"
        case .bufferingStarted:
            return "BUFFERING_STARTED"
        case .bufferingEnded:
            return "BUFFERING_ENDED"
        case .playbackCompleted:
            return "PLAYER_COMPLETED"
        case .playbackError(let message):
            return "PLAYER_ERROR (\(message))"
        }
    }
}
