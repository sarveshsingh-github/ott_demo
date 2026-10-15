import Foundation

// MARK: - Data Transfer Objects (DTOs)
// DTOs represent the raw JSON data received from the network or mock file.
// They conform to Decodable and map JSON fields to Swift types.

struct HomeResponseDTO: Decodable {
    let hero: MediaItemDTO
    let rails: [RailDTO]
}

struct RailDTO: Decodable {
    let id: String
    let title: String
    let items: [MediaItemDTO]
}

struct MediaItemDTO: Decodable {
    let id: String
    let title: String
    let description: String
    let thumbnailUrl: String
    let bannerUrl: String
    let videoUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case thumbnailUrl = "thumbnail_url"
        case bannerUrl = "banner_url"
        case videoUrl = "video_url"
    }
}
