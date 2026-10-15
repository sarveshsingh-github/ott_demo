import UIKit

// MARK: - HeroBannerCell
// Displays the top prominent Hero Banner loaded from HeroBannerCell.xib.
// Shows banner image, title, short description, and a Play / View Details CTA.

final class HeroBannerCell: UICollectionViewCell {
    static let reuseIdentifier = "HeroBannerCell"

    // MARK: - IBOutlets
    @IBOutlet private weak var bannerImageView: UIImageView!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!

    // MARK: - Gradient
    private let gradientLayer = CAGradientLayer()

    // MARK: - Callback
    var onCTATapped: (() -> Void)?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGradient()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientView.bounds
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.85).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientView.layer.addSublayer(gradientLayer)
    }

    // MARK: - Configure
    func configure(with item: MediaItem) {
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        bannerImageView.loadImage(from: item.bannerURL ?? item.thumbnailURL)
    }

    // MARK: - IBActions
    @IBAction private func playButtonTapped(_ sender: UIButton) {
        onCTATapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bannerImageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
    }
}
