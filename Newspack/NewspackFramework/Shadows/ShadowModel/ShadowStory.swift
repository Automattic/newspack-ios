import Foundation

/// Stores select information about a story.
/// Facilitates storage in shared defautls.
///
public struct ShadowStory {
    public let uuid: String
    public let title: String
    public let bookmarkData: Data

    public var dictionary: [String: Any] {
        return [
            ModelConstants.uuid: uuid,
            ModelConstants.title: title,
            ModelConstants.bookmarkData: bookmarkData
        ]
    }

    public init(uuid: String, title: String, bookmarkData: Data) {
        self.uuid = uuid
        self.title = title
        self.bookmarkData = bookmarkData
    }

    public init(dict: [String: Any]) {
        guard
            let uuid = dict[ModelConstants.uuid] as? String,
            let title = dict[ModelConstants.title] as? String,
            let bookmarkData = dict[ModelConstants.bookmarkData] as? Data
        else {
            // This should never happen.
            fatalError()
        }
        self.uuid = uuid
        self.title = title
        self.bookmarkData = bookmarkData
    }

}
