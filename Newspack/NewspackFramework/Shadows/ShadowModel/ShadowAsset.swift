import Foundation

/// Stores select information about an asset.
/// Facilitates storage in shared defautls.
///
public struct ShadowAsset {
    public let storyUUID: String // The UUID of the destination story folder.
    public let bookmarkData: Data

    public var dictionary: [String: Any] {
        return [
            ModelConstants.uuid: storyUUID,
            ModelConstants.bookmarkData: bookmarkData
        ]
    }

    public init(storyUUID: String, bookmarkData: Data) {
        self.storyUUID = storyUUID
        self.bookmarkData = bookmarkData
    }

    public init(dict: [String: Any]) {
        guard
            let uuid = dict[ModelConstants.uuid] as? String,
            let bookmarkData = dict[ModelConstants.bookmarkData] as? Data
        else {
            // This should never happen.
            fatalError()
        }
        self.storyUUID = uuid
        self.bookmarkData = bookmarkData
    }

}
