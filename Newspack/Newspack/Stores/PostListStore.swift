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

    var currentList: PostList? {
        didSet {
            if oldValue != currentList {
                state = .changingCurrentList
                state = .ready
                // TODO: sync if needed
            }
        }
    }

    var sessionReceipt: Receipt?

    override init(initialState: PostListState = .ready, dispatcher: ActionDispatcher = .global) {
        super.init(initialState: initialState, dispatcher: dispatcher)

        // Listen for session changes in order to seed default lists if necessary.
        // Weak self to avoid strong retains.
        DispatchQueue.main.async { [weak self] in
            self?.sessionReceipt = SessionManager.shared.onChange {
                self?.handleSessionChanged()
            }
            self?.handleSessionChanged()
        }
    }

    override func onDispatch(_ action: Action) {

        if let apiAction = action as? PostIDsFetchedApiAction {
            handlePostIDsFetched(action: apiAction)
        }

    }

    /// Convenience method for retrieving the specified post list.
    ///
    /// - Parameters:
    ///   - listID: The uuid of the list
    ///   - siteUUID: The uuid of the site that owns the list.
    /// - Returns: The list instance of found, or nil.
    ///
    func postListByIdentifier(listID: UUID, siteUUID: UUID) -> PostList? {
        let fetchRequest = PostList.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", listID as CVarArg)

        let context = CoreDataManager.shared.mainContext
        do {
            guard
                let list = try context.fetch(fetchRequest).first,
                list.site.uuid == siteUUID
            else {
                return nil
            }
            return list
        } catch {
            // TODO: Handle error
            return nil
        }
    }

}

// MARK: - Syncing

/// Extension for wrangling API queries.
///
extension PostListStore {

    /// Retrieve remote post items for the list with the specified name.
    ///
    /// - Parameters:
    ///   - page: The page number to sync. Default is 1.
    ///
    func syncItems(page: Int = 1) {
        guard let list = currentList else {
            return
        }
        syncItemsForList(list: list, page: page)
    }

    /// Sync the post list items for the specified list.
    ///
    /// - Parameters:
    ///   - list: A PostList instance
    ///   - page: The page to sync. Default is 1.
    ///
    func syncItemsForList(list: PostList, page: Int = 1) {
        list.syncing = true
        state = .syncing
        CoreDataManager.shared.saveContext()

        let remote = ApiService.shared.postServiceRemote()
        remote.fetchPostIDs(filter: list.filter, page: page, siteUUID: list.site.uuid, listID: list.uuid)

    }

    /// Handles the postsFetched action.
    ///
    /// - Parameters:
    ///     - action: Instance of the action to handle.
    ///
    func handlePostIDsFetched(action: PostIDsFetchedApiAction) {
        guard let list = postListByIdentifier(listID: action.listID, siteUUID: action.siteUUID) else {
            //TODO: handle error.
            return
        }

        list.syncing = false
        state = .ready

        defer {
            CoreDataManager.shared.saveContext()
        }

        guard !action.isError() else {
            // TODO: Handle error.
            return
        }

        guard let remotePostIDs = action.payload else {
            // TODO: Unknown error?
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
                // TODO: Propperly log this
                print("Error fetching post list item")
                continue
            }

            updatePostListItem(item, with: remotePostID)
            list.addToItems(item)
        }

        list.lastSync = Date()
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
        guard let site = StoreContainer.shared.accountStore.currentAccount?.currentSite else {
            // TODO: Handle missing site error
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
            return
        }

        guard let count = try? context.count(for: fetchRequest) else {
            // TODO: Handle core data error.
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

