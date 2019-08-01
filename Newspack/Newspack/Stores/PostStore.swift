import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing post related things
///
class PostStore: Store {
    typealias Item = Int64

    let requestQueue: RequestQueue<Int64, PostStore>

    override init(dispatcher: ActionDispatcher = .global) {
        requestQueue = RequestQueue<Int64, PostStore>()
        super.init(dispatcher: dispatcher)
        requestQueue.delegate = self
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {

        if let apiAction = action as? PostsFetchedApiAction {
            handlePostsFetched(action: apiAction)

        } else if let apiAction = action as? PostFetchedApiAction {
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

    func getPostListItemWithID(postID: Int64) -> PostListItem? {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = PostListItem.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "postID = %ld", postID)
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            // TODO: Handle Error.
        }
        return nil
    }

    func syncPostIfNecessary(postID: Int64) {
        guard let postItem = getPostListItemWithID(postID: postID) else {
            return
        }

        if postItem.isStale() {
            // Add to queue
            requestQueue.append(item: postItem.postID)
        }
    }

    func handleItemEnqueued(item: Int64) {
        // TODO: For offline support, when coming back online see if there are enqueued items.
        guard let uuid = StoreContainer.shared.accountStore.currentAccount?.currentSite?.uuid else {
            return
        }

        let remote = ApiService.shared.postServiceRemote()
        remote.fetchPost(postID: item, fromSite: uuid)
    }

    func handlePostFetchedAction(action: PostFetchedApiAction) {
        guard !action.isError() else {
            // TODO: Handle error
            return
        }

        let siteStore = StoreContainer.shared.siteStore

        guard
            let site = siteStore.getSiteByUUID(action.siteUUID),
            let remotePost = action.payload,
            let listItem = getPostListItemWithID(postID: remotePost.postID)
        else {
            // TODO: Unknown error?
            return
        }

        // remove item from queue.
        // This should update the active queue and start the next sync
        requestQueue.remove(item: remotePost.postID)

        let context = CoreDataManager.shared.mainContext

        let post: Post
        let fetchRequest = Post.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site = %@ AND postID = %ld", site, remotePost.postID)

        do {
            post = try context.fetch(fetchRequest).first ?? Post(context: context)
        } catch {
            post = Post(context: context)
            // TODO: Propperly log this
            print("Error fetching post")
        }

        updatePost(post, with: remotePost)
        post.site = site
        post.addToItems(listItem)

        CoreDataManager.shared.saveContext()
    }

    func syncPosts() {
        guard let uuid = StoreContainer.shared.accountStore.currentAccount?.currentSite?.uuid else {
            return
        }
        let remote = ApiService.shared.postServiceRemote()
        remote.fetchPosts(siteUUID: uuid)
    }

    /// Handles the postsFetched action.
    ///
    /// - Parameters:
    ///     - action: Instance of the action to handle.
    ///
    func handlePostsFetched(action: PostsFetchedApiAction) {
        guard !action.isError() else {
            // TODO: Handle error.
            return
        }

        let siteStore = StoreContainer.shared.siteStore

        guard
            let site = siteStore.getSiteByUUID(action.siteUUID),
            let remotePosts = action.payload
        else {
            // TODO: Unknown error?
            return
        }

        let context = CoreDataManager.shared.mainContext

        for remotePost in remotePosts {
            let post: Post
            let fetchRequest = Post.defaultFetchRequest()
            fetchRequest.predicate = NSPredicate(format: "site = %@ AND postID = %ld", site, remotePost.postID)

            do {
                post = try context.fetch(fetchRequest).first ?? Post(context: context)
            } catch {
                // TODO: Propperly log this
                print("Error fetching post")
                continue
            }

            updatePost(post, with: remotePost)
            post.site = site
            if let listItem = getPostListItemWithID(postID: remotePost.postID) {
                post.addToItems(listItem)
            }
        }

        CoreDataManager.shared.saveContext()
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
