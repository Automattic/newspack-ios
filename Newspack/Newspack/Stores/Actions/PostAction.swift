import Foundation
import WordPressFlux

/// Supported Actions for changes to the PostStore
///
enum PostAction: Action {
    case syncPosts(posts: [RemotePost], site: Site)
}
