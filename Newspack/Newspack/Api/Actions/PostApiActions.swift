import Foundation
import WordPressFlux

struct PostFetchedApiAction: ApiAction {
    var payload: RemotePost?
    var error: Error?
    var siteUUID: UUID
}

struct PostIDsFetchedApiAction: ApiAction {
    var payload: [RemotePostID]?
    var error: Error?
    var siteUUID: UUID
    var listID: UUID
    var count: Int
    var page: Int
    var hasMore: Bool
}
