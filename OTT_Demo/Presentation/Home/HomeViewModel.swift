import Foundation
import Combine

// MARK: - HomeViewModel
// Manages the state and presentation logic for the Home screen.
// Interacts with the Domain layer via GetHomeContentUseCaseProtocol.

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var state: ViewState<HomeContent> = .idle

    // MARK: - Dependencies
    private let getHomeContentUseCase: GetHomeContentUseCaseProtocol

    // MARK: - Cached Data
    private var homeContent: HomeContent?

    init(getHomeContentUseCase: GetHomeContentUseCaseProtocol) {
        self.getHomeContentUseCase = getHomeContentUseCase
    }

    // MARK: - Actions
    func loadContent() {
        state = .loading

        Task {
            do {
                let content = try await getHomeContentUseCase.execute()
                self.homeContent = content

                if content.sections.isEmpty && content.heroItem.title.isEmpty {
                    self.state = .empty
                } else {
                    self.state = .success(content)
                }
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Convenient Accessors for CollectionView
    var heroItem: MediaItem? {
        return homeContent?.heroItem
    }

    var numberOfSections: Int {
        // Section 0 is the Hero Banner, followed by content rails
        guard let homeContent = homeContent else { return 0 }
        return 1 + homeContent.sections.count
    }

    func numberOfItems(in section: Int) -> Int {
        if section == 0 {
            return heroItem != nil ? 1 : 0
        }
        let railIndex = section - 1
        guard let sections = homeContent?.sections, railIndex < sections.count else { return 0 }
        return sections[railIndex].items.count
    }

    func sectionTitle(for section: Int) -> String? {
        guard section > 0 else { return nil }
        let railIndex = section - 1
        guard let sections = homeContent?.sections, railIndex < sections.count else { return nil }
        return sections[railIndex].title
    }

    func item(inSection section: Int, at index: Int) -> MediaItem? {
        if section == 0 {
            return heroItem
        }
        let railIndex = section - 1
        guard let sections = homeContent?.sections, railIndex < sections.count else { return nil }
        let items = sections[railIndex].items
        guard index < items.count else { return nil }
        return items[index]
    }
}
