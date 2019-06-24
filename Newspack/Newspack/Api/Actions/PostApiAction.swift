import Foundation
import WordPressFlux

enum PostApiAction: Action {
    case postsFetched(posts: [RemotePost]?, error: Error?)
}
