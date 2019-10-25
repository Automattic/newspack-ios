import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing media related things.
///
class MediaStore: Store {
    typealias Item = Int64

    let requestQueue: RequestQueue<Int64, MediaStore>
    private var saveTimer: Timer?
    private var saveTimerInterval: TimeInterval = 1

    private(set) var currentSiteID: UUID?

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID
        requestQueue = RequestQueue<Int64, MediaStore>()
        super.init(dispatcher: dispatcher)
        requestQueue.delegate = self
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        if let apiAction = action as? MediaFetchedApiAction {
            handleMediaFetchedAction(action: apiAction)
            return
        }

        if let action = action as? MediaAction {
            switch action {
            case .syncItems:
                break
            case .syncMedia(let mediaID):
                syncMediaIfNecessary(mediaID: mediaID)
            }
        }
    }
}

extension MediaStore: RequestQueueDelegate {
    func itemEnqueued(item: Int64) {
        handleItemEnqueued(mediaID: item)
    }
}

extension MediaStore {

    /// Gets the MediaItem from core data for the specified media ID.
    ///
    /// - Parameter mediaID: The media ID of the item.
    /// - Returns: The model object, or nil if not found.
    ///
    func getMediaItemWithID(mediaID: Int64) -> MediaItem? {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = MediaItem.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mediaID = %ld", mediaID)
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            // TODO: Handle Error.
            let error = error as NSError
            LogError(message: "getMediaItemWithID: " + error.localizedDescription)
        }
        return nil
    }

    /// Syncs the Media for the spcified media ID if its associated MediaItem if
    /// the media is absent or its data is stale.  Internally this method appends
    /// the media id to a queue of media ids that need to be synced.
    ///
    /// - Parameter mediaID: The specified media ID
    ///
    func syncMediaIfNecessary(mediaID: Int64) {
        guard let mediaItem = getMediaItemWithID(mediaID: mediaID) else {
            LogWarn(message: "syncMediaIfNecessary: Unable to find media item by ID.")
            return
        }

        if mediaItem.isStale() {
            requestQueue.append(item: mediaItem.mediaID)
        }
    }

    /// Handles syncing an enqueued media ID.
    ///
    /// - Parameter mediaID: The media ID of the media to sync
    ///
    func handleItemEnqueued(mediaID: Int64) {
        // TODO: For offline support, when coming back online see if there are enqueued items.
        let service = ApiService.mediaService()
        service.fetchMedia(mediaID: mediaID)
    }

    /// Handles the dispatched action from the remote post service.
    ///
    /// - Parameter action: The action dispatched by the API
    ///
    func handleMediaFetchedAction(action: MediaFetchedApiAction) {
        guard !action.isError() else {
            // TODO: Handle error
            if let error = action.error as NSError? {
                LogError(message: "handleMediaFetchedAction: " + error.localizedDescription)
            }
            return
        }

        let siteStore = StoreContainer.shared.siteStore

        guard
            let remoteMedia = action.payload,
            let siteID = currentSiteID,
            let siteObjID = siteStore.getSiteByUUID(siteID)?.objectID,
            let itemObjID = getMediaItemWithID(mediaID: remoteMedia.mediaID)?.objectID
        else {
            LogError(message: "handleMediaFetchedAction: A value was unexpectedly nil.")
            return
        }

        // remove item from queue.
        // This should update the active queue and start the next sync
        requestQueue.remove(item: remoteMedia.mediaID)

        CoreDataManager.shared.performOnWriteContext { (context) in
            let site = context.object(with: siteObjID) as! Site
            let mediaItem = context.object(with: itemObjID) as! MediaItem

            let fetchRequest = Media.defaultFetchRequest()
            fetchRequest.predicate = NSPredicate(format: "site = %@ AND mediaID = %ld", site, remoteMedia.mediaID)

            let media: Media
            do {
                media = try context.fetch(fetchRequest).first ?? Media(context: context)
            } catch {
                media = Media(context: context)
                let error = error as NSError
                LogWarn(message: "handleMediaFetchedAction: " + error.localizedDescription)
            }

            self.updateMedia(media, with: remoteMedia)
            media.site = site
            media.item = mediaItem

            CoreDataManager.shared.saveContext(context: context)
        }
    }

    /// Update a post with a corresponding remote post
    ///
    /// - Parameters:
    ///   - post: the post to update
    ///   - remotePost: the remote post
    func updateMedia(_ media: Media, with remoteMedia: RemoteMedia) {
        media.mediaID = remoteMedia.mediaID

        media.altText = remoteMedia.altText
        media.authorID = remoteMedia.authorID
        media.caption = remoteMedia.caption
        media.captionRendered = remoteMedia.captionRendered
        media.commentStatus = remoteMedia.commentStatus
        media.date = remoteMedia.date
        media.dateGMT = remoteMedia.dateGMT
        media.descript = remoteMedia.descript
        media.descriptionRendered = remoteMedia.descriptionRendered
        media.generatedSlug = remoteMedia.generatedSlug
        media.guid = remoteMedia.guid
        media.guidRendered = remoteMedia.guidRendered
        media.link = remoteMedia.link
        media.mediaType = remoteMedia.mediaType
        media.details = remoteMedia.mediaDetails
        media.mimeType = remoteMedia.mimeType
        media.modified = remoteMedia.modified
        media.modifiedGMT = remoteMedia.modifiedGMT
        media.permalinkTemplate = remoteMedia.permalinkTemplate
        media.pingStatus = remoteMedia.pingStatus
        media.postID = remoteMedia.postID
        media.slug = remoteMedia.slug
        media.source = remoteMedia.sourceURL
        media.status = remoteMedia.status
        media.template = remoteMedia.template
        media.title = remoteMedia.title
        media.titleRendered = remoteMedia.titleRendered
        media.type = remoteMedia.type
    }
}
