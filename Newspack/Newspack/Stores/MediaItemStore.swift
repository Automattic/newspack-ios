import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing media item related things.
///
enum MediaItemStoreState {
    case ready
    case syncing
    case changingQuery
}

/// Responsible for wrangling the current media query and other media data.
///
class MediaItemStore: StatefulStore<MediaItemStoreState> {
    private var sessionReceipt: Receipt?

    let pageSize = 100
    let maxPages = 10
    let syncInterval: TimeInterval = 600 // 10 minutes.
    var queue = [Int]()
    private(set) var currentSiteID: UUID?

    var currentQuery: MediaQuery? {
        didSet {
            if oldValue != currentQuery {
                state = .changingQuery
                state = .ready
                sync()
            }
        }
    }

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID
        super.init(initialState: .ready, dispatcher: dispatcher)

        // Listen for session changes in order to seed default lists if necessary.
        // Weak self to avoid strong retains.
        DispatchQueue.main.async { [weak self] in
            self?.sessionReceipt = SessionManager.shared.onChange {
                self?.handleSessionChanged()
            }
            self?.handleSessionChanged()
        }
    }

    /// Action handler
    ///
    /// - Parameter action:
    override func onDispatch(_ action: Action) {
        if let apiAction = action as? MediaItemsFetchedApiAction {
            handleMediaItemsFetched(action: apiAction)
            return
        }

        if let _ = action as? MediaCreatedApiAction {
            LogDebug(message: "Sync first page only")
            sync(force: true, firstPageOnly: true)
            return
        }

        if let action = action as? MediaAction {
            switch action {
            case .syncItems:
                sync()
            case .syncMedia(_):
                break
            }
            return
        }
    }

    /// Convenience method for retrieving the media query for the specified filter.
    ///
    /// - Parameters:
    ///   - filter: The query's filter. This should be unique per site.
    ///   - siteUUID: The uuid of the site that owns the query.
    /// - Returns: The query instance of found, or nil.
    ///
    func mediaQueryByFilter(filter:[String: AnyObject], siteUUID: UUID) -> MediaQuery? {
        let siteStore = StoreContainer.shared.siteStore
        guard let site = siteStore.getSiteByUUID(siteUUID) else {
            return nil
        }
        let fetchRequest = MediaQuery.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "filter == %@ AND site == %@", filter as CVarArg, site)

        let context = CoreDataManager.shared.mainContext
        do {
            guard let query = try context.fetch(fetchRequest).first else {
                return nil
            }
            return query
        } catch {
            // TODO: Handle error
            let error = error as NSError
            LogError(message: "mediaQueryByFilter: " + error.localizedDescription)
            return nil
        }
    }

    func mediaQueryByTitle(title: String, siteUUID: UUID) -> MediaQuery? {
        let siteStore = StoreContainer.shared.siteStore
        guard let site = siteStore.getSiteByUUID(siteUUID) else {
            return nil
        }
        let fetchRequest = MediaQuery.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@ AND site == %@", title, site)

        let context = CoreDataManager.shared.mainContext
        do {
            guard let query = try context.fetch(fetchRequest).first else {
                return nil
            }
            return query
        } catch {
            // TODO: Handle error
            let error = error as NSError
            LogError(message: "mediaQueryByName: " + error.localizedDescription)
            return nil
        }
    }

}

// MARK: - Sync related methods

/// Extension for wrangling API queries.
///
extension MediaItemStore {

    /// Get the number of pages for the specified query that are currently synced
    /// and cached
    ///
    /// - Parameter query: The query in question.
    /// - Returns: The number of pages
    ///
    func numberOfPagesSyncedForQuery(query: MediaQuery) -> Int {
        return Int(ceil(Float(query.items.count) / Float(pageSize)))
    }

    /// Checks to see if enough time has passed since the specified query's last
    /// sync for it to be synced again.
    ///
    /// - Parameter query: The query in question.
    /// - Returns: True if the query can be synced.
    ///
    func timeForNextSyncForQuery(_ query: MediaQuery) -> Bool {
        let now = Date()
        let then = query.lastSync.addingTimeInterval(syncInterval)
        return now > then
    }

    /// Syncs the current query.
    /// Attempts to sync media items for all currently synced pages, or the first
    /// page if there are no currenty synced items.
    /// Checks the date the query was last synced before syncing unless the force
    /// parameter is true.
    ///
    /// - Parameters:
    ///   - force: Whether to force a sync, ignoring the last synced date
    ///   - firstPageOnly: Whether to sync just the first page.
    ///
    func sync(force: Bool = false, firstPageOnly: Bool = false) {
        guard
            let query = currentQuery,
            state != .syncing
        else {
            return
        }

        if !force && !timeForNextSyncForQuery(query) {
            return
        }

        let pages = firstPageOnly ? 1 : numberOfPagesSyncedForQuery(query: query)
        queue = pages > 1 ? [Int](1...pages) : [1]
        queue.reverse()
        syncItemsForQuery(query: query, page: queue.popLast()!)
    }

    /// Sync's the next unsynced page of items.
    ///
    func syncNextPage() {
        guard
            let query = currentQuery,
            query.hasMore
        else {
            return
        }

        let page = numberOfPagesSyncedForQuery(query: query)
        if page < maxPages  {
            syncItemsForQuery(query: query, page: page + 1)
        }
    }

    /// Sync the media items for the specified query.
    ///
    /// - Parameters:
    ///   - query: A MediaQuery instance
    ///   - page: The page to sync. Default is 1.
    ///
    func syncItemsForQuery(query: MediaQuery, page: Int = 1) {
        if state == .syncing {
            return
        }

        state = .syncing

        let service = ApiService.mediaService()
        service.fetchMediaItems(filter: query.filter, page: page)
    }

    /// Handles the MediaItemsFetched action.
    ///
    /// - Parameters:
    ///     - action: Instance of the action to handle.
    ///
    func handleMediaItemsFetched(action: MediaItemsFetchedApiAction) {

        guard
            let siteID = currentSiteID,
            let query = mediaQueryByFilter(filter: action.filter, siteUUID: siteID)
            else {
                // TODO: Handle error.
                LogError(message: "handleMediaItemsFetched: A value was unexpectedly nil.")
                return
        }

        defer {
            state = .ready

            if let page = queue.popLast() {
                syncItemsForQuery(query: query, page: page)
            }
        }

        guard !action.isError() else {
            // TODO: Inspect and handle error.
            // For now assume we're out of pages.
            query.hasMore = action.hasMore
            CoreDataManager.shared.saveContext(context: CoreDataManager.shared.mainContext)
            queue.removeAll()
            return
        }

        guard let remoteItems = action.payload else {
            queue.removeAll()
            LogWarn(message: "handleMediaItemsFetched: A value was unexpectedly nil.")
            return
        }

        let objID = query.objectID
        CoreDataManager.shared.performOnWriteContext { (context) in
            let query = context.object(with: objID) as! MediaQuery
            query.hasMore = remoteItems.count == self.pageSize

            if action.page == 1 {
                query.lastSync = Date()
            }

            for remoteItem in remoteItems {
                let item: MediaItem
                let fetchRequest = MediaItem.defaultFetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%@ IN queries AND mediaID = %ld", query, remoteItem.mediaID)

                do {
                    item = try context.fetch(fetchRequest).first ?? MediaItem(context: context)
                } catch {
                    let error = error as NSError
                    LogError(message: "handleMediaItemsFetched: " + error.localizedDescription)
                    continue
                }

                self.updateMediaItem(item, with: remoteItem)
                item.site = query.site
                query.addToItems(item)
            }
            CoreDataManager.shared.saveContext(context: context)
        }

    }

    /// Update a media item with a corresponding remote media item
    ///
    /// - Parameters:
    ///   - item: the media item to update
    ///   - remoteID: the remote media item
    func updateMediaItem(_ item: MediaItem, with remoteItem: RemoteMediaItem) {
        item.mediaID = remoteItem.mediaID
        item.dateGMT = remoteItem.dateGMT
        item.modifiedGMT = remoteItem.modifiedGMT
        item.mimeType = remoteItem.mimeType
        item.sourceURL = remoteItem.sourceURL
        item.details = remoteItem.mediaDetails
    }
}


// MARK: - Related to the default media queries and their setup.

/// Extension for grouping default media query related things.
///
extension MediaItemStore {

    /// Returns a default list of media item queries for the app.
    ///
    /// - Returns: An array of MediaItemQuery instances.
    ///
    static func defaultMediaQueries() -> Array<MediaItemQuery> {
        return [
            MediaItemQuery(title: "images", filter: ["media_type": "image" as AnyObject])
        ]
    }

    /// Handles session changed events.
    /// Makes to the call to set up default media queries when
    /// a new session is initialized.
    ///
    func handleSessionChanged() {
        guard SessionManager.shared.state == .initialized else {
            currentQuery = nil
            return
        }
        guard
            let siteID = currentSiteID,
            let site = StoreContainer.shared.siteStore.getSiteByUUID(siteID)
            else {
                // TODO: Handle missing site error
                LogError(message: "handleSessionChanged: A value was unexpectedly nil.")
                currentQuery = nil
                return
        }
        setupDefaultMediaQueriesIfNeeded(siteUUID: site.uuid, onComplete: {
            self.currentQuery = site.mediaQueries.first
        })
    }

    /// Checks for the presense of default queries.
    /// Creates any that are missing.
    /// Ideally this should be set up as part of an initial sync.
    ///
    func setupDefaultMediaQueriesIfNeeded(siteUUID: UUID, onComplete: @escaping () -> Void ) {
        let store = StoreContainer.shared.siteStore
        guard let siteObjID = store.getSiteByUUID(siteUUID)?.objectID else {
            // TODO: Handle no site.
            LogError(message: "setupDefaultMediaQueriesIfNeeded: Unable to get site by UUID.")
            return
        }

        CoreDataManager.shared.performOnWriteContext { (context) in
            let site = context.object(with: siteObjID) as! Site
            let fetchRequest = MediaQuery.defaultFetchRequest()

            guard let count = try? context.count(for: fetchRequest) else {
                // TODO: Handle core data error.
                LogError(message: "setupDefaultMediaQueriesIfNeeded: Unable to get count from NSManagedObjectContext.")
                return
            }

            if count > 0 {
                // Nothing to do here.
                return
            }

            for item in MediaItemStore.defaultMediaQueries() {
                let query = MediaQuery(context: context)
                query.uuid = UUID()
                query.title = item.title
                query.filter = item.filter
                query.site = site
            }

            CoreDataManager.shared.saveContext(context: context)
            DispatchQueue.main.async {
                onComplete()
            }
        }
    }
}

struct MediaItemQuery {
    let title: String
    let filter: [String: AnyObject]
}
