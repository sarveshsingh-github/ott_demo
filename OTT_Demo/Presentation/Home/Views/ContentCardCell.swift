import UIKit

// MARK: - ContentCardCell
// Displays an individual movie/show card loaded from ContentCardCell.xib.
// Shows a poster thumbnail and title.

final class ContentCardCell: UICollectionViewCell {
    static let reuseIdentifier = "ContentCardCell"

    // MARK: - IBOutlets
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
    }

    func configure(with item: MediaItem) {
        titleLabel.text = item.title
        thumbnailImageView.loadImage(from: item.thumbnailURL)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        titleLabel.text = nil
    }
}
