import Foundation
import WordPressFlux

/// Supported Actions for changes to the PostStore
///
enum PostAction: Action {
    case syncItems(force: Bool)
    case syncNextPage
    case syncPost(postID: Int64)
}
