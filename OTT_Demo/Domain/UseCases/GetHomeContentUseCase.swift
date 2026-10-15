import Foundation

// MARK: - Use Case
// A Use Case encapsulates a single business action or rule.
// Here, it fetches home content via the repository contract.
// This allows easy unit testing and prevents ViewModels from depending on concrete data classes.

public protocol GetHomeContentUseCaseProtocol {
    func execute() async throws -> HomeContent
}

public final class GetHomeContentUseCase: GetHomeContentUseCaseProtocol {
    private let repository: ContentRepositoryProtocol

    public init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> HomeContent {
        return try await repository.getHomeContent()
    }
}
