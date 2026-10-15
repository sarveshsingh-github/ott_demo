import Foundation

// MARK: - ContentDetailViewModelProtocol
// Defines the contract for the Detail screen presentation logic.
// Keeping this protocol in place adheres to Dependency Inversion (DIP)
// and allows simple mocking for unit tests.

protocol ContentDetailViewModelProtocol {
    var title: String { get }
    var description: String { get }
    var imageURL: URL? { get }
    var videoURL: URL { get }
    var item: MediaItem { get }
}

// MARK: - ContentDetailViewModel
// Prepares and formats domain data for ContentDetailViewController.
// Notice: Pure Swift, zero UIKit dependencies.

final class ContentDetailViewModel: ContentDetailViewModelProtocol {
    let item: MediaItem

    init(item: MediaItem) {
        self.item = item
    }

    var title: String {
        return item.title
    }

    var description: String {
        return item.description
    }

    var imageURL: URL? {
        return item.bannerURL ?? item.thumbnailURL
    }

    var videoURL: URL {
        return item.videoURL
    }
}
