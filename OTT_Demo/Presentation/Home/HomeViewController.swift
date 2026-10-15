import UIKit
import Combine

// MARK: - HomeViewController
// Implements the OTT Home Screen using Main.storyboard and XIBs:
// - UICollectionView with UICollectionViewCompositionalLayout
// - Prominent Hero Banner loaded from HeroBannerCell.xib
// - Horizontally scrolling content rails loaded from ContentCardCell.xib
// - Handles all UI states (Loading, Success, Empty, Error)
// - IBOutlets wired directly from Main.storyboard

final class HomeViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var errorView: UIStackView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var emptyLabel: UILabel!

    // MARK: - Dependencies & State
    private var viewModel: HomeViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Injects ViewModel when instantiated from Storyboard
    func configure(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        if isViewLoaded {
            bindViewModel()
            viewModel.loadContent()
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        if viewModel != nil {
            bindViewModel()
            viewModel.loadContent()
        }
    }

    // MARK: - Orientation Support
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        title = "OTT Demo"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.backButtonDisplayMode = .minimal
    }

    // MARK: - Setup CollectionView
    private func setupCollectionView() {
        guard let cv = collectionView else { return }

        // Set modern compositional layout dynamically
        cv.collectionViewLayout = makeLayout()
        cv.dataSource = self
        cv.delegate = self

        // Register XIB-based cells
        cv.register(
            UINib(nibName: "HeroBannerCell", bundle: nil),
            forCellWithReuseIdentifier: HeroBannerCell.reuseIdentifier
        )
        cv.register(
            UINib(nibName: "ContentCardCell", bundle: nil),
            forCellWithReuseIdentifier: ContentCardCell.reuseIdentifier
        )
        // Register Supplementary View Header
        cv.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )
    }

    // MARK: - ViewModel Binding (Requirement #9: Application State)
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: ViewState<HomeContent>) {
        switch state {
        case .idle:
            loadingIndicator.stopAnimating()
            collectionView.isHidden = true
            errorView.isHidden = true
            emptyLabel.isHidden = true

        case .loading:
            loadingIndicator.startAnimating()
            collectionView.isHidden = true
            errorView.isHidden = true
            emptyLabel.isHidden = true

        case .success:
            loadingIndicator.stopAnimating()
            collectionView.isHidden = false
            errorView.isHidden = true
            emptyLabel.isHidden = true
            collectionView.reloadData()

        case .empty:
            loadingIndicator.stopAnimating()
            collectionView.isHidden = true
            errorView.isHidden = true
            emptyLabel.isHidden = false

        case .error(let message):
            loadingIndicator.stopAnimating()
            collectionView.isHidden = true
            emptyLabel.isHidden = true
            errorView.isHidden = false
            errorLabel.text = message
        }
    }

    // MARK: - IBActions
    @IBAction private func didTapRetry(_ sender: UIButton) {
        viewModel.loadContent()
    }

    // MARK: - Navigation
    private func navigateToDetail(with item: MediaItem) {
        let storyboard = UIStoryboard(name: "Detail", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(withIdentifier: "ContentDetailViewController") as? ContentDetailViewController else {
            return
        }
        let detailViewModel = ContentDetailViewModel(item: item)
        detailVC.configure(viewModel: detailViewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - UICollectionView Compositional Layout
    private func makeLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self = self else { return nil }

            if sectionIndex == 0 {
                // Section 0: Hero Banner Section
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(380)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
                return section
            } else {
                // Section 1+: Horizontal Rails
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(135),
                    heightDimension: .absolute(225)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16)

                // Rail Section Header
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(40)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section
            }
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            // Hero Banner Cell (loaded from HeroBannerCell.xib)
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HeroBannerCell.reuseIdentifier,
                for: indexPath
            ) as? HeroBannerCell,
            let heroItem = viewModel.heroItem else {
                return UICollectionViewCell()
            }

            cell.configure(with: heroItem)
            cell.onCTATapped = { [weak self] in
                self?.navigateToDetail(with: heroItem)
            }
            return cell
        } else {
            // Content Card Cell (loaded from ContentCardCell.xib)
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ContentCardCell.reuseIdentifier,
                for: indexPath
            ) as? ContentCardCell,
            let item = viewModel.item(inSection: indexPath.section, at: indexPath.item) else {
                return UICollectionViewCell()
            }

            cell.configure(with: item)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SectionHeaderView.reuseIdentifier,
                for: indexPath
              ) as? SectionHeaderView,
              let title = viewModel.sectionTitle(for: indexPath.section) else {
            return UICollectionReusableView()
        }

        header.configure(with: title)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedItem = viewModel.item(inSection: indexPath.section, at: indexPath.item) else { return }
        navigateToDetail(with: selectedItem)
    }
}
