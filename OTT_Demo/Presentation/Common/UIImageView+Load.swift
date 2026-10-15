import UIKit

// MARK: - Simple Image Cache & Loader
// Downloads images asynchronously with in-memory caching.
// Ensures cells don't flicker when reused.

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 100 // Cache up to 100 images in memory
    }

    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }

    func save(image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

private var taskKey: UInt8 = 0

extension UIImageView {
    private var currentTask: URLSessionDataTask? {
        get { objc_getAssociatedObject(self, &taskKey) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Loads an image from a URL, using cache if available.
    func loadImage(from url: URL?, placeholder: UIImage? = UIImage(systemName: "film")) {
        currentTask?.cancel()
        self.image = placeholder

        guard let url = url else { return }

        // 1. Check cache first
        if let cachedImage = ImageCache.shared.image(for: url) {
            self.image = cachedImage
            return
        }

        // 2. Download asynchronously
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, error == nil, let data = data, let image = UIImage(data: data) else {
                return
            }

            ImageCache.shared.save(image: image, for: url)

            DispatchQueue.main.async {
                self.image = image
            }
        }

        self.currentTask = task
        task.resume()
    }
}
