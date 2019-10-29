import Foundation
import CoreData
import WPMediaPicker
import WordPressFlux

/// Provides a bridge between the media stores and the media picker.
///
class SiteMediaDataSource: NSObject {
    private var currentIndex = 0
    private var ascendedOrder = false
    private var mediaFilter = WPMediaType.image
    private var observers = [NSUUID: WPMediaChangesBlock]()
    private var groupObservers = [NSUUID: WPMediaGroupChangesBlock]()
    private let sortField = "dateGMT"

    private var itemsInserted = NSMutableIndexSet()
    private var itemsRemoved = NSMutableIndexSet()
    private var itemsChanged = NSMutableIndexSet()
    private var itemsMoved = [WPIndexMove]()

    var groups = [WPMediaGroup]()
    lazy var resultsController: NSFetchedResultsController<MediaItem> = {
        let fetchRequest = MediaItem.defaultFetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortField, ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    var mediaItemsReceipt: Receipt?

    override init() {
        super.init()

        mediaItemsReceipt = StoreContainer.shared.mediaItemStore.onStateChange({ [weak self] state in
            self?.handleMediaItemsStateChanged(oldState: state.0, newState: state.1)
        })

        resultsController.delegate = self
        configureResultsController()
    }

    func handleMediaItemsStateChanged(oldState: MediaItemStoreState, newState: MediaItemStoreState) {
        if oldState == .syncing {

            // no op?
        } else if oldState == .changingQuery {
            configureResultsController()
        }
    }

    func configureResultsController() {
        if let mediaQuery = StoreContainer.shared.mediaItemStore.currentQuery {
            resultsController.fetchRequest.predicate = NSPredicate(format: "queries contains %@", mediaQuery)
        }

        try? resultsController.performFetch()

        configureGroups()
    }

    func configureGroups() {
        let image = UIImage(named: "media-group-default")!
        let count = resultsController.fetchedObjects?.count ?? 0
        if count > 0 {
            // todo: Use the first image.
        }
        let group = MediaLibraryGroup(name: NSLocalizedString("WordPress Media", comment: "Media title."),
                                      identifier: "com.newspack.medialibrary",
                                      numberofAssets: count,
                                      image: image)
        groups = [group]
    }

    func notifyGroupObservers() {
        for callback in groupObservers.values {
            callback()
        }
    }

    func notifyObservers(incrementalChanges: Bool, removed: NSIndexSet, inserted: NSIndexSet, changed:NSIndexSet, moved: [WPMediaMove]) {
        for callback in observers.values {
            callback(incrementalChanges, removed as IndexSet, inserted as IndexSet, changed as IndexSet, moved)
        }
    }

    func notifyObserversReloadData() {
        notifyObservers(incrementalChanges: false,
                        removed: NSIndexSet(),
                        inserted: NSIndexSet(),
                        changed: NSIndexSet(),
                        moved: [WPMediaMove]())
    }
}

extension SiteMediaDataSource: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        itemsInserted.removeAllIndexes()
        itemsRemoved.removeAllIndexes()
        itemsChanged.removeAllIndexes()
        itemsMoved.removeAll()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert :
            itemsInserted.add(newIndexPath!.row)
        case .delete:
            itemsRemoved.add(indexPath!.row)
        case .update:
            itemsChanged.add(indexPath!.row)
        case .move:
            let moved = WPIndexMove(UInt(indexPath!.row), to: UInt(newIndexPath!.row))!
            itemsMoved.append(moved)
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if itemsChanged.contains(0) || itemsRemoved.contains(0) || itemsInserted.contains(0) {
            notifyGroupObservers()
        }
        notifyObservers(incrementalChanges: true, removed: itemsRemoved, inserted: itemsInserted, changed: itemsChanged, moved: itemsMoved)
    }
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

        let dispatcher = SessionManager.shared.sessionDispatcher
        dispatcher.dispatch(MediaAction.syncMedia(mediaID: item.mediaID))

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
        successBlock?()
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

class MediaLibraryGroup: NSObject {
    var groupName: String
    var groupID: String
    var groupImage: UIImage
    var groupAssetCount: Int

    init(name:String, identifier: String, numberofAssets: Int, image: UIImage) {
        groupName = name
        groupID = identifier
        groupAssetCount = numberofAssets
        groupImage = image

        super.init()
    }
}

extension MediaLibraryGroup: WPMediaGroup {
    func baseGroup() -> Any {
        self
    }

    func name() -> String {
        return groupName
    }

    func identifier() -> String {
        return groupID
    }

    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        completionHandler(groupImage, nil)
        return 0
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        // noop?
    }

    func numberOfAssets(of mediaType: WPMediaType, completionHandler: WPMediaCountBlock? = nil) -> Int {
        return groupAssetCount
    }
}

// Should wrap a MediaItem / Media object
class MediaAsset: NSObject, WPMediaAsset {
    let mediaID: Int32
    let mediaKind: MediaKind
    let sourceURL: String
    let dateCreated: Date
    var mediaDuration: TimeInterval = 0
    var image = UIImage(named: "media-group-default")!

    init(item: MediaItem) {
        mediaID = Int32(item.mediaID)
        mediaKind = item.mediaKind()
        sourceURL = item.sourceURL
        dateCreated = item.dateGMT

        guard
            let media = item.media,
            let img = media.cached?.image()
        else {
            return
        }
        image = img
    }

    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        // TODO: Need the image loader
        completionHandler(image, nil)
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
        switch mediaKind {
        case .image:
            return WPMediaType.image
        case .video:
            return WPMediaType.video
        case .audio:
            return WPMediaType.audio
        default:
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
        return CGSize(width: image.size.width, height: image.size.height)
    }

    // Note: This is marked as optional but if the assetType returns WPMediaType.other it is checked.
    // An exception is thrown if not implemented in this case.
    func filename() -> String? {
        return "unknown"
    }
}
