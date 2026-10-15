import Foundation
import os.log

// MARK: - ConsolePlayerAnalyticsRepository (Data Layer)
// Implements PlayerAnalyticsRepositoryProtocol by printing formatted telemetry
// as specified in Section 5 of the technical assignment.
// Can easily be substituted with a Firebase, Segment, or Conviva analytics repository.

final class ConsolePlayerAnalyticsRepository: PlayerAnalyticsRepositoryProtocol {
    private let logger = Logger(subsystem: "com.dataStorage.OTT-Demo", category: "PlayerAnalytics")

    func track(event: PlayerEvent, mediaTitle: String, mediaId: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] [ANALYTICS] \(event.eventName) | Title: \"\(mediaTitle)\" (ID: \(mediaId))"

        // Also print to standard stdout for immediate terminal visibility
        print(logMessage)
        logger.info("\(logMessage, privacy: .public)")
    }
}
