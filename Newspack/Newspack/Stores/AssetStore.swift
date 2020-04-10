import Foundation
import WordPressFlux

/// Responsible for managing folder related things.
///
class AssetStore: Store {

    private(set) var currentSiteID: UUID?

    private let folderManager: FolderManager

    private(set) var selectedFolder: URL?

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID

        folderManager = SessionManager.shared.folderManager

        if let _ = siteID, let folder = StoreContainer.shared.folderStore.listFolders().first {
            selectedFolder = folder
        }

        super.init(dispatcher: dispatcher)
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        if let action = action as? AssetAction {
            switch action {
            case .selectFolder(let folder) :
                selectFolder(folder: folder)
            }
        }
    }
}

extension AssetStore {

    func selectFolder(folder: URL) {
        guard folderManager.folderExists(url: folder) else {
            return
        }
        selectedFolder = folder
        emitChange()
    }

    func listAssets() -> [URL] {
        guard let selectedFolder = selectedFolder else {
            return [URL]()
        }
        return folderManager.enumerateFolderContents(url: selectedFolder)
    }
}
