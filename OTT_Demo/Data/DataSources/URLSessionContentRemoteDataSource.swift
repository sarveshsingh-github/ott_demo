import Foundation

// MARK: - Production URLSession Remote Data Source (API-Ready Design)
// Demonstrates Requirement #8:
// Swapping from MockContentRemoteDataSource to this real API implementation
// requires ZERO changes to Domain Models, Repositories, Use Cases, or UI.

final class URLSessionContentRemoteDataSource: ContentRemoteDataSourceProtocol {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = URL(string: "https://api.example.com/v1")!) {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchHomeData() async throws -> HomeResponseDTO {
        let endpointURL = baseURL.appendingPathComponent("home")
        let (data, response) = try await session.data(from: endpointURL)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(HomeResponseDTO.self, from: data)
    }
}
