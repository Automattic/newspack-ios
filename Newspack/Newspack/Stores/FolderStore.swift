import Foundation
import WordPressFlux

/// Responsible for managing folder related things.
///
class FolderStore: Store, FolderMaker {

    private(set) var currentSiteID: UUID?

    private let folderManager: FolderManager

    /// During normal operation the current story folder will be one of the folders
    /// under the site's folder. Due to the way sessions work and how the FolderStore
    /// is instantiated currentStoryFolder is intializaed to the temp directory,
    /// but updated immediately after.
    ///
    private(set) var currentStoryFolder = FileManager.default.temporaryDirectory

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID

        folderManager = SessionManager.shared.folderManager

        super.init(dispatcher: dispatcher)

        createDefaultStoryFolderIfNeeded()
        selectDefaultStoryFolderIfNeeded()
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        if let action = action as? FolderAction {
            switch action {
            case .createStoryFolder(let path, let addSuffix) :
                createStoryFolder(path: path, addSuffix: addSuffix)
            case .renameStoryFolder(let folder, let name) :
                renameStoryFolder(at: folder, to: name)
            case .deleteStoryFolder(let folder) :
                deleteStoryFolder(at: folder)
            case .selectStoryFolder(let folder) :
                selectStoryFolder(folder: folder)
            }
        }
    }
}

extension FolderStore {

    /// Creates a single, default, folder under the site's folder if there is a
    /// site, and there are currently no folders.
    ///
    private func createDefaultStoryFolderIfNeeded() {
        guard let _ = currentSiteID, listStoryFolders().count == 0 else {
            return
        }
        createStoryFolder()
    }

    /// Select the default story folder if needed.
    ///
    private func selectDefaultStoryFolderIfNeeded() {
        guard
            let _ = currentSiteID,
            !folderManager.currentFolderContains(currentStoryFolder),
            let folder = listStoryFolders().first else {
            return
        }
        selectStoryFolder(folder: folder)
    }

    /// Create a new story folder using the supplied string as its path.
    ///
    /// - Parameters:
    ///   - path: The folder name and (optionally) a path to the story folder.
    ///   - addSuffix: Whether to add a numeric suffix to the folder name if there
    /// is already a folder with that name.
    ///
    func createStoryFolder(path: String = Constants.defaultStoryFolderName, addSuffix: Bool = false) {
        guard let url = folderManager.createFolderAtPath(path: path, ifExistsAppendSuffix: addSuffix) else {
            LogError(message: "Unable to create the folder at \(path)")
            return
        }
        LogDebug(message: "Success: \(url.path)")

        // Update the currentStoryFolder if needed.
        if listStoryFolders().count == 1, let folder = listStoryFolders().first {
            currentStoryFolder = folder
        }

        emitChange()
    }

    func renameStoryFolder(at url: URL, to name: String) {
        if let url = folderManager.renameFolder(at: url, to: name) {
            LogDebug(message: "Success: \(url)")
        }
        // TODO: For now, emit change even if not successful. We'll wire up proper
        // error handling later when we figure out what that looks like.
        emitChange()
    }

    func deleteStoryFolder(at url: URL) {
        if !folderManager.deleteFolder(at: url) {
            // TODO: For now emit change even if not successful. We'll wire up
            // proper error handling later.
            LogError(message: "Unable to delete the folder at \(url)")
        }

        // There should always be at least one folder.
        createDefaultStoryFolderIfNeeded()

        // Update the current story folder if it was the one deleted.
        if url == currentStoryFolder, let folder = listStoryFolders().first {
            currentStoryFolder = folder
        }

        emitChange()
    }

    func listStoryFolders() -> [URL] {
        return folderManager.enumerateFolders(url: folderManager.currentFolder)
    }

    func selectStoryFolder(folder: URL) {
        guard folderManager.currentFolderContains(folder) else {
            return
        }

        currentStoryFolder = folder
        emitChange()
    }

    func listCurrentStoryFolderContents() -> [URL] {
        return folderManager.enumerateFolderContents(url: currentStoryFolder)
    }
}

extension FolderStore {
    private struct Constants {
        static let defaultStoryFolderName = NSLocalizedString("New Story", comment: "Noun. This is the default name given to a new story folder.")
    }
}
