import UIKit

extension UIImage {
    convenience init?(contentsOfURL url: URL) {
        guard let rawImage = try? Data(contentsOf: url) else {
            return nil
        }

        self.init(data: rawImage)
    }

    func JPEGEncoded(_ quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }

    // TODO: NEEDS PNG Encoded option
}
