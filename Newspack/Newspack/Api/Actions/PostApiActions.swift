import Foundation
import WordPressFlux

struct PostsFetchedApiAction: ApiAction {
    var payload: [RemotePost]?
    var error: Error?
    var siteUUID: UUID
    // TOOD: Add meta about the fetch. e.g. offset|page, search, filter, etc.
}
