import Foundation
import CoreData
import WordPressFlux

enum PostListState {
    case ready
    case syncing
    case changingCurrentList
}

/// Responsible for wrangling the current post list and other post list data.
///
class PostListStore: StatefulStore<PostListState> {
    private var sessionReceipt: Receipt?

    let pageSize = 100
    let maxPages = 10
    let syncInterval: TimeInterval = 600 // 10 minutes.
    var queue = [Int]()
    private(set) var currentSiteID: UUID?

    var currentList: PostList? {
        didSet {
            if oldValue != currentList {
                state = .changingCurrentList
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
    }

    /// Convenience method for retrieving the post list for the specified filter.
    ///
    /// - Parameters:
    ///   - filter: The lists filter. This should be unique per site.
    ///   - siteUUID: The uuid of the site that owns the list.
    /// - Returns: The list instance of found, or nil.
    ///
    func postListByFilter(filter:[String: AnyObject], siteUUID: UUID) -> PostList? {
        let siteStore = StoreContainer.shared.siteStore
        guard let site = siteStore.getSiteByUUID(siteUUID) else {
            return nil
        }
        let fetchRequest = PostList.defaultFetchRequest()
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
            LogError(message: "postListByFilter: " + error.localizedDescription)
            return nil
        }
    }

    func postListByName(name: String, siteUUID: UUID) -> PostList? {
        let siteStore = StoreContainer.shared.siteStore
        guard let site = siteStore.getSiteByUUID(siteUUID) else {
            return nil
        }
        let fetchRequest = PostList.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == 'all' AND site == %@", site)

        let context = CoreDataManager.shared.mainContext
        do {
            guard let list = try context.fetch(fetchRequest).first else {
                return nil
            }
            return list
        } catch {
            // TODO: Handle error
            let error = error as NSError
            LogError(message: "postListByName: " + error.localizedDescription)
            return nil
        }
    }

}

// MARK: - Sync related methods

/// Extension for wrangling API queries.
///
extension PostListStore {

    /// Get the number of pages for the specified list that are currently synced
    /// and cached
    ///
    /// - Parameter list: The list in question.
    /// - Returns: The number of pages
    ///
    func numberOfPagesSyncedForList(list: PostList) -> Int {
        return Int(ceil(Float(list.items.count) / Float(pageSize)))
    }

    /// Checks to see if enough time has passed since the specified list's last
    /// sync for it to be synced again.
    ///
    /// - Parameter list: The list in question.
    /// - Returns: True if the list can be synced.
    ///
    func timeForNextSyncForList(_ list: PostList) -> Bool {
        let now = Date()
        let then = list.lastSync.addingTimeInterval(syncInterval)
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
    func sync(force:Bool = false) {
        guard
            let list = currentList,
            state != .syncing
        else {
            return
        }

        if !force && !timeForNextSyncForList(list) {
            return
        }

        let pages = numberOfPagesSyncedForList(list: list)
        queue = pages > 1 ? [Int](1...pages) : [1]
        queue.reverse()
        syncItemsForList(list: list, page: queue.popLast()!)
    }

    /// Sync's the next unsynced page of items.
    ///
    func syncNextPage() {
        guard
            let list = currentList,
            list.hasMore
        else {
            return
        }

        let page = numberOfPagesSyncedForList(list: list)
        if page < maxPages  {
            syncItemsForList(list: list, page: page + 1)
        }
    }

    /// Sync the post list items for the specified list.
    ///
    /// - Parameters:
    ///   - list: A PostList instance
    ///   - page: The page to sync. Default is 1.
    ///
    func syncItemsForList(list: PostList, page: Int = 1) {
        if state == .syncing {
            return
        }

        state = .syncing
        CoreDataManager.shared.saveContext()

        let service = ApiService.postService()
        service.fetchPostIDs(filter: list.filter, page: page)
    }

    /// Handles the postsFetched action.
    ///
    /// - Parameters:
    ///     - action: Instance of the action to handle.
    ///
    func handlePostIDsFetched(action: PostIDsFetchedApiAction) {

        guard
            let siteID = currentSiteID,
            let list = postListByFilter(filter: action.filter, siteUUID: siteID)
            else {
                // TODO: Handle error.
                LogError(message: "handlePostIDsFetched: A value was unexpectedly nil.")
                return
        }

        defer {
            state = .ready

            CoreDataManager.shared.saveContext()

            if let page = queue.popLast() {
                syncItemsForList(list: list, page: page)
            }
        }

        guard !action.isError() else {
            // TODO: Inspect and handle error.
            // For now assume we're out of pages.
            list.hasMore = action.hasMore
            queue.removeAll()
            return
        }

        guard let remotePostIDs = action.payload else {
            queue.removeAll()
            LogWarn(message: "handlePostIDsFetched: A value was unexpectedly nil.")
            return
        }

        let context = CoreDataManager.shared.mainContext

        for remotePostID in remotePostIDs {
            let item: PostListItem
            let fetchRequest = PostListItem.defaultFetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%@ IN postLists AND postID = %ld", list, remotePostID.postID)

            do {
                item = try context.fetch(fetchRequest).first ?? PostListItem(context: context)
            } catch {
                let error = error as NSError
                LogError(message: "handlePostIDsFetched: " + error.localizedDescription)
                continue
            }

            updatePostListItem(item, with: remotePostID)
            item.site = list.site
            list.addToItems(item)
        }

        list.hasMore = remotePostIDs.count == pageSize

        if action.page == 1 {
            list.lastSync = Date()
        }
    }

    /// Update a post list item with a corresponding remote post id
    ///
    /// - Parameters:
    ///   - item: the post list item to update
    ///   - remoteID: the remote post ID
    func updatePostListItem(_ item: PostListItem, with remoteID: RemotePostID) {
        item.postID = remoteID.postID
        item.dateGMT = remoteID.dateGMT
        item.modifiedGMT = remoteID.modifiedGMT
        item.revisionCount = remoteID.revisionCount
    }
}


// MARK: - Related to the default post lists and their setup.

/// Extension for grouping default post list related things.
///
extension PostListStore {

    /// Returns a default list of post lists for the app.
    ///
    /// - Returns: An array of PostListQuery instances.
    ///
    static func defaultPostLists() -> Array<PostListQuery> {
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
            currentList = nil
            return
        }
        guard
            let siteID = currentSiteID,
            let site = StoreContainer.shared.siteStore.getSiteByUUID(siteID)
            else {
                // TODO: Handle missing site error
                LogError(message: "handleSessionChanged: A value was unexpectedly nil.")
                currentList = nil
                return
        }
        setupDefaultPostListsIfNeeded(siteUUID: site.uuid)
        currentList = site.postLists.first
    }

    /// Checks for the presense of default lists.
    /// Creates any that are missing.
    /// Ideally this should be set up as part of an initial sync.
    ///
    func setupDefaultPostListsIfNeeded(siteUUID: UUID) {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = PostList.defaultFetchRequest()

        guard let site = StoreContainer.shared.siteStore.getSiteByUUID(siteUUID) else {
            // TODO: Handle no site.
            LogError(message: "setupDefaultPostListsIfNeeded: Unable to get site by UUID.")
            return
        }

        guard let count = try? context.count(for: fetchRequest) else {
            // TODO: Handle core data error.
            LogError(message: "setupDefaultPostListsIfNeeded: Unable to get count from NSManagedObjectContext.")
            return
        }

        if count > 0 {
            // Nothing to do here.
            return
        }

        for item in PostListStore.defaultPostLists() {
            let list = PostList(context: context)
            list.uuid = UUID()
            list.name = item.name
            list.filter = item.filter
            list.site = site
        }

        CoreDataManager.shared.saveContext(context: context)
    }
}

struct PostListQuery {
    let name: String
    let filter: [String: AnyObject]
}
