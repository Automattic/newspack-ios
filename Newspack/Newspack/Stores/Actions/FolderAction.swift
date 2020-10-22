import Foundation
import WordPressFlux

/// Supported Actions for changes to the FolderStore
///
enum FolderAction: Action {
    case sortBy(field: String, ascending: Bool)
    case createStoryFolder
    case createStoryFolderNamed(path: String, addSuffix: Bool, autoSyncAssets: Bool)
    case updateStoryFolder(folderID: UUID, name: String, autoSyncAssets: Bool)
    case deleteStoryFolder(folderID: UUID)
    case selectStoryFolder(folderID: UUID)
}
