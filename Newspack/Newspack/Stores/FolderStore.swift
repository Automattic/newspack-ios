import Foundation
import WordPressFlux

/// Responsible for managing folder related things.
///
class FolderStore: Store {

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

        createAndSetSiteFolderIfNeeded()
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

    /// Creates a folder for the current site if one does not exist. The site
    /// folder contains all story folders so it must exist prior to creating
    /// story folders.
    ///
    private func createAndSetSiteFolderIfNeeded() {
        guard
            let siteID = currentSiteID,
            let site = StoreContainer.shared.siteStore.getSiteByUUID(siteID)
        else {
            return
        }
        // Get a usable site title
        let name = folderNameForSite(site: site)

        guard let url = folderManager.createFolderAtPath(path: name) else {
            fatalError("Unable to create a folder named: \(name)")
        }

        // The FolderManager's currentFolder should _always_ be the site's folder.
        guard folderManager.setCurrentFolder(url: url) else {
            fatalError("Unable to set the folder manager's current folder to \(url.path)")
        }
    }

    /// Get a folder name for the specified site.
    ///
    /// - Parameter site: A Site instance.
    /// - Returns: A string that should be usable as a folder name.
    ///
    func folderNameForSite(site: Site) -> String {
        // Prefer using the URL host + path since this should be unique
        // for every site, and still readable if the user looks at the folder itself.
        if
            let url = URL(string: site.url),
            let host = url.host
        {
            let name = host + url.path
            return sanitizedFolderName(name: name)
        }

        // If for some crazy reason the URL is not available, use the site's UUID.
        // The UUID will be unique, even if it looks like nonsense to the user.
        // We want to avoid using the site's title as this is not guarenteed to
        // be unique and there could be collisions when there are multiple sites.
        // We can be clever later and use the site's title as a directory's
        // display name.
        return site.uuid.uuidString
    }

    /// Sanitize the supplied string to make it suitable to use as a folder name.
    ///
    /// - Parameter name: The string needing to be sanitized.
    /// - Returns: The sanitized version of the string.
    ///
    func sanitizedFolderName(name: String) -> String {
        var sanitizedName = name.replacingOccurrences(of: "/", with: "-")
        sanitizedName = sanitizedName.replacingOccurrences(of: ".", with: "-")
        sanitizedName = sanitizedName.trimmingCharacters(in: CharacterSet.init(charactersIn: "-"))
        return sanitizedName
    }

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
