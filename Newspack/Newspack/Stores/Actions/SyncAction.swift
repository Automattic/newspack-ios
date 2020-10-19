import Foundation
import WordPressFlux

/// Supported Actions for Syncing
///
enum SyncAction: Action {
    case syncAll
    case syncStories
    case syncAssets
}
