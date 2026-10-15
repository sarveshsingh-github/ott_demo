import Foundation

// MARK: - Repository Implementation
// Fulfills the ContentRepositoryProtocol defined in the Domain layer.
// Notice: It depends on the abstraction (ContentRemoteDataSourceProtocol), NOT a concrete class.

final class ContentRepository: ContentRepositoryProtocol {
    private let remoteDataSource: ContentRemoteDataSourceProtocol

    init(remoteDataSource: ContentRemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    func getHomeContent() async throws -> HomeContent {
        let dto = try await remoteDataSource.fetchHomeData()
        return MediaMapper.toDomain(dto: dto)
    }
}
