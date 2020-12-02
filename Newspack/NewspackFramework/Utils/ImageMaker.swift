import UIKit
import AVKit

public class ImageMaker {

    public static func imageFromImageFile(at bookmark: Data, size: CGSize, identifier: String) -> UIImage? {
        if let image = ImageResizer.shared.resizedImage(identifier: identifier, size: size) {
            return image
        }

        guard let url = FolderManager().urlFromBookmark(bookmark: bookmark) else {
            return nil
        }

        return imageFromImageFile(at: url, size: size, identifier: identifier)
    }

    public static func imageFromImageFile(at url: URL, size: CGSize, identifier: String) -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        return ImageResizer.shared.resizeImage(image: image, identifier: identifier, fillingSize: size)
    }

    public static func imageFromVideoFile(at bookmark: Data, size: CGSize, identifier: String) -> UIImage? {
        if let image = ImageResizer.shared.resizedImage(identifier: identifier, size: size) {
            return image
        }

        guard let url = FolderManager().urlFromBookmark(bookmark: bookmark) else {
            return nil
        }

        return imageFromVideoFile(at: url, size: size, identifier: identifier)
    }

    public static func imageFromVideoFile(at url: URL, size: CGSize, identifier: String) -> UIImage? {
        if let image = ImageResizer.shared.resizedImage(identifier: identifier, size: size) {
            return image
        }

        let asset = AVURLAsset(url: url, options: nil)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: 0, timescale: 1)

        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }

        return ImageResizer.shared.resizeImage(image: UIImage(cgImage: cgImage),
                                               identifier: identifier,
                                               fillingSize: size)

    }

}
