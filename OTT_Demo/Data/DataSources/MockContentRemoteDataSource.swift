import Foundation

// MARK: - Mock Remote Data Source
// Simulates an API call by reading bundled JSON file and decoding it.
// Uses Swift Concurrency (async/await) and simulates network latency.

final class MockContentRemoteDataSource: ContentRemoteDataSourceProtocol {
    private let bundle: Bundle
    private let fileName: String
    private let simulatedDelayNanoseconds: UInt64

    init(
        bundle: Bundle = .main,
        fileName: String = "home_response",
        simulatedDelaySeconds: Double = 0.5
    ) {
        self.bundle = bundle
        self.fileName = fileName
        self.simulatedDelayNanoseconds = UInt64(simulatedDelaySeconds * 1_000_000_000)
    }

    func fetchHomeData() async throws -> HomeResponseDTO {
        // 1. Simulate network latency so loading indicators can be tested
        if simulatedDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        }

        // 2. Locate the file in the bundle (with fallback for unit test environments)
        var targetURL = bundle.url(forResource: fileName, withExtension: "json")
        if targetURL == nil {
            targetURL = Bundle(for: MockContentRemoteDataSource.self).url(forResource: fileName, withExtension: "json")
        }
        
        guard let url = targetURL else {
            throw DataError.fileNotFound("\(fileName).json")
        }

        // 3. Read data from file
        let data = try Data(contentsOf: url)

        // 4. Decode JSON into DTO
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(HomeResponseDTO.self, from: data)
        } catch {
            throw DataError.decodingFailed(error)
        }
    }
}
