import Foundation
import WordPressFlux

/// Supported Actions for changes to the MediaItemStore and MediaStore
///
enum MediaAction: Action {
    case syncItems(force: Bool)
    case syncMedia(mediaID: Int64)
}

enum StagedMediaAction: Action {
    case enqueueMedia(assetIdentifiers: [String])
}
