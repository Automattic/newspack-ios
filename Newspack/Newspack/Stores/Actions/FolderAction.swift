import Foundation
import WordPressFlux

/// Supported Actions for changes to the FolderStore
///
enum FolderAction: Action {
    case createStoryFolder(path: String, addSuffix: Bool)
    case renameStoryFolder(folder: URL, name: String)
    case deleteStoryFolder(folder: URL)
    case selectStoryFolder(folder: URL)
}
