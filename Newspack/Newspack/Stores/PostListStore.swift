import Foundation
import CoreData
import WordPressFlux


struct PostListQuery {
    let name: String
    let filter: [String: AnyObject]
}

class PostListStore: Store {

    var sessionReceipt: Receipt?

    static func defaultPostLists() -> Array<PostListQuery> {
        return [
            PostListQuery(name: "all", filter: ["status": ["publish","draft","pending","private","future"] as AnyObject])
        ]
    }

    override init(dispatcher: ActionDispatcher = .global) {
        super .init(dispatcher: dispatcher)

        // Listen for session changes
        // Weak self to avoid strong retains.
        DispatchQueue.main.async { [weak self] in
            self?.sessionReceipt = SessionManager.shared.onChange {
                self?.handleSessionChanged()
            }
        }
    }


    override func onDispatch(_ action: Action) {

    }


    func handleSessionChanged() {
        guard SessionManager.shared.state == .initialized else {
            return
        }
        guard let site = StoreContainer.shared.accountStore.currentAccount?.currentSite else {
            // TODO: Handle missing site error
            return
        }
        setupDefaultPostListsIfNeeded(siteUUID: site.uuid)
    }

}

extension PostListStore {


    /// Retrieve remote post items for the list with the specified name.
    ///
    /// - Parameters:
    ///   - listName: The name of the list.
    ///   - The site.
    ///   - page: The page number to sync.
    ///
    func syncItemsForPostListNamed(listName: String, siteUUID: UUID, page: Int = 0) {
        guard let uuid = StoreContainer.shared.accountStore.currentAccount?.currentSite?.uuid else {
            return
        }
        let remote = ApiService.shared.postServiceRemote()
        remote.fetchPosts(siteUUID: uuid)

    }

}


extension PostListStore {

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
            list.name = item.name
            list.filter = item.filter
            list.site = site
        }

        CoreDataManager.shared.saveContext(context: context)
    }
}

