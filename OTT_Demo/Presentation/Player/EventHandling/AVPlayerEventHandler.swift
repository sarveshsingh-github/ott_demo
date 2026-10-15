import Foundation
import AVFoundation

// MARK: - AVPlayerEventHandler
// Implements PlayerEventHandlerProtocol by attaching observers to an AVPlayer instance.
// Listens for:
// 1. KVO on player status (.playerReady, .playbackError)
// 2. KVO on timeControlStatus (.playbackStarted, .playbackPaused, .bufferingStarted)
// 3. KVO on buffer health (.bufferingStarted / .bufferingEnded)
// 4. Notification on item completion (.playbackCompleted)
// 5. Periodic time observer for playback progress
// 6. User seek invocations (.seekPerformed)
//
// Ensures 100% clean teardown with no memory leaks or dangling KVO tokens.

final class AVPlayerEventHandler: PlayerEventHandlerProtocol {

    weak var delegate: PlayerEventHandlerDelegate?

    private weak var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemDidPlayToEndObserver: NSObjectProtocol?

    // KVO Observations
    private var statusObservation: NSKeyValueObservation?
    private var timeControlStatusObservation: NSKeyValueObservation?
    private var bufferEmptyObservation: NSKeyValueObservation?
    private var likelyToKeepUpObservation: NSKeyValueObservation?

    // State Flags to prevent duplicate event spam
    private var hasEmittedReady = false
    private var isBuffering = false

    deinit {
        teardown()
    }

    func startObserving(player: AVPlayer) {
        // Teardown any prior player observers
        teardown()

        self.player = player
        self.hasEmittedReady = false
        self.isBuffering = false

        observePlayerStatus(player: player)
        observeTimeControlStatus(player: player)
        observeCurrentItem(player: player)
        observePeriodicTime(player: player)
        observeCompletionNotification(player: player)
    }

    // MARK: - KVO Observers
    private func observePlayerStatus(player: AVPlayer) {
        guard let currentItem = player.currentItem else { return }

        statusObservation = currentItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    if !self.hasEmittedReady {
                        self.hasEmittedReady = true
                        self.delegate?.playerEventHandler(self, didEmitEvent: .playerReady)
                    }
                case .failed:
                    let errorMessage = item.error?.localizedDescription ?? "Unknown AVPlayer playback error"
                    self.delegate?.playerEventHandler(self, didEmitEvent: .playbackError(message: errorMessage))
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func observeTimeControlStatus(player: AVPlayer) {
        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] player, change in
            guard let self = self, change.oldValue != change.newValue else { return }

            DispatchQueue.main.async {
                switch player.timeControlStatus {
                case .playing:
                    if self.isBuffering {
                        self.isBuffering = false
                        self.delegate?.playerEventHandler(self, didEmitEvent: .bufferingEnded)
                    }
                    self.delegate?.playerEventHandler(self, didEmitEvent: .playbackStarted)

                case .paused:
                    // Avoid emitting pause if video completed
                    if let currentItem = player.currentItem,
                       currentItem.currentTime() >= currentItem.duration {
                        return
                    }
                    self.delegate?.playerEventHandler(self, didEmitEvent: .playbackPaused)

                case .waitingToPlayAtSpecifiedRate:
                    if !self.isBuffering {
                        self.isBuffering = true
                        self.delegate?.playerEventHandler(self, didEmitEvent: .bufferingStarted)
                    }

                @unknown default:
                    break
                }
            }
        }
    }

    private func observeCurrentItem(player: AVPlayer) {
        guard let currentItem = player.currentItem else { return }

        bufferEmptyObservation = currentItem.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if item.isPlaybackBufferEmpty && !self.isBuffering {
                    self.isBuffering = true
                    self.delegate?.playerEventHandler(self, didEmitEvent: .bufferingStarted)
                }
            }
        }

        likelyToKeepUpObservation = currentItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if item.isPlaybackLikelyToKeepUp && self.isBuffering {
                    self.isBuffering = false
                    self.delegate?.playerEventHandler(self, didEmitEvent: .bufferingEnded)
                }
            }
        }
    }

    private func observePeriodicTime(player: AVPlayer) {
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let currentItem = self.player?.currentItem else { return }

            let currentTime = time.seconds
            let duration = currentItem.duration.seconds

            if !duration.isNaN && duration > 0 {
                self.delegate?.playerEventHandler(self, didUpdateProgress: currentTime, duration: duration)
            }
        }
    }

    private func observeCompletionNotification(player: AVPlayer) {
        itemDidPlayToEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.playerEventHandler(self, didEmitEvent: .playbackCompleted)
        }
    }

    // MARK: - Explicit Actions
    func notifySeek(toSeconds seconds: Double) {
        delegate?.playerEventHandler(self, didEmitEvent: .seekPerformed(toSeconds: seconds))
    }

    // MARK: - Teardown / Resource Management
    func teardown() {
        if let token = timeObserverToken, let player = player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }

        if let observer = itemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
            itemDidPlayToEndObserver = nil
        }

        statusObservation?.invalidate()
        statusObservation = nil

        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = nil

        bufferEmptyObservation?.invalidate()
        bufferEmptyObservation = nil

        likelyToKeepUpObservation?.invalidate()
        likelyToKeepUpObservation = nil

        player = nil
    }
}
