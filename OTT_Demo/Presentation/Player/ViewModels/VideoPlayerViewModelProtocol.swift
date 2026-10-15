import Foundation
import Combine
import AVFoundation

// MARK: - VideoPlayerViewModelProtocol
// Contract representing the presentation logic and state for the video player.

@MainActor
protocol VideoPlayerViewModelProtocol: ObservableObject {
    var title: String { get }
    var player: AVPlayer { get }
    var isPlaying: Bool { get }
    var isBuffering: Bool { get }
    var currentTimeFormatted: String { get }
    var durationFormatted: String { get }
    var progress: Float { get }
    var isCompleted: Bool { get }
    var errorMessage: String? { get }

    var isPlayingPublisher: Published<Bool>.Publisher { get }
    var isBufferingPublisher: Published<Bool>.Publisher { get }
    var currentTimeFormattedPublisher: Published<String>.Publisher { get }
    var durationFormattedPublisher: Published<String>.Publisher { get }
    var progressPublisher: Published<Float>.Publisher { get }
    var isCompletedPublisher: Published<Bool>.Publisher { get }
    var errorMessagePublisher: Published<String?>.Publisher { get }

    func togglePlayPause()
    func play()
    func pause()
    func seek(toProgress progress: Float)
    func seekBy(seconds: Double)
    func handleAppDidEnterBackground()
    func teardown()
}
