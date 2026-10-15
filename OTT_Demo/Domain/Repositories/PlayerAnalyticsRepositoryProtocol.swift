import Foundation

// MARK: - PlayerAnalyticsRepositoryProtocol (Domain Contract)
// Defines how player telemetry events are recorded.
// Fulfills Dependency Inversion: The Domain specifies what it needs,
// while the Data layer implements the destination (e.g. Console, Firebase, Mixpanel).

public protocol PlayerAnalyticsRepositoryProtocol {
    func track(event: PlayerEvent, mediaTitle: String, mediaId: String)
}
