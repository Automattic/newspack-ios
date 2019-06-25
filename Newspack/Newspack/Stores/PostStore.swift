import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing post related things
///
class PostStore: EventfulStore {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {

        if let apiAction = action as? PostApiAction {
            switch apiAction {
            case .postsFetched(let posts, let error):
                handlePostsFetched(remotePosts: posts, error: error)
            }
        }

    }

}

extension PostStore {

    /// Handles the postsFetched action.
    ///
    /// - Parameters:
    ///     - remotePosts: The returned remote posts
    ///     - error: Any error.
    ///
    func handlePostsFetched(remotePosts: [RemotePost]?, error: Error?) {
        guard let remotePosts = remotePosts else {
            if let _ = error {
                // TODO: Handle error
            }
            return
        }

        // TODO: This is tightly coupled to the current account and current site.
        // Need to find a way to inject the account and site.
        let accountStore = StoreContainer.shared.accountStore
        guard
            let account = accountStore.currentAccount,
            let site = account.currentSite else {
                return
        }

        let context = CoreDataManager.shared.mainContext

        for remotePost in remotePosts {
            let post: Post
            let fetchRequest = Post.defaultFetchRequest()
            fetchRequest.predicate = NSPredicate(format: "site = %@, postID = %@", site, remotePost.postID)

            do {
                post = try context.fetch(fetchRequest).first ?? Post(context: context)
            } catch {
                // TODO: Propperly log this
                print("Error fetching post")
                continue
            }

            updatePost(post, with: remotePost)
            post.site = site
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
