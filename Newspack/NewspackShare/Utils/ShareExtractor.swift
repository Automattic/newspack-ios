import Foundation
import CoreServices
import UIKit
import NewspackFramework

/// A type that represents the information we can extract from an extension context
///
struct ExtractedShare {
    var images: [ExtractedImage]
    var movies: [ExtractedMovie]
}

struct ExtractedImage {
    let url: URL
}

struct ExtractedMovie {
    let url: URL
}

/// Extracts valid information from an extension context.
///
struct ShareExtractor {
    let extensionContext: NSExtensionContext
    let tempDirectory: URL

    init(extensionContext: NSExtensionContext, tempDirectory: URL) {
        self.extensionContext = extensionContext
        self.tempDirectory = tempDirectory
    }

    /// Loads the content asynchronously.
    ///
    /// - Important: This method will only call completion if it can successfully extract content.
    /// - Parameters:
    ///   - completion: the block to be called when the extractor has obtained content.
    ///
    func loadShare(completion: @escaping (ExtractedShare) -> Void) {
        extractMovies { extractedMovies in
            self.extractImages { extractedImages in
                completion(ExtractedShare(images: extractedImages, movies: extractedMovies))
            }
        }
    }

    /// Determines if the extractor will be able to obtain valid content from
    /// the extension context.
    ///
    /// This doesn't ensure success though. It will only check that the context
    /// includes known types, but there might still be errors loading the content.
    ///
    var validContent: Bool {
        return imageExtractor != nil
    }
}


// MARK: - Private

/// A private type that represents the information we can extract from an extension context
/// attachment
///
private struct ExtractedItem {
    /// An image
    ///
    var images = [ExtractedImage]()
    var movies = [ExtractedMovie]()
}

private extension ShareExtractor {

    var imageExtractor: ExtensionContentExtractor? {
        return ImageExtractor(tempDirectory: tempDirectory)
    }

    var movieExtractor: ExtensionContentExtractor? {
        return MovieExtractor(tempDirectory: tempDirectory)
    }

    func extractImages(completion: @escaping ([ExtractedImage]) -> Void) {
        guard let imageExtractor = imageExtractor else {
            completion([])
            return
        }
        imageExtractor.extract(context: extensionContext) { extractedItems in
            guard extractedItems.count > 0 else {
                completion([])
                return
            }
            var extractedImages = [ExtractedImage]()
            extractedItems.forEach { item in
                item.images.forEach { extractedImage in
                    extractedImages.append(extractedImage)
                }
            }

            completion(extractedImages)
        }
    }

    func extractMovies(completion: @escaping ([ExtractedMovie]) -> Void) {
        guard let movieExtractor = movieExtractor else {
            completion([])
            return
        }
        movieExtractor.extract(context: extensionContext) { extractedItems in
            guard extractedItems.count > 0 else {
                completion([])
                return
            }
            var extractedMovies = [ExtractedMovie]()
            extractedItems.forEach { item in
                item.movies.forEach { movie in
                    extractedMovies.append(movie)
                }
            }

            completion(extractedMovies)
        }

    }
}

private protocol ExtensionContentExtractor {
    func canHandle(context: NSExtensionContext) -> Bool
    func extract(context: NSExtensionContext, completion: @escaping ([ExtractedItem]) -> Void)
    func saveToSharedContainer(data: Data, fileExtension: String) -> URL?
    func saveToSharedContainer(wrapper: FileWrapper) -> URL?
    func copyToSharedContainer(url: URL) -> URL?
}

private protocol TypeBasedExtensionContentExtractor: ExtensionContentExtractor {
    associatedtype Payload
    var tempDirectory: URL { get }
    var acceptedType: String { get }
    func convert(payload: Payload) -> ExtractedItem?
}

private extension TypeBasedExtensionContentExtractor {

    func canHandle(context: NSExtensionContext) -> Bool {
        return !context.itemProviders(ofType: acceptedType).isEmpty
    }

    func extract(context: NSExtensionContext, completion: @escaping ([ExtractedItem]) -> Void) {
        let itemProviders = context.itemProviders(ofType: acceptedType)
        var results = [ExtractedItem]()
        guard itemProviders.count > 0 else {
            DispatchQueue.main.async {
                completion(results)
            }
            return
        }

        // There 1 or more valid item providers here, lets work through them
        let syncGroup = DispatchGroup()
        for provider in itemProviders {
            syncGroup.enter()
            // Remember, this is an async call....
            provider.loadItem(forTypeIdentifier: acceptedType, options: nil) { (payload, error) in
                let payload = payload as? Payload
                let result = payload.flatMap(self.convert(payload:))
                if let result = result {
                    results.append(result)
                }
                syncGroup.leave()
            }
        }

        // Call the completion handler after all of the provider items are loaded
        syncGroup.notify(queue: DispatchQueue.main) {
            completion(results)
        }
    }

    func saveToSharedContainer(data: Data, fileExtension: String) -> URL? {
        guard let fullPath = tempPath(for: fileExtension) else {
            return nil
        }
        do {
            try data.write(to: fullPath, options: [.atomic])
        } catch {
            print("Error saving \(fullPath) to shared container: \(String(describing: error))")
            return nil
        }
        return fullPath
    }

    func saveToSharedContainer(wrapper: FileWrapper) -> URL? {
        guard let wrappedFileName = wrapper.filename?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let wrappedURL = URL(string: wrappedFileName),
            let newPath = tempPath(for: wrappedURL.pathExtension) else {
                return nil
        }

        do {
            try wrapper.write(to: newPath, options: [], originalContentsURL: nil)
        } catch {
            print("Error saving \(newPath) to shared container: \(String(describing: error))")
            return nil
        }

        return newPath
    }

    func copyToSharedContainer(url: URL) -> URL? {
        guard let newPath = tempPath(for: url.lastPathComponent) else {
            return nil
        }

        do {
            try FileManager.default.copyItem(at: url, to: newPath)
        } catch {
            print("Error saving \(newPath) to shared container: \(String(describing: error))")
            return nil
        }

        return newPath
    }

    private func tempPath(for ext: String) -> URL? {
        return FileManager.default.availableFileURL(for: ext, isDirectory: false, relativeTo: tempDirectory)
    }
}


private struct ImageExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = AnyObject
    let acceptedType = kUTTypeImage as String
    let tempDirectory: URL
    func convert(payload: AnyObject) -> ExtractedItem? {
        var returnedItem = ExtractedItem()

        switch payload {
        case let url as URL:
            if let itemURL = copyToSharedContainer(url: url) {
                returnedItem.images = [ExtractedImage(url: itemURL)]
            }
        case var data as Data:
            if data.imageContentType == .unknown, let encodedData = encodeImageDataAsJPEG(data: data) {
                data = encodedData
            }
            let ext = data.imageContentType.fileExtension
            if let itemURL = saveToSharedContainer(data: data, fileExtension: ext) {
                returnedItem.images = [ExtractedImage(url: itemURL)]
            }
        case let image as UIImage:
            // If we have a UIImage, just save as a JPEG for now.
            if let data = image.JPEGEncoded(),
               let itemURL = saveToSharedContainer(data: data, fileExtension: Data.ImageContentType.jpg.fileExtension) {
                returnedItem.images = [ExtractedImage(url: itemURL)]
            }
        default:
            break
        }
        return returnedItem
    }

    func encodeImageDataAsJPEG(data: Data) -> Data? {
        guard
            let image = UIImage(data: data),
            let data = image.JPEGEncoded()
        else {
            return nil
        }
        return data
    }
}

private struct MovieExtractor: TypeBasedExtensionContentExtractor {
    typealias Payload = AnyObject
    let acceptedType = kUTTypeMovie as String // Note: The UTI for kUTTypeMovie encompases other types like kUTTypeVideo
    let tempDirectory: URL
    func convert(payload: AnyObject) -> ExtractedItem? {
        var returnedItem = ExtractedItem()

        switch payload {
        case let url as URL:
            if let itemURL = copyToSharedContainer(url: url) {
                returnedItem.movies = [ExtractedMovie(url: itemURL)]
            }
        case let data as Data:
            if let itemURL = saveToSharedContainer(data: data, fileExtension: "mp4") {
                returnedItem.movies = [ExtractedMovie(url: itemURL)]
            }
        default:
            break
        }

        return returnedItem
    }
}
