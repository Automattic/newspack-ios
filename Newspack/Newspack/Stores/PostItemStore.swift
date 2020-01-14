import Foundation
import CoreData
import WordPressFlux

enum PostItemStoreState {
    case ready
    case syncing
    case changingCurrentQuery
}

/// Responsible for wrangling the current post list and other post list data.
///
class PostItemStore: StatefulStore<PostItemStoreState> {
    private var sessionReceipt: Receipt?

    let pageSize = 100
    let maxPages = 10
    let syncInterval: TimeInterval = 600 // 10 minutes.
    var queue = [Int]()
    private(set) var currentSiteID: UUID?

    var currentQuery: PostQuery? {
        didSet {
            if oldValue != currentQuery {
                state = .changingCurrentQuery
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
        if let apiAction = action as? PostIDsFetchedApiAction {
            handlePostIDsFetched(action: apiAction)
        }

        if let action = action as? PostAction {
            switch action {
            case .syncItems(_):
                sync()
            case .syncNextPage:
                syncNextPage()
            case .syncPost(_):
                break
            }
        }
    }

    /// Convenience method for retrieving the post list for the specified filter.
    ///
    /// - Parameters:
    ///   - filter: The lists filter. This should be unique per site.
    ///   - siteUUID: The uuid of the site that owns the list.
    /// - Returns: The list instance of found, or nil.
    ///
    func postQueryByFilter(filter:[String: AnyObject], siteUUID: UUID) -> PostQuery? {
        let siteStore = StoreContainer.shared.siteStore
        guard let site = siteStore.getSiteByUUID(siteUUID) else {
            return nil
        }
        let fetchRequest = PostQuery.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "filter == %@ AND site == %@", filter as CVarArg, site)

        let context = CoreDataManager.shared.mainContext
        do {
            guard let list = try context.fetch(fetchRequest).first else {
                return nil
            }
            return list
        } catch {
            // TODO: Handle error
            let error = error as NSError
            LogError(message: "postQueryByFilter: " + error.localizedDescription)
            return nil
        }
    }

    func postQueryByName(name: String, siteUUID: UUID) -> PostQuery? {
        let siteStore = StoreContainer.shared.siteStore
        guard let site = siteStore.getSiteByUUID(siteUUID) else {
            return nil
        }
        let fetchRequest = PostQuery.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == 'all' AND site == %@", site)

        let context = CoreDataManager.shared.mainContext
        do {
            guard let query = try context.fetch(fetchRequest).first else {
                return nil
            }
            return query
        } catch {
            // TODO: Handle error
            let error = error as NSError
            LogError(message: "postQueryByName: " + error.localizedDescription)
            return nil
        }
    }

}

// MARK: - Sync related methods

/// Extension for wrangling API queries.
///
extension PostItemStore {

    /// Get the number of pages for the specified list that are currently synced
    /// and cached
    ///
    /// - Parameter query: The list in question.
    /// - Returns: The number of pages
    ///
    func numberOfPagesSyncedForQuery(query: PostQuery) -> Int {
        return Int(ceil(Float(query.items.count) / Float(pageSize)))
    }

    /// Checks to see if enough time has passed since the specified list's last
    /// sync for it to be synced again.
    ///
    /// - Parameter query: The list in question.
    /// - Returns: True if the list can be synced.
    ///
    func timeForNextSyncForQuery(_ query: PostQuery) -> Bool {
        let now = Date()
        let then = query.lastSync.addingTimeInterval(syncInterval)
        return now > then
    }

    /// Syncs the current list.
    /// Attempts to sync post items for all currently synced pages, or the first
    /// page if there are no currenty synced items.
    /// Checks the date the list was last synced before syncing unless the force
    /// parameter is true.
    ///
    /// - Parameter force: Whether to force a sync, ignoring the last synced date.
    ///
    func sync(force: Bool = false) {
        guard
            let query = currentQuery,
            state != .syncing
        else {
            return
        }

        if !force && !timeForNextSyncForQuery(query) {
            return
        }

        let pages = numberOfPagesSyncedForQuery(query: query)
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

    /// Sync the post list items for the specified list.
    ///
    /// - Parameters:
    ///   - query: A PostQuery instance
    ///   - page: The page to sync. Default is 1.
    ///
    func syncItemsForQuery(query: PostQuery, page: Int = 1) {
        if state == .syncing {
            return
        }

        state = .syncing

        let service = ApiService.postService()
        service.fetchPostIDs(filter: query.filter, page: page)
    }

    /// Handles the postsFetched action.
    ///
    /// - Parameters:
    ///     - action: Instance of the action to handle.
    ///
    func handlePostIDsFetched(action: PostIDsFetchedApiAction) {

        guard
            let siteID = currentSiteID,
            let query = postQueryByFilter(filter: action.filter, siteUUID: siteID)
            else {
                // TODO: Handle error.
                LogError(message: "handlePostIDsFetched: A value was unexpectedly nil.")
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

        guard let remotePostIDs = action.payload else {
            queue.removeAll()
            LogWarn(message: "handlePostIDsFetched: A value was unexpectedly nil.")
            return
        }

        let queryObjID = query.objectID
        CoreDataManager.shared.performOnWriteContext { (context) in
            let query = context.object(with: queryObjID) as! PostQuery
            query.hasMore = remotePostIDs.count == self.pageSize

            if action.page == 1 {
                query.lastSync = Date()
            }

            for remotePostID in remotePostIDs {
                let item: PostItem
                let fetchRequest = PostItem.defaultFetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%@ IN postQueries AND postID = %ld",query, remotePostID.postID)

                do {
                    item = try context.fetch(fetchRequest).first ?? PostItem(context: context)
                } catch {
                    let error = error as NSError
                    LogError(message: "handlePostIDsFetched: " + error.localizedDescription)
                    continue
                }

                self.updatePostItem(item, with: remotePostID)
                item.site = query.site
                query.addToItems(item)
            }
            CoreDataManager.shared.saveContext(context: context)
        }

    }

    /// Update a post list item with a corresponding remote post id
    ///
    /// - Parameters:
    ///   - item: the post list item to update
    ///   - remoteID: the remote post ID
    func updatePostItem(_ item: PostItem, with remoteID: RemotePostID) {
        item.postID = remoteID.postID
        item.dateGMT = remoteID.dateGMT
        item.modifiedGMT = remoteID.modifiedGMT
        item.revisionCount = remoteID.revisionCount
    }
}


// MARK: - Related to the default post lists and their setup.

/// Extension for grouping default post list related things.
///
extension PostItemStore {

    /// Returns a default list of post lists for the app.
    ///
    /// - Returns: An array of PostListQuery instances.
    ///
    static func defaultPostQueries() -> Array<PostListQuery> {
        return [
            PostListQuery(name: "all", filter: ["status": ["publish","draft","pending","private","future"] as AnyObject])
        ]
    }

    /// Handles session changed events.
    /// Makes to the call to set up default post lists when
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
        setupDefaultPostQueriesIfNeeded(siteUUID: site.uuid, onComplete: {
            self.currentQuery = site.postQueries.first
        })
    }

    /// Checks for the presense of default lists.
    /// Creates any that are missing.
    /// Ideally this should be set up as part of an initial sync.
    ///
    func setupDefaultPostQueriesIfNeeded(siteUUID: UUID, onComplete: @escaping () -> Void ) {
        let store = StoreContainer.shared.siteStore
        guard let siteObjID = store.getSiteByUUID(siteUUID)?.objectID else {
            // TODO: Handle no site.
            LogError(message: "setupDefaultPostQueriesIfNeeded: Unable to get site by UUID.")
            return
        }

        CoreDataManager.shared.performOnWriteContext { (context) in
            let site = context.object(with: siteObjID) as! Site
            let fetchRequest = PostQuery.defaultFetchRequest()

            defer {
                DispatchQueue.main.async {
                    onComplete()
                }
            }
            guard let count = try? context.count(for: fetchRequest) else {
                // TODO: Handle core data error.
                LogError(message: "setupDefaultPostQueriesIfNeeded: Unable to get count from NSManagedObjectContext.")
                return
            }

            if count > 0 {
                // Nothing to do here.
                return
            }

            for item in PostItemStore.defaultPostQueries() {
                let query = PostQuery(context: context)
                query.uuid = UUID()
                query.name = item.name
                query.filter = item.filter
                query.site = site
            }

            CoreDataManager.shared.saveContext(context: context)
        }
    }
}

struct PostListQuery {
    let name: String
    let filter: [String: AnyObject]
}
