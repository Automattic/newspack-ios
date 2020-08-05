import Foundation
import CoreData
import CoreImage
import CoreServices
import Photos

/// Errors thrown by the MediaImporter
///
enum MediaImporterError: Error {
    case unableToWriteFile
    case invalidDestination
    case missingUniformTypeIdentifier
}

/// A utility for copying PHAssets to a specified directory in the file system.
///
class MediaImporter {

    private class Constants {
        static let utiHEIC = "public.heic"
        static let utiJPG = kUTTypeJPEG as String
        static let utiPNG = kUTTypePDF as String
        static let utiGIF = kUTTypeGIF as String
        static let utiLivePhoto = kUTTypeLivePhoto as String
        static let iptcDictionaryKey = kCGImagePropertyIPTCDictionary as String
        static let tiffDictionaryKey = kCGImagePropertyTIFFDictionary as String
        static let gpsDictionaryKey = kCGImagePropertyGPSDictionary as String
        static let iptcOrientationKey = kCGImagePropertyIPTCImageOrientation as String
        static let tiffOrientationKey = kCGImagePropertyTIFFOrientation as String
    }

    /// The identifier of the PHAsset currently being imported.
    private var currentImportID: String?

    /// A file URL to the destination directory.
    private let directoryPath: URL

    /// Staging array for PHAssets to import.
    private var assets = [PHAsset]()

    /// Designated initializer.
    ///
    /// - Parameter destination: A file URL pointing to the existing intended
    /// destination directory.  An error is thrown if the URL is not a file URL
    /// or does not point to a directory.
    ///
    init(destination: URL) throws {
        guard destination.isFileURL && destination.hasDirectoryPath else {
            throw MediaImporterError.invalidDestination
        }
        directoryPath = destination
    }

    /// Begins importing the specified assets.
    ///
    /// - Parameter assets: An array of PHAssets to copy to the destination directory.
    ///
    func importAssets(assets: [PHAsset]) {
        self.assets.append(contentsOf: assets)
        importNext()
    }

}

// MARK: - PHAsset / File Management

extension MediaImporter {

    /// Import the next PHAsset in the assets array.
    ///
    private func importNext() {
        // For now, skip when testing.
        guard !Environment.isTesting() else {
            return
        }

        guard currentImportID == nil else {
            // Busy importing.
            return
        }

        guard assets.count > 0 else {
            // No PHAssets to processs.
            return
        }

        // Import items as a queue not a stack.
        let asset = assets.removeFirst()

        currentImportID = asset.identifier()

        importAsset(asset: asset) { [weak self] (asset, fileURL, filename, mimeType, error) in
            if let error = error {
                LogError(message: "Error importing asset: \(error)")
                // TODO: handle error.
                // If networking, we can just abort.
                return
            }
            self?.currentImportID = nil
            self?.importNext()
        }
    }

    /// Imports an PHAsset to a local folder for uploading.
    ///
    /// - Parameter asset: A PHAsset instance.
    /// - Parameter onComplete: A completion handler called when the import is complete.
    ///
    func importAsset(asset: PHAsset, onComplete: @escaping ((PHAsset, URL?, String?, String?, Error?) -> Void)) {

        // TODO: Need to segment on mediaType. For now, assume image.

        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true

        asset.requestContentEditingInput(with: options) { (contentEditingInput, info) in
            if let error = info[PHContentEditingInputErrorKey] as? NSError {
                onComplete(asset, nil, nil, nil, error)
                return
            }

            guard
                let contentEditingInput = contentEditingInput,
                let uniformTypeIdentifier = contentEditingInput.uniformTypeIdentifier
            else {
                let error = MediaImporterError.missingUniformTypeIdentifier as NSError
                onComplete(asset, nil, nil, nil, error)
                return
            }

            do {
                let originalFileName = contentEditingInput.fullSizeImageURL?.pathComponents.last
                let mime = self.mimeTypeFromUTI(identifier: uniformTypeIdentifier)
                let fileURL = try self.copyAssetToFile(asset: asset, contentEditingInput: contentEditingInput)
                onComplete(asset, fileURL, originalFileName, mime, nil)
            } catch {
                onComplete(asset, nil, nil, nil, error)
            }
        }
    }

    /// Attempt to get an asset's mime type from its uniform type identifier.
    ///
    /// - Parameter identifier: A unitform type identifier.
    /// - Returns: THe mimetype for the identifier.
    ///
    func mimeTypeFromUTI(identifier: String) -> String {
        let uti = identifier as CFString
        guard let unretainedMime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType) else {
            return "application/octet-stream"
        }
        let mime = unretainedMime.takeRetainedValue() as String
        return mime as String
    }

    /// Removes GPS data.
    /// Fixes or removes orientation flags
    ///
    /// - Parameter metaData: Dictionary of image meta data.
    /// - Returns: The sanitized dictionary.
    ///
    func sanitizeImageMetaData(metaData: [String: Any]) -> [String: Any] {
        var properties = metaData
        // Remove GPS data
        properties.removeValue(forKey: Constants.gpsDictionaryKey)

        // Remove Orientation data
        if var tiffProps = properties[Constants.tiffDictionaryKey] as? [String: Any] {
            tiffProps.removeValue(forKey: Constants.tiffOrientationKey)
            properties[Constants.tiffDictionaryKey] = tiffProps
        }

        if var iptcProps = properties[Constants.iptcDictionaryKey] as? [String: Any] {
            iptcProps.removeValue(forKey: Constants.iptcOrientationKey)
            properties[Constants.iptcDictionaryKey] = iptcProps
        }

        return properties
    }

    /// Returns a new, prepared, instance of the supplied CIImage instance.
    ///
    /// - Parameter image: The image to sanitize.
    /// - Returns: A CIImage instance.
    ///
    func prepareImage(image: CIImage) -> CIImage {
        let properties = sanitizeImageMetaData(metaData: image.properties)
        return image.settingProperties(properties)
    }

    /// Copy the file backing a PHAsset to a local directory in preparation for uploading.
    ///
    /// - Parameter asset: A PHAsset instance.  An image is expected.
    /// - Parameter contentEditingInput: A PHContentEditingInput instance
    /// - Returns: The file URL for the copied asset or nil.
    ///
    func copyAssetToFile(asset: PHAsset, contentEditingInput: PHContentEditingInput) throws -> URL? {
        guard
            let originalFileURL = contentEditingInput.fullSizeImageURL,
            let originalImage = CIImage(contentsOf: originalFileURL),
            let uti = contentEditingInput.uniformTypeIdentifier
        else {
            throw MediaImporterError.unableToWriteFile
        }

        let image = prepareImage(image: originalImage)
        let fileURL = importURLForOriginalURL(originalURL: originalFileURL)

        try writeImage(image: image, withUTI: uti, toFile: fileURL)

        return fileURL
    }

    /// Find a usable import URL for the original URL. If a file already exists
    /// at a candidate URL, a numeric suffix is added. The suffix will be
    /// incremented until an available filename is found.
    ///
    /// - Parameter originalURL: The original file URL.
    /// - Returns: An available URL for an imported asset.
    ///
    func importURLForOriginalURL(originalURL: URL) -> URL {
        let fileManager = FileManager()

        var candidateURL = directoryPath.appendingPathComponent(originalURL.lastPathComponent)
        guard fileManager.fileExists(atPath: candidateURL.path) else {
            return candidateURL
        }

        let filename = originalURL.lastPathComponent.components(separatedBy: ".").first!
        var counter = 1
        repeat {
            let path = "\(filename)-\(counter).\(originalURL.pathExtension)"
            candidateURL = directoryPath.appendingPathComponent(path)
            counter = counter + 1
        } while fileManager.fileExists(atPath: candidateURL.path)

        return candidateURL
    }

    /// Create a new image file from the provided CIImage at the specified location.
    ///
    /// - Parameter image: A CIImage instance
    /// - Parameter uti: The universal type identifier for the image.
    /// - Parameter fileURL: The location to save the file.
    ///
    func writeImage(image: CIImage, withUTI uti: String, toFile fileURL: URL) throws {
        if uti == Constants.utiJPG {
            try writeJPGImage(image: image, toFile: fileURL)

        } else if uti == Constants.utiPNG {
            try writePNGImage(image: image, fileURL: fileURL)

        } else if uti == Constants.utiLivePhoto {
            // Needs special handling. TBD

        } else if uti == Constants.utiGIF {
            // Needs special handling. TBD

        } else if uti == Constants.utiHEIC {
            try writeHEICImage(image: image, fileURL: fileURL)

        } else {
            // Treat as JPG
            try writeJPGImage(image: image, toFile: fileURL)
        }
    }

    /// Create an JPG image.
    ///
    /// - Parameter image: A CIImage instance
    /// - Parameter fileURL: The location to save the file.
    ///
    func writeJPGImage(image: CIImage, toFile fileURL: URL) throws {
        let context = CIContext()
        let options = [CIImageRepresentationOption: Any]()

        try context.writeJPEGRepresentation(of: image,
                                            to: fileURL,
                                            colorSpace: image.colorSpace!,
                                            options: options)
    }

    /// Create an PNG image.
    ///
    /// - Parameter image: A CIImage instance
    /// - Parameter fileURL: The location to save the file.
    ///
    func writePNGImage(image: CIImage, fileURL: URL) throws {
        let context = CIContext()
        let options = [CIImageRepresentationOption: Any]()

        try context.writePNGRepresentation(of: image,
                                           to: fileURL,
                                           format: CIFormat.RGBA8,
                                           colorSpace: image.colorSpace!,
                                           options: options)
    }

    /// Create an HEIF image.
    ///
    /// - Parameter image: A CIImage instance
    /// - Parameter fileURL: The location to save the file.
    ///
    func writeHEICImage(image: CIImage, fileURL: URL) throws {
        let context = CIContext()
        let options = [CIImageRepresentationOption: Any]()

        try context.writeHEIFRepresentation(of: image,
                                            to: fileURL,
                                            format: CIFormat.RGBA8,
                                            colorSpace: context.workingColorSpace!,
                                            options: options)
    }

}
