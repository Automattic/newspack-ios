import Foundation

/// Props https://stackoverflow.com/a/57361865
///
extension Data {
    public enum ImageContentType: String {
        case jpg, png, gif, tiff, unknown

        public var fileExtension: String {
            return self.rawValue
        }
    }

    public var imageContentType: ImageContentType {

        var values = [UInt8](repeating: 0, count: 1)

        self.copyBytes(to: &values, count: 1)

        switch (values[0]) {
        case 0xFF:
            return .jpg
        case 0x89:
            return .png
        case 0x47:
           return .gif
        case 0x49, 0x4D :
           return .tiff
        default:
            return .unknown
        }
    }
}
