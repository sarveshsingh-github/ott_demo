import UIKit

// MARK: - ContentDetailViewController
// Displays detailed information about a selected movie/show:
// - Banner/Poster
// - Title
// - Description
// - Play Button (Launches Video Player)
// - Uses Detail.storyboard and follows MVVM via ContentDetailViewModelProtocol

final class ContentDetailViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var bannerImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!

    // MARK: - ViewModel & Callback
    private var viewModel: ContentDetailViewModelProtocol!
    var onPlayRequested: ((MediaItem) -> Void)?

    // MARK: - Init
    init(viewModel: ContentDetailViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Configures the ViewController with its ViewModel
    func configure(viewModel: ContentDetailViewModelProtocol) {
        self.viewModel = viewModel
        if isViewLoaded {
            renderData()
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if viewModel != nil {
            renderData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure returning from full-screen player restores normal portrait layout
        if #available(iOS 16.0, *) {
            view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    // MARK: - Orientation Support
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
    }

    private func renderData() {
        guard let vm = viewModel else { return }
        title = vm.title
        titleLabel?.text = vm.title
        descriptionLabel?.text = vm.description
        bannerImageView?.loadImage(from: vm.imageURL)
    }

    // MARK: - IBActions
    @IBAction private func didTapPlayButton(_ sender: UIButton) {
        guard let vm = viewModel else { return }
        if let onPlayRequested = onPlayRequested {
            onPlayRequested(vm.item)
            return
        }

        let storyboard = UIStoryboard(name: "Player", bundle: nil)
        guard let playerVC = storyboard.instantiateViewController(withIdentifier: "VideoPlayerViewController") as? VideoPlayerViewController else {
            return
        }
        let playerViewModel = VideoPlayerViewModel(item: vm.item)
        playerVC.configure(viewModel: playerViewModel)
        playerVC.modalPresentationStyle = .fullScreen
        present(playerVC, animated: true)
    }
}
