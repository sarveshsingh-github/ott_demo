import Foundation

// MARK: - Remote Data Source Protocol
// This protocol defines how raw data is retrieved.
// We can easily swap between MockContentRemoteDataSource and URLSessionContentRemoteDataSource
// without changing the Repository or anything above it.

protocol ContentRemoteDataSourceProtocol {
    func fetchHomeData() async throws -> HomeResponseDTO
}

// MARK: - Custom Data Errors
enum DataError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "Mock data file '\(fileName)' was not found in the application bundle."
        case .decodingFailed(let underlyingError):
            return "Failed to decode mock JSON: \(underlyingError.localizedDescription)"
        }
    }
}
