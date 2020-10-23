import Foundation
import WordPressFlux

/// Supported Actions for changes to the FolderStore
///
enum FolderAction: Action {
    case sortMode(index: Int)
    case sortDirection(ascending: Bool)
    case createStoryFolder
    case createStoryFolderNamed(path: String, addSuffix: Bool, autoSyncAssets: Bool)
    case updateStoryFolderName(folderID: UUID, name: String)
    case updateStoryFolderAutoSync(folderID: UUID, autoSync: Bool)
    case deleteStoryFolder(folderID: UUID)
    case selectStoryFolder(folderID: UUID)
}
