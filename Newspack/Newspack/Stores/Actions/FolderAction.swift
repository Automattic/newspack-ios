import Foundation
import WordPressFlux

/// Supported Actions for changes to the FolderStore
///
enum FolderAction: Action {
    case createFolder(path: String, addSuffix: Bool)
    case renameFolder(folder: URL, name: String)
    case deleteFolder(folder: URL)
}
