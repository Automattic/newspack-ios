import Foundation
import WordPressFlux

struct PostFetchedApiAction: ApiAction {
    var payload: RemotePost?
    var error: Error?
}

struct PostIDsFetchedApiAction: ApiAction {
    var payload: [RemotePostID]?
    var error: Error?
    var count: Int
    var page: Int
    var hasMore: Bool
}
