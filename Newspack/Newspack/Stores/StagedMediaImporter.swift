import Foundation
import CoreData
import CoreImage
import MobileCoreServices
import Photos

enum WriteError: Error {
    case unableToWrite
}

class StagedMediaImporter: NSObject {

    private class Constants {
        static let stagedMediaFolderName = "StagedMedia"
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
        static let jpgExt = ".jpg"
        static let pngExt = ".png"
        static let heicExt = ".heic"
    }

    let resultsController: NSFetchedResultsController<StagedMedia>
    var currentImportID: UUID?

    init(site: Site) {
        let request = StagedMedia.defaultFetchRequest()
        request.predicate = NSPredicate(format: "assetIdentifier != NULL AND localFilePath == NULL AND site == %@", site)
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: true)]

        let context = CoreDataManager.shared.mainContext
        resultsController = NSFetchedResultsController(fetchRequest: request,
                                                       managedObjectContext:context,
                                                       sectionNameKeyPath: nil,
                                                       cacheName: nil)
        super.init()
        resultsController.delegate = self
        try? resultsController.performFetch()
        importNext()
    }

    func importNext() {
        guard currentImportID == nil else {
            // Busy.
            return
        }

        guard let nextMedia = resultsController.fetchedObjects?.first else {
            // Nothing to do.
            return
        }

        let objectID = nextMedia.objectID

        guard
            let identifier = nextMedia.assetIdentifier,
            let asset = fetchAssetByIdentifier(identifier: identifier)
        else {
            // TODO: Delete record. The asset is unavailable.
            StoreContainer.shared.stagedMediaStore.deleteStagedMedia(objectID: objectID)
            LogWarn(message: "importNext: Unable to fetch asset by identifier.")
            return
        }

        LogDebug(message: "Import Next: \(nextMedia)")
        currentImportID = nextMedia.uuid
        importAsset(asset: asset) { (asset, fileURL, filename, mimeType, error) in
            if let error = error {
                LogError(message: "Error importing asset: \(error)")
                // TODO: handle error.
                // If networking, we can just abort.
                // If no longer exsting we should remove the record.
                StoreContainer.shared.stagedMediaStore.deleteStagedMedia(objectID: objectID)
                return
            }

            self.currentImportID = nil
            // Update record.
            CoreDataManager.shared.performOnWriteContext { (context) in
                let media = context.object(with: objectID) as! StagedMedia
                media.localFilePath = fileURL?.absoluteString
                media.originalFileName = filename
                media.mimeType = mimeType
                CoreDataManager.shared.saveContext(context: context)
                LogDebug(message: "ImportAsset: Saved")
            }
        }
    }

}

extension StagedMediaImporter: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        importNext()
    }
}

// MARK: - Asset File Management
extension StagedMediaImporter {

    /// Delete any files staged for upload.
    ///
    func purgeStagedMediaFiles() {
        guard let path = directoryPath() else {
            return
        }
        let fileManager = FileManager()
        if fileManager.fileExists(atPath: path.absoluteString) {
            try? fileManager.removeItem(at: path)
        }
    }

    /// Fetch a PHAsset by its localIdentifier.
    /// - Parameter identifier: An asset's localIdentifier.
    ///
    func fetchAssetByIdentifier(identifier: String) -> PHAsset? {
        return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }

    /// Imports an PHAsset to a local folder for uploading.
    /// - Parameter asset: A PHAsset instance.
    /// - Parameter onComplete: A completion handler called when the import is complete.
    ///
    func importAsset(asset: PHAsset, onComplete: @escaping ((PHAsset, URL?, String?, String?, Error?) -> Void)) {
        // TODO: Need to segment on mediaType. For now, assume image.

        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true

        asset.requestContentEditingInput(with: options) { (contentEditingInput, info) in
            guard
                let contentEditingInput = contentEditingInput,
                let uniformTypeIdentifier = contentEditingInput.uniformTypeIdentifier
            else {
                onComplete(asset, nil, nil, nil, nil)
                return
            }

            do {
                let originalFileName = contentEditingInput.fullSizeImageURL?.pathComponents.last
                let fileURL = try self.copyAssetToFile(asset: asset, contentEditingInput: contentEditingInput)
                let mime = self.mimeTypeFromUTI(identifier: uniformTypeIdentifier)
                onComplete(asset, fileURL, originalFileName, mime, nil)
            } catch {
                onComplete(asset, nil, nil, nil, error)
            }
        }
    }

    /// Attempt to get an asset's mime type from its uniform type identifier.
    /// - Parameter identifier: A unitform type identifier.
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
    /// - Parameter metaData: Dictionary of image meta data.
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
    /// - Parameter image: The image to sanitize.
    ///
    func prepareImage(image: CIImage) -> CIImage {
        let properties = sanitizeImageMetaData(metaData: image.properties)
        return image.settingProperties(properties)
    }

    /// A file URL to the upload directory.  Creates the directory if it doesn't exist.
    ///
    func directoryPath() -> URL? {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directoryPath = documentDirectory.appendingPathComponent(Constants.stagedMediaFolderName, isDirectory: true)
        if !fileManager.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            do {
                try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // TODO:
                return nil
            }
        }

        return directoryPath
    }

    /// Copy the file backing a PHAsset to a local directory in preparation for uploading.
    /// - Parameter asset: A PHAsset instance.  An image is expected.
    /// - Parameter contentEditingInput: A PHContentEditingInput instance
    ///
    func copyAssetToFile(asset: PHAsset, contentEditingInput: PHContentEditingInput) throws -> URL? {
        guard
            let directoryPath = directoryPath(),
            let originalFileURL = contentEditingInput.fullSizeImageURL,
            let originalImage = CIImage(contentsOf: originalFileURL),
            let uti = contentEditingInput.uniformTypeIdentifier
        else {
            throw WriteError.unableToWrite
        }

        let image = prepareImage(image: originalImage)
        let fileURL = directoryPath.appendingPathComponent(UUID().uuidString).appendingPathExtension(originalFileURL.pathExtension)

        try writeImage(image: image, withUTI: uti, toFile: fileURL)

        return fileURL
    }

    /// Create a new image file from the provided CIImage at the specified location.
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
