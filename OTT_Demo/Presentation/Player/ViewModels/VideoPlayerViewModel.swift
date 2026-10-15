import Foundation
import Combine
import AVFoundation

// MARK: - VideoPlayerViewModel
// Mediates between AVPlayerEventHandler and UI.
// Implements the pipeline specified in Section 5:
// AVPlayer → Player Event Handler → ViewModel → Analytics/Event Repository

@MainActor
final class VideoPlayerViewModel: VideoPlayerViewModelProtocol {

    // MARK: - Published UI State
    @Published private(set) var isPlaying: Bool = true
    @Published private(set) var isBuffering: Bool = true
    @Published private(set) var currentTimeFormatted: String = "00:00"
    @Published private(set) var durationFormatted: String = "00:00"
    @Published private(set) var progress: Float = 0.0
    @Published private(set) var isCompleted: Bool = false
    @Published private(set) var errorMessage: String? = nil

    // Publishers for UI binding
    var isPlayingPublisher: Published<Bool>.Publisher { $isPlaying }
    var isBufferingPublisher: Published<Bool>.Publisher { $isBuffering }
    var currentTimeFormattedPublisher: Published<String>.Publisher { $currentTimeFormatted }
    var durationFormattedPublisher: Published<String>.Publisher { $durationFormatted }
    var progressPublisher: Published<Float>.Publisher { $progress }
    var isCompletedPublisher: Published<Bool>.Publisher { $isCompleted }
    var errorMessagePublisher: Published<String?>.Publisher { $errorMessage }

    // MARK: - Properties
    let title: String
    let mediaId: String
    let player: AVPlayer

    private let eventHandler: PlayerEventHandlerProtocol
    private let analyticsRepository: PlayerAnalyticsRepositoryProtocol
    private var totalDurationSeconds: Double = 0.0

    // MARK: - Init
    init(
        item: MediaItem,
        player: AVPlayer? = nil,
        eventHandler: PlayerEventHandlerProtocol = AVPlayerEventHandler(),
        analyticsRepository: PlayerAnalyticsRepositoryProtocol = ConsolePlayerAnalyticsRepository()
    ) {
        self.title = item.title
        self.mediaId = item.id
        self.analyticsRepository = analyticsRepository
        self.eventHandler = eventHandler

        let avPlayer = player ?? AVPlayer(url: item.videoURL)
        self.player = avPlayer

        self.eventHandler.delegate = self
        self.eventHandler.startObserving(player: avPlayer)

        // Automatically start playback
        avPlayer.play()
    }

    deinit {
        // Ensure cleanup when ViewModel is released
        eventHandler.teardown()
    }

    // MARK: - Playback Controls
    func togglePlayPause() {
        if player.rate > 0 {
            pause()
        } else {
            play()
        }
    }

    func play() {
        if isCompleted {
            // Replay from beginning
            player.seek(to: .zero)
            isCompleted = false
        }
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func seek(toProgress progressValue: Float) {
        guard totalDurationSeconds > 0 else { return }
        let targetSeconds = Double(progressValue) * totalDurationSeconds
        seekToTime(seconds: targetSeconds)
    }

    func seekBy(seconds offset: Double) {
        let currentSeconds = player.currentTime().seconds
        guard !currentSeconds.isNaN else { return }
        let targetSeconds = max(0, min(totalDurationSeconds, currentSeconds + offset))
        seekToTime(seconds: targetSeconds)
    }

    private func seekToTime(seconds: Double) {
        let targetCMTime = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: targetCMTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            if completed {
                self?.eventHandler.notifySeek(toSeconds: seconds)
            }
        }
    }

    func handleAppDidEnterBackground() {
        // Requirement #4: Lifecycle & Resource management
        pause()
    }

    func teardown() {
        player.pause()
        eventHandler.teardown()
    }

    // MARK: - Formatting Helpers
    private func formatTime(seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        let hours = mins / 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, mins % 60, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}

// MARK: - PlayerEventHandlerDelegate Implementation
extension VideoPlayerViewModel: PlayerEventHandlerDelegate {

    func playerEventHandler(_ handler: PlayerEventHandlerProtocol, didEmitEvent event: PlayerEvent) {
        // 1. Forward event to Analytics/Event Repository (Requirement #5)
        analyticsRepository.track(event: event, mediaTitle: title, mediaId: mediaId)

        // 2. Update UI State according to event
        switch event {
        case .playerReady:
            isBuffering = false

        case .playbackStarted:
            isPlaying = true
            isBuffering = false
            isCompleted = false

        case .playbackPaused:
            isPlaying = false

        case .bufferingStarted:
            isBuffering = true

        case .bufferingEnded:
            isBuffering = false

        case .seekPerformed(let seconds):
            currentTimeFormatted = formatTime(seconds: seconds)

        case .playbackCompleted:
            isPlaying = false
            isCompleted = true

        case .playbackError(let message):
            isBuffering = false
            isPlaying = false
            errorMessage = message
        }
    }

    func playerEventHandler(_ handler: PlayerEventHandlerProtocol, didUpdateProgress currentTime: Double, duration: Double) {
        totalDurationSeconds = duration
        currentTimeFormatted = formatTime(seconds: currentTime)
        durationFormatted = formatTime(seconds: duration)

        if duration > 0 {
            progress = Float(currentTime / duration)
        }
    }
}
