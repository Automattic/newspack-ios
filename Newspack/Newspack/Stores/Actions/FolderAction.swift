import Foundation
import WordPressFlux

/// Supported Actions for changes to the FolderStore
///
enum FolderAction: Action {
    case createFolder(path: String, addSuffix: Bool)
}