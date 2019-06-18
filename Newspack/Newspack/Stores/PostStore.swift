import Foundation
import CoreData
import WordPressFlux

/// Supported Actions for changes to the PostStore
///
enum PostAction: Action {
    case syncPosts(posts: [RemotePost], site: Site)
}

/// Dispatched actions to notifiy subscribers of changes
///
enum PostEvent: Event {
    case postsSynced(error: Error?)
}

/// Errors
///
enum PostError: Error {
    case createPostsSiteMissing
}


/// Responsible for managing post related things
///
class PostStore: EventfulStore {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        guard let postAction = action as? PostAction else {
            return
        }
        switch postAction {
        case .syncPosts(let posts, let site):
            syncPosts(remotePosts: posts, site: site)
        }
    }

}


extension PostStore {

    func syncPosts(remotePosts: [RemotePost], site: Site) {
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

        emitChangeEvent(event: PostEvent.postsSynced(error: nil))
    }


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
