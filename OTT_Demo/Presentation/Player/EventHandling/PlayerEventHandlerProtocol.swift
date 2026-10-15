import Foundation
import AVFoundation

// MARK: - PlayerEventHandlerDelegate
// Communication bridge between the low-level AVPlayer observer layer and the ViewModel.

protocol PlayerEventHandlerDelegate: AnyObject {
    func playerEventHandler(_ handler: PlayerEventHandlerProtocol, didEmitEvent event: PlayerEvent)
    func playerEventHandler(_ handler: PlayerEventHandlerProtocol, didUpdateProgress currentTime: Double, duration: Double)
}

// MARK: - PlayerEventHandlerProtocol
// Abstract contract for managing player telemetry and observations.

protocol PlayerEventHandlerProtocol: AnyObject {
    var delegate: PlayerEventHandlerDelegate? { get set }
    func startObserving(player: AVPlayer)
    func notifySeek(toSeconds seconds: Double)
    func teardown()
}
