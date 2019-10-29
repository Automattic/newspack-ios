import Foundation
import WordPressFlux

struct MediaFetchedApiAction: ApiAction {
    var payload: RemoteMedia?
    var image: UIImage?
    var error: Error?
    var previewURL: String
    var mediaID: Int64
}

struct MediaItemsFetchedApiAction: ApiAction {
    var payload: [RemoteMediaItem]?
    var error: Error?
    var count: Int
    var filter: [String: AnyObject]
    var page: Int
    var hasMore: Bool
}
