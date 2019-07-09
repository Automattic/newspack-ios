import Foundation
import WordPressFlux

struct PostsFetchedApiAction: ApiAction {
    var payload: [RemotePost]?
    var error: Error?
    var siteUUID: UUID
    // TOOD: Add meta about the fetch. e.g. offset|page, search, filter, etc.
}

struct PostFetchedApiAction: ApiAction {
    var payload: RemotePost?
    var error: Error?
    var siteUUID: UUID
}

struct PostIDsFetchedApiAction: ApiAction {
    var payload: Any?
    var error: Error?
    var siteUUID: UUID
    var count: Int
    var page: Int
    var hasMore: Bool
}
