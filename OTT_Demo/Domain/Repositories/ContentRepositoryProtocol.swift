import Foundation

// MARK: - Repository Protocol (Domain Contract)
// In Clean Architecture (Dependency Inversion), the Domain defines the interface (Protocol)
// that it requires, while the Data layer will be responsible for implementing it.

public protocol ContentRepositoryProtocol {
    /// Fetches all content needed for the Home Screen.
    func getHomeContent() async throws -> HomeContent
}
