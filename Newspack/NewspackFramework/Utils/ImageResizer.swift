import UIKit
import Foundation

/// A singleton class for resizing UIImages. Resized images are kept in an NSCache
/// for quick retrieval.  The resized images are resized so they will aspectFill
/// their target size. (No letterboxing!)
///
public class ImageResizer {

    /// Singleton reference.
    public static let shared = ImageResizer()

    private var cache = NSCache<NSString, UIImage>()

    private var renderers = [CGSize: UIGraphicsImageRenderer]()

    /// Private initializer.  Use the singleton.
    private init() {}

    /// Creates a resized version of the specified UIImage. Resized images are
    /// cached for later retrivial via their identifier and size.
    ///
    /// - Parameters:
    ///   - image: The UIImage instance to resize.
    ///   - identifier: An identifier to use as part of a cache key for later retrieval.
    ///   - size: The target size that the resized image should fill. Used as part of the cache key.
    ///   - force: Whether to skip the cache and create a freshly resized image. Default is false.
    /// - Returns: The resized image.
    ///
    public func resizeImage(image: UIImage, identifier: String, fillingSize size: CGSize, force: Bool = false) -> UIImage {

        // Return a cached iamge if one exists.
        if !force, let thumb = resizedImage(identifier: identifier, size: size) {
            return thumb
        }

        let originalSize = image.size
        let scale = max((size.width / originalSize.width), (size.height / originalSize.height))
        let targetSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)

        let r = renderer(for: targetSize)

        let thumb = r.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        cacheImage(image: thumb, identifier: identifier, size: size)

        return thumb
    }

    /// Fetches a resized image from the cache (if it exists).
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the image.
    ///   - size: The size of the image.
    /// - Returns: The cached image or nil if one was not found.
    ///
    public func resizedImage(identifier: String, size: CGSize) -> UIImage? {
        let key = cacheKey(for: identifier, size: size)
        return cache.object(forKey: key)
    }

    /// Adds the specified image to the internal cache based on its identifier and size.
    /// - Parameters:
    ///   - image: The UIImage to cache.
    ///   - identifier: The identifier to use as one part of the cache key.
    ///   - size: The size of the image. This is used as the second part of the cache key.
    private func cacheImage(image: UIImage, identifier: String, size: CGSize) {
        let key = cacheKey(for: identifier, size: size)
        cache.setObject(image, forKey: key)
    }

    /// Returns a UIGraphicsImageRenderer to render images of the specified size.
    /// Rather than recreating renderers as needed we keep them in memory for
    /// performance reasons.  UIGraphicsImageRenderer maintain an internal cache
    /// that can speed up recreating images as needed.
    ///
    /// - Parameter size: The size of UIImage that the renderer should create.
    /// - Returns: A renderer. If one is not cached a new renderer is created.
    ///
    private func renderer(for size: CGSize) -> UIGraphicsImageRenderer {
        if let renderer = renderers[size] {
            return renderer
        }
        let renderer = UIGraphicsImageRenderer(size: size)
        renderers[size] = renderer
        return renderer
    }

    /// Create a key to use for the image cache based on the identifier and size.
    ///
    /// - Parameters:
    ///   - identifier: The identifier to use for the key.
    ///   - size: The CGSize to use for the key.
    /// - Returns: An NSString to use as a cache key.
    ///
    private func cacheKey(for identifier: String, size: CGSize) -> NSString {
        let key = identifier + String(size.hashValue)
        return NSString(string: key)
    }
}
