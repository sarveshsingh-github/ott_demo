import Foundation

// MARK: - Mapper
// The Mapper transforms raw Data Transfer Objects (DTOs) into clean Domain Models.
// Why: If backend API keys or structures change, only the DTO and Mapper change.
// The Domain layer and UI remain completely unaffected.

enum MediaMapper {
    static func toDomain(dto: HomeResponseDTO) -> HomeContent {
        let hero = toDomain(dto: dto.hero)
        let sections = dto.rails.map { rail in
            ContentSection(
                id: rail.id,
                title: rail.title,
                items: rail.items.map { toDomain(dto: $0) }
            )
        }
        return HomeContent(heroItem: hero, sections: sections)
    }

    static func toDomain(dto: MediaItemDTO) -> MediaItem {
        return MediaItem(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            thumbnailURL: URL(string: dto.thumbnailUrl),
            bannerURL: URL(string: dto.bannerUrl),
            videoURL: URL(string: dto.videoUrl) ?? URL(string: "https://example.com")!
        )
    }
}
