import Foundation
import WordPressFlux

/// Supported Actions for changes to the MediaItemStore and MediaStore
///
enum MediaAction: Action {
    case syncItems
    case syncMedia(mediaID: Int64)
}

enum PendingMediaAction: Action {
    case enqueueMedia(assetIdentifiers: [String])
}
