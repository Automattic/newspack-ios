import Foundation
import WordPressFlux

/// Supported Actions for changes to the FolderStore
///
enum AssetAction: Action {
    case selectFolder(folder: URL)
}
