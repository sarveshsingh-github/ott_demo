import Testing
import Foundation
import Combine
import AVFoundation
@testable import OTT_Demo

// MARK: - Mock Analytics Repository for Unit Testing
final class MockPlayerAnalyticsRepository: PlayerAnalyticsRepositoryProtocol {
    private(set) var trackedEvents: [PlayerEvent] = []

    func track(event: PlayerEvent, mediaTitle: String, mediaId: String) {
        trackedEvents.append(event)
    }
}

// MARK: - Mock Player Event Handler for Unit Testing
final class MockPlayerEventHandler: PlayerEventHandlerProtocol {
    weak var delegate: PlayerEventHandlerDelegate?
    private(set) var didTeardown = false

    func startObserving(player: AVPlayer) {}

    func notifySeek(toSeconds seconds: Double) {
        delegate?.playerEventHandler(self, didEmitEvent: .seekPerformed(toSeconds: seconds))
    }

    func teardown() {
        didTeardown = true
    }

    // Test Helper
    func simulate(event: PlayerEvent) {
        delegate?.playerEventHandler(self, didEmitEvent: event)
    }

    func simulateProgress(currentTime: Double, duration: Double) {
        delegate?.playerEventHandler(self, didUpdateProgress: currentTime, duration: duration)
    }
}

// MARK: - Test Suite
struct OTT_DemoTests {

    @Test func testMockDataSourceLoadsAndDecodesSuccessfully() async throws {
        // Given
        let dataSource = MockContentRemoteDataSource(simulatedDelaySeconds: 0)

        // When
        let dto = try await dataSource.fetchHomeData()

        // Then
        #expect(dto.hero.title == "Big Buck Bunny")
        #expect(dto.rails.count >= 2)
    }

    @Test func testRepositoryAndUseCaseReturnDomainContent() async throws {
        // Given
        let dataSource = MockContentRemoteDataSource(simulatedDelaySeconds: 0)
        let repository = ContentRepository(remoteDataSource: dataSource)
        let useCase = GetHomeContentUseCase(repository: repository)

        // When
        let homeContent = try await useCase.execute()

        // Then
        #expect(homeContent.heroItem.id == "hero_001")
        #expect(homeContent.heroItem.title == "Big Buck Bunny")
        #expect(homeContent.sections.count >= 2)
        #expect(homeContent.sections[0].title == "Trending Now")
        #expect(homeContent.sections[0].items.count > 0)
    }

    @Test @MainActor func testPlayerEventPipelinePropagatesToAnalyticsRepository() {
        // Given
        let item = MediaItem(
            id: "test_1",
            title: "Test Video",
            description: "Test Desc",
            thumbnailURL: nil,
            bannerURL: nil,
            videoURL: URL(string: "https://example.com/video.mp4")!
        )
        let mockEventHandler = MockPlayerEventHandler()
        let mockAnalytics = MockPlayerAnalyticsRepository()
        let viewModel = VideoPlayerViewModel(
            item: item,
            player: AVPlayer(),
            eventHandler: mockEventHandler,
            analyticsRepository: mockAnalytics
        )

        // When simulating playback events
        mockEventHandler.simulate(event: .playerReady)
        mockEventHandler.simulate(event: .playbackStarted)
        mockEventHandler.simulate(event: .bufferingStarted)
        mockEventHandler.simulate(event: .bufferingEnded)
        mockEventHandler.simulate(event: .seekPerformed(toSeconds: 45.0))
        mockEventHandler.simulate(event: .playbackPaused)
        mockEventHandler.simulate(event: .playbackCompleted)

        // Then: Verify all 7 events flowed through AVPlayer -> EventHandler -> ViewModel -> AnalyticsRepository
        #expect(mockAnalytics.trackedEvents.count == 7)
        #expect(mockAnalytics.trackedEvents[0] == .playerReady)
        #expect(mockAnalytics.trackedEvents[1] == .playbackStarted)
        #expect(mockAnalytics.trackedEvents[2] == .bufferingStarted)
        #expect(mockAnalytics.trackedEvents[3] == .bufferingEnded)
        #expect(mockAnalytics.trackedEvents[4] == .seekPerformed(toSeconds: 45.0))
        #expect(mockAnalytics.trackedEvents[5] == .playbackPaused)
        #expect(mockAnalytics.trackedEvents[6] == .playbackCompleted)
        #expect(viewModel.isCompleted == true)
        #expect(viewModel.isPlaying == false)
    }

    @Test @MainActor func testPlayerProgressUpdatesViewModelState() {
        // Given
        let item = MediaItem(
            id: "test_2",
            title: "Progress Video",
            description: "Test Desc",
            thumbnailURL: nil,
            bannerURL: nil,
            videoURL: URL(string: "https://example.com/video.mp4")!
        )
        let mockEventHandler = MockPlayerEventHandler()
        let viewModel = VideoPlayerViewModel(
            item: item,
            player: AVPlayer(),
            eventHandler: mockEventHandler
        )

        // When simulating progress: 65 seconds into a 130 second video
        mockEventHandler.simulateProgress(currentTime: 65.0, duration: 130.0)

        // Then
        #expect(viewModel.currentTimeFormatted == "01:05")
        #expect(viewModel.durationFormatted == "02:10")
        #expect(abs(viewModel.progress - 0.5) < 0.01)
    }

    @Test func testContentDetailViewModelFormatsDataAccurately() {
        // Given
        let url = URL(string: "https://example.com/thumb.jpg")
        let item = MediaItem(
            id: "detail_1",
            title: "Detail Movie",
            description: "Detail Desc",
            thumbnailURL: url,
            bannerURL: nil,
            videoURL: URL(string: "https://example.com/video.mp4")!
        )
        let viewModel = ContentDetailViewModel(item: item)

        // Then
        #expect(viewModel.title == "Detail Movie")
        #expect(viewModel.description == "Detail Desc")
        #expect(viewModel.imageURL == url)
    }
}
