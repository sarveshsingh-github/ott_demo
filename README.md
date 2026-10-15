# OTT Demo — iOS Technical Assignment

An OTT-style iOS application built using **Swift**, **UIKit (Storyboards & XIBs)**, **Clean Architecture**, **MVVM**, and **AVFoundation (AVPlayer)**.

---

## 1. Steps to Build and Run the Application

1. **Clone the repository**:
   ```bash
   git clone <repository_url>
   cd OTT_Demo
   ```
2. **Open in Xcode**:
   - Double-click `OTT_Demo.xcodeproj` or run:
     ```bash
     open OTT_Demo.xcodeproj
     ```
3. **Select Simulator or Device**:
   - Choose any iOS 16.0+ simulator (e.g., iPhone 15, iPhone 16, iPhone 17) or a physical iOS device.
4. **Build and Run**:
   - Press `Cmd + R` or click the **Play** button in Xcode.
5. **Run Unit Tests**:
   - Press `Cmd + U` to execute the full unit test suite.

---

## 2. Minimum Supported iOS Version
* **iOS 16.0+**
* Tested on iOS 16, iOS 17, and iOS 18 / future runtimes.

---

## 3. Architecture Overview

This project is built following **Clean Architecture** and **SOLID Principles**, structured into three strictly decoupled layers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│   Home.storyboard · Detail.storyboard · Player.storyboard · Custom XIBs│
│  HomeViewController · ContentDetailVC · VideoPlayerViewController       │
│  HomeViewModel · ContentDetailViewModel · VideoPlayerViewModel         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Depends on Domain abstractions)
┌───────────────────────────────────▼────────────────────────────────────┐
│                           DOMAIN LAYER                                 │
│      MediaItem · ContentSection · HomeContent · PlayerEvent            │
│ ContentRepositoryProtocol · GetHomeContentUseCase · AnalyticsProtocol  │
│                      (Pure Swift — Zero UIKit)                         │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ (Implements Domain contracts)
┌───────────────────────────────────┴────────────────────────────────────┐
│                            DATA LAYER                                  │
│         ContentRepository · ConsolePlayerAnalyticsRepository           │
│       MockContentRemoteDataSource · URLSessionContentRemoteDataSource  │
│                  HomeResponseDTO · MediaMapper                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Key Architectural Highlights:
* **The Dependency Rule**: Inner layers (Domain) have zero knowledge of outer layers (Data, Presentation). Domain contains **no UIKit imports** and **no Decodable/JSON annotations**.
* **Composition Root**: Dependencies are composed and injected in `SceneDelegate.swift`, keeping view controllers lightweight and isolated.
* **Separation of Storyboards**: Rather than a single monolithic `Main.storyboard`, each feature has its own co-located storyboard (`Home.storyboard`, `Detail.storyboard`, `Player.storyboard`) to adhere to the Single Responsibility Principle and prevent XML merge conflicts.

---

## 4. Project & Module Structure

```
OTT_Demo/
├── Presentation/
│   ├── Common/
│   │   ├── ViewState.swift                  # Generic ViewState (.idle, .loading, .success, .empty, .error)
│   │   └── UIImageView+Load.swift           # Asynchronous image downloader with NSCache
│   ├── Home/
│   │   ├── Home.storyboard                  # Dedicated Home feature storyboard
│   │   ├── HomeViewController.swift         # CollectionView with Compositional Layout
│   │   ├── HomeViewModel.swift              # Combine @Published state management
│   │   └── Views/
│   │       ├── HeroBannerCell.xib & .swift  # Hero banner cell
│   │       ├── ContentCardCell.xib & .swift # Poster thumbnail card cell
│   │       └── SectionHeaderView.swift      # Rail title header view
│   ├── Detail/
│   │   ├── Detail.storyboard                # Dedicated Detail feature storyboard
│   │   ├── ContentDetailViewController.swift# Detail view with ScrollView & Play CTA
│   │   └── ContentDetailViewModel.swift     # Detail presentation logic
│   └── Player/
│       ├── Player.storyboard                # Dedicated Video Player storyboard
│       ├── VideoPlayerViewController.swift  # AVPlayerLayer, overlay controls, scrubber
│       ├── EventHandling/
│       │   ├── PlayerEventHandlerProtocol.swift
│       │   └── AVPlayerEventHandler.swift   # Observes AVPlayer KVO, notifications, time
│       └── ViewModels/
│           ├── VideoPlayerViewModelProtocol.swift
│           └── VideoPlayerViewModel.swift   # Routes events to Analytics & publishes UI state
├── Domain/
│   ├── Models/
│   │   ├── MediaItem.swift                  # Pure business models (MediaItem, ContentSection, HomeContent)
│   │   └── PlayerEvent.swift                # Playback telemetry events
│   ├── Repositories/
│   │   ├── ContentRepositoryProtocol.swift  # Repository domain contract
│   │   └── PlayerAnalyticsRepositoryProtocol.swift # Telemetry domain contract
│   └── UseCases/
│       └── GetHomeContentUseCase.swift      # Encapsulates home content retrieval
├── Data/
│   ├── DataSources/
│   │   ├── ContentRemoteDataSourceProtocol.swift # Abstract data source contract
│   │   ├── MockContentRemoteDataSource.swift     # Bundled JSON mock provider
│   │   └── URLSessionContentRemoteDataSource.swift # Real HTTP endpoint provider
│   ├── DTOs/
│   │   └── HomeResponseDTO.swift            # Decodable network models
│   ├── Mappers/
│   │   └── MediaMapper.swift                # DTO -> Domain Entity transformation
│   └── Repositories/
│       ├── ContentRepository.swift          # Implements ContentRepositoryProtocol
│       └── ConsolePlayerAnalyticsRepository.swift # Implements PlayerAnalyticsRepositoryProtocol
└── Resources/
    └── MockData/
        └── home_response.json               # Static JSON response (Hero + Rails)
```

---

## 5. Libraries Used
* **100% Native Apple Frameworks**:
  * `UIKit` — Interface Builder Storyboards, XIBs, and Auto Layout.
  * `AVFoundation` & `AVKit` — Core media playback engine and player layer.
  * `Combine` — Reactive state binding between ViewModels and ViewControllers.
  * `Testing` — Swift Testing framework (`@Test`, `#expect`) for fast, modern unit tests.
* **Zero Third-Party Dependencies**: No external pods or SPM packages required, ensuring zero dependency bloat and instant builds.

---

## 6. Key Technical & Architectural Decisions

1. **Protocol-Driven Dependency Inversion (SOLID)**:
   - All layers communicate via protocols. ViewModels depend on UseCase protocols, Repositories depend on DataSource protocols, and the Player depends on an EventHandler protocol.
2. **UICollectionViewCompositionalLayout**:
   - Used for the Home screen to achieve a modern OTT layout: a full-width Hero Banner section paired with horizontally scrolling orthogonal rails without nesting collection views inside table view cells.
3. **Modular Storyboards & XIBs**:
   - Individual feature storyboards avoid the classic iOS anti-pattern of an oversized `Main.storyboard`, facilitating clean Git merges and team scalability.
4. **Clean Application State Flow**:
   - `ViewState<T>` handles `.idle`, `.loading`, `.success`, `.empty`, and `.error(message)` with retry capability in the UI.

---

## 7. Player Event Handling Approach

As mandated in Section 5 of the specification, player events are **not** handled or logged directly in the `UIViewController`. Instead, they flow through a dedicated four-stage pipeline:

```
[AVPlayer]
    │ (KVO, Time Observers, NSNotifications)
    ▼
[AVPlayerEventHandler]
    │ (PlayerEventHandlerDelegate: .ready, .started, .paused, .seeked, .buffering, .completed, .error)
    ▼
[VideoPlayerViewModel]
    │ (Updates reactive UI state & dispatches to repository)
    ▼
[PlayerAnalyticsRepositoryProtocol] ──► [ConsolePlayerAnalyticsRepository]
                                        (Outputs formatted [ANALYTICS] logs)
```

### Handled Events:
1. `PLAYER_READY`: Triggered when `AVPlayerItem.status == .readyToPlay`.
2. `PLAYER_STARTED`: Triggered when `AVPlayer.timeControlStatus == .playing`.
3. `PLAYER_PAUSED`: Triggered when playback pauses (excluding end of stream).
4. `PLAYER_SEEKED`: Triggered when the user scrubs or jumps ±10 seconds.
5. `BUFFERING_STARTED` / `BUFFERING_ENDED`: Triggered via `isPlaybackBufferEmpty` and `isPlaybackLikelyToKeepUp`.
6. `PLAYER_COMPLETED`: Triggered via `NotificationCenter` on `.AVPlayerItemDidPlayToEndTime`.
7. `PLAYER_ERROR`: Triggered if item status changes to `.failed`.

### Lifecycle & Resource Management:
* Listens to `UIApplication.didEnterBackgroundNotification` to automatically pause playback.
* In `deinit` and `cleanupPlayer()`, observers (`removeTimeObserver`, KVO token invalidation, NotificationCenter removal) are explicitly torn down to prevent retain cycles and background audio leaks.

---

## 8. How Mock Data Source Is Replaced with a Real API

The application is **100% API-Ready**. Both data source implementations conform to `ContentRemoteDataSourceProtocol`:

```swift
protocol ContentRemoteDataSourceProtocol {
    func fetchHomeData() async throws -> HomeResponseDTO
}
```

To switch from the Mock JSON file to a live backend API, change **one single line** in `SceneDelegate.swift` (Composition Root):

```swift
// FROM (Mock):
let dataSource = MockContentRemoteDataSource()

// TO (Production API):
let dataSource = URLSessionContentRemoteDataSource(baseURL: URL(string: "https://api.myott.com/v1")!)
```

**Zero changes** are needed in:
* `ContentRepository`
* `GetHomeContentUseCase`
* Domain Models (`MediaItem`, `ContentSection`)
* `HomeViewModel`
* `HomeViewController`

---

## 9. Known Limitations (Future Enhancements)

* **Offline Caching**: Video streams are streamed live; integrating `AVAssetDownloadURLSession` would enable offline download capabilities.
* **Picture-in-Picture (PiP)**: Can be enabled via `AVPictureInPictureController` for multitasking.
* **Coordinator Pattern**: While navigation is currently managed via UINavigationController and modal presentation, introducing an app-wide `Coordinator` / `Router` would further decouple view controllers from navigation flow in a larger application.
