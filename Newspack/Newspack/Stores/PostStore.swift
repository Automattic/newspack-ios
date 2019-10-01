import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing post related things.
///
class PostStore: Store {
    typealias Item = Int64

    let requestQueue: RequestQueue<Int64, PostStore>
    private var saveTimer: Timer?
    private var saveTimerInterval: TimeInterval = 1

    private(set) var currentSiteID: UUID?

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID
        requestQueue = RequestQueue<Int64, PostStore>()
        super.init(dispatcher: dispatcher)
        requestQueue.delegate = self
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        if let apiAction = action as? PostFetchedApiAction {
            handlePostFetchedAction(action: apiAction)
        }
    }
}

extension PostStore: RequestQueueDelegate {
    func itemEnqueued(item: Int64) {
        handleItemEnqueued(item: item)
    }
}

extension PostStore {

    func getHighestPostID() -> Int64 {
        guard let siteID = currentSiteID else {
            return 0
        }
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = PostListItem.defaultFetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "site.siteID = @", siteID as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "postID", ascending: false)]

        if let results = try? context.fetch(fetchRequest) {
            if let result = results.first {
                return result.postID
            }
        }
        return 0
    }

    /// Gets the PostListItem from core data for the specified post ID.
    ///
    /// - Parameter postID: The post ID of the item.
    /// - Returns: The model object, or nil if not found.
    ///
    func getPostListItemWithID(postID: Int64) -> PostListItem? {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = PostListItem.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "postID = %ld", postID)
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            // TODO: Handle Error.
            let error = error as NSError
            LogError(message: "getPostListItemWithID: " + error.localizedDescription)
        }
        return nil
    }

    /// Syncs the Post for the spcified post ID if its associated PostListItem if
    /// the post is absent or its data is stale.  Internally this method appends
    /// the post id to a queue of post ids that need to be synced.
    ///
    /// - Parameter postID: The specified post ID
    ///
    func syncPostIfNecessary(postID: Int64) {
        guard let postItem = getPostListItemWithID(postID: postID) else {
            LogWarn(message: "syncPostIfNecessary: Unable to find post list by ID.")
            return
        }

        if postItem.isStale() {
            requestQueue.append(item: postItem.postID)
        }
    }

    /// Handles syncing an enqueued post ID.
    ///
    /// - Parameter item: The post ID of the post to sync
    ///
    func handleItemEnqueued(item: Int64) {
        // TODO: For offline support, when coming back online see if there are enqueued items.
        let service = ApiService.postService()
        service.fetchPost(postID: item)
    }

    /// Handles the dispatched action from the remote post service.
    ///
    /// - Parameter action: The action dispatched by the API
    ///
    func handlePostFetchedAction(action: PostFetchedApiAction) {
        guard !action.isError() else {
            // TODO: Handle error
            if let error = action.error as NSError? {
                LogError(message: "handlePostFetchedAction: " + error.localizedDescription)
            }
            return
        }

        let siteStore = StoreContainer.shared.siteStore

        guard
            let siteID = currentSiteID,
            let site = siteStore.getSiteByUUID(siteID),
            let remotePost = action.payload,
            let listItem = getPostListItemWithID(postID: remotePost.postID)
        else {
            LogError(message: "handlePostFetchedAction: A value was unexpectedly nil.")
            return
        }

        // remove item from queue.
        // This should update the active queue and start the next sync
        requestQueue.remove(item: remotePost.postID)

        let context = CoreDataManager.shared.mainContext
        let fetchRequest = Post.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site = %@ AND postID = %ld", site, remotePost.postID)

        let post: Post
        do {
            post = try context.fetch(fetchRequest).first ?? Post(context: context)
        } catch {
            post = Post(context: context)
            let error = error as NSError
            LogWarn(message: "handlePostFetchedAction: " + error.localizedDescription)
        }

        updatePost(post, with: remotePost)
        post.site = site
        post.item = listItem

        if requestQueue.queue.count == 0 {
            stopSaveTimer()
            CoreDataManager.shared.saveContext()
        }
    }

    /// Update a post with a corresponding remote post
    ///
    /// - Parameters:
    ///   - post: the post to update
    ///   - remotePost: the remote post
    func updatePost(_ post: Post, with remotePost: RemotePost) {
        post.postID = remotePost.postID
        post.authorID = remotePost.authorID
        post.categories = remotePost.categories
        post.commentStatus = remotePost.commentStatus
        post.content = remotePost.content
        post.contentRendered = remotePost.contentRendered
        post.date = remotePost.date
        post.dateGMT = remotePost.dateGMT
        post.excerpt = remotePost.excerpt
        post.excerptRendered = remotePost.excerptRendered
        post.featuredMedia = remotePost.featuredMedia
        post.format = remotePost.format
        post.generatedSlug = remotePost.generatedSlug
        post.guid = remotePost.guid
        post.guidRendered = remotePost.guidRendered
        post.link = remotePost.link
        post.modified = remotePost.modified
        post.modifiedGMT = remotePost.modifiedGMT
        post.password = remotePost.password
        post.permalinkTemplate = remotePost.permalinkTemplate
        post.pingStatus = remotePost.pingStatus
        post.revisionCount = remotePost.revisionCount
        post.slug = remotePost.slug
        post.status = remotePost.status
        post.sticky = remotePost.sticky
        post.tags = remotePost.tags
        post.template = remotePost.template
        post.title = remotePost.title
        post.titleRendered = remotePost.titleRendered
        post.type = remotePost.type
    }
}

// MARK: - Timer methods
/// The timer is part of a performance strategy and is used to limit rapid saves to core data while syncing.
extension PostStore {

    private func startSaveTimer() {
        guard saveTimer == nil else {
            return
        }
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveTimerInterval, repeats: true, block: { _ in
            CoreDataManager.shared.saveContext()
        })
    }

    private func stopSaveTimer() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
}
