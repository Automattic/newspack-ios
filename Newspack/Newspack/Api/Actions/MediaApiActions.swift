import Foundation
import WordPressFlux

struct MediaFetchedApiAction: ApiAction {
    var payload: RemoteMedia?
    var error: Error?
    var image: UIImage?
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

struct MediaCreatedApiAction: ApiAction {
    var payload: RemoteMedia?
    var error: Error?
    var uuid: UUID
}
