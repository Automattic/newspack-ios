import Foundation
import CoreData
import WPMediaPicker

class MediaLibraryGroup: NSObject {
    let currentQuery: MediaQuery

    init(mediaQuery: MediaQuery) {
        currentQuery = mediaQuery
    }
}
extension MediaLibraryGroup: WPMediaGroup {
    func baseGroup() -> Any {
        self
    }

    func name() -> String {
        return NSLocalizedString("WordPress Media", comment: "Media title.")
    }

    func identifier() -> String {
        return "com.newspack.medialibrary"
    }

    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        guard currentQuery.items.count > 0 else {
            completionHandler(nil, nil)
            return 0
        }

        // This would be the most recent photo as the group's image.
        let fetchRequest = MediaItem.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "queries contains %@", currentQuery)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let context = CoreDataManager.shared.mainContext
        guard let item = try? context.fetch(fetchRequest).first else {
            let placeholderImage = UIImage(named: "media-library-group-placeholder")
            completionHandler(placeholderImage, nil)
            return 0
        }

        // TODO: Need the image loader for this.
        let asset = MediaAsset(item: item)
        return asset.image(with: size, completionHandler: completionHandler)
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        // noop?
    }

    func numberOfAssets(of mediaType: WPMediaType, completionHandler: WPMediaCountBlock? = nil) -> Int {
        return currentQuery.items.count
    }

}


class SiteMediaDataSource: NSObject {
    private var currentIndex = 0
    private var ascendedOrder = false
    private var mediaFilter = WPMediaType.image
    private var observers = [NSUUID: WPMediaChangesBlock]()
    private var groupObservers = [NSUUID: WPMediaGroupChangesBlock]()

    var groups = [WPMediaGroup]()
    let currentQuery: MediaQuery
    let resultsController: NSFetchedResultsController<MediaItem>

    init(mediaQuery: MediaQuery) {
        currentQuery = mediaQuery

        let context = CoreDataManager.shared.mainContext
        let fetchRequest = MediaItem.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "queries contains %@", currentQuery)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        super.init()

        resultsController.delegate = self
        try? resultsController.performFetch()
    }

}

extension SiteMediaDataSource: NSFetchedResultsControllerDelegate {

}

extension SiteMediaDataSource: WPMediaCollectionDataSource {

    func numberOfGroups() -> Int {
        return groups.count
    }

    func group(at index: Int) -> WPMediaGroup {
        return groups[index]
    }

    func selectedGroup() -> WPMediaGroup? {
        return groups[currentIndex]
    }

    func setSelectedGroup(_ group: WPMediaGroup) {
        guard let idx = groups.firstIndex(where: {
            $0.identifier() == group.identifier()
        }) else {
            return
        }
        // TODO: handle any side effects of updating the index.
        currentIndex = idx
    }

    func numberOfAssets() -> Int {
        return resultsController.fetchedObjects?.count ?? 0
    }

    func media(at index: Int) -> WPMediaAsset {
        let item = resultsController.fetchedObjects![index]
        return MediaAsset(item: item)
    }

    func media(withIdentifier identifier: String) -> WPMediaAsset? {
        // In WPiOS this is a URI with an x-coredata URL scheme.
        // Not sure, but might be a locally cached image?
        // WPMediaAsset specifies an identifier field. Its probably this, whatever we set that to.
        // Potentially the image source_url.
        return nil
    }

    func registerChangeObserverBlock(_ callback: @escaping WPMediaChangesBlock) -> NSObjectProtocol {
        let uuid = NSUUID()
        observers[uuid] = callback
        return uuid
    }

    func registerGroupChangeObserverBlock(_ callback: @escaping WPMediaGroupChangesBlock) -> NSObjectProtocol {
        let uuid = NSUUID()
        groupObservers[uuid] = callback
        return uuid
    }

    func unregisterChangeObserver(_ blockKey: NSObjectProtocol) {
        guard let uuid = blockKey as? NSUUID else {
            return
        }
        observers.removeValue(forKey: uuid)
    }

    func unregisterGroupChangeObserver(_ blockKey: NSObjectProtocol) {
        guard let uuid = blockKey as? NSUUID else {
            return
        }
        groupObservers.removeValue(forKey: uuid)
    }

    func loadData(with options: WPMediaLoadOptions, success successBlock: WPMediaSuccessBlock?, failure failureBlock: WPMediaFailureBlock? = nil) {
        // TODO: Dispatch action to sync media.
    }

    func add(_ image: UIImage, metadata: [AnyHashable : Any]?, completionBlock: WPMediaAddedBlock? = nil) {
        // TODO: When implementing adding images.
    }

    func addVideo(from url: URL, completionBlock: WPMediaAddedBlock? = nil) {
        // TODO: When implementing adding video
    }

    func setMediaTypeFilter(_ filter: WPMediaType) {
        mediaFilter = filter
    }

    func mediaTypeFilter() -> WPMediaType {
        return mediaFilter
    }

    func setAscendingOrdering(_ ascending: Bool) {
        ascendedOrder = ascending
    }

    func ascendingOrdering() -> Bool {
        return ascendedOrder
    }

}

// Should wrap a MediaItem / Media object
class MediaAsset: NSObject, WPMediaAsset {
    let mediaID: Int32

    var mediaType = "image"
    var mediaDuration: TimeInterval = 0
    var sourceURL = ""
    var dateCreated = Date()
    var width = 0
    var height = 0

    init(item: MediaItem) {
        mediaID = Int32(item.mediaID)
        guard let media = item.media else {
            return
        }
        mediaType = media.type
        sourceURL = media.source
        dateCreated = media.dateGMT
        //width = media.width
        //height = media.height
        //mediaDuration = media.duration
    }

    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        // TODO: Need the image loader
        return mediaID
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        // noop?
    }

    func videoAsset(completionHandler: @escaping WPMediaAssetBlock) -> WPMediaRequestID {
        // TODO: Need the image loader
        return mediaID
    }

    func assetType() -> WPMediaType {
        if mediaType == "image" {
            return WPMediaType.image
        } else if mediaType == "video" {
            return WPMediaType.video
        } else if mediaType == "audio" {
            return WPMediaType.audio
        } else {
            return WPMediaType.other
        }
    }

    func duration() -> TimeInterval {
        return mediaDuration
    }

    func baseAsset() -> Any {
        // TODO: Maybe should return a media instance?  We might not yet have one...
        return self
    }

    func identifier() -> String {
        return sourceURL
    }

    func date() -> Date {
        return dateCreated
    }

    func pixelSize() -> CGSize {
        return CGSize(width: width, height: height)
    }

}
