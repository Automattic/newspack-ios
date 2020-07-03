import Foundation
import WordPressFlux

/// Supported Actions for changes to the FolderStore
///
enum FolderAction: Action {
    case sortBy(field: String, ascending: Bool)
    case createStoryFolder
    case createStoryFolderNamed(path: String, addSuffix: Bool)
    case renameStoryFolder(folderID: UUID, name: String)
    case deleteStoryFolder(folderID: UUID)
    case selectStoryFolder(folderID: UUID)
}
