import Foundation

// MARK: - Domain Models
// These are pure Swift models used by the business logic and UI.
// Notice: No "import UIKit" and no "Decodable" here. This keeps the Domain pure.

/// Represents a single video or movie item.
public struct MediaItem: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let thumbnailURL: URL?
    public let bannerURL: URL?
    public let videoURL: URL

    public init(
        id: String,
        title: String,
        description: String,
        thumbnailURL: URL?,
        bannerURL: URL?,
        videoURL: URL
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.bannerURL = bannerURL
        self.videoURL = videoURL
    }
}

/// Represents a horizontal rail/category of content (e.g. "Trending Now").
public struct ContentSection: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let items: [MediaItem]

    public init(id: String, title: String, items: [MediaItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

/// Represents the complete data required to display the Home Screen.
public struct HomeContent: Equatable {
    public let heroItem: MediaItem
    public let sections: [ContentSection]

    public init(heroItem: MediaItem, sections: [ContentSection]) {
        self.heroItem = heroItem
        self.sections = sections
    }
}
