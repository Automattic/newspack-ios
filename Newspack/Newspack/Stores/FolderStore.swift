import Foundation
import CoreData
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

    /// Warning: We initialize with a random UUID due to the way sessions work.
    /// Durning normal opperation this is updated to an actual StoryFolder's uuid
    /// before it is used.
    private(set) var currentStoryFolderID = UUID()

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
            case .createStoryFolder:
                // Create a story folder with the default name, appending a suffix if needed.
                createStoryFolder(path: Constants.defaultStoryFolderName, addSuffix: true)
            case .createStoryFolderNamed(let path, let addSuffix):
                createStoryFolder(path: path, addSuffix: addSuffix)
            case .renameStoryFolder(let uuid, let name):
                renameStoryFolder(uuid: uuid, to: name)
            case .deleteStoryFolder(let uuid):
                deleteStoryFolder(uuid: uuid)
            case .selectStoryFolder(let uuid):
                selectStoryFolder(uuid: uuid)
            }
        }
    }
}

extension FolderStore {

    /// Convenience method for getting an NSFetchedResultsController configured
    /// to fetch StoryFolders for the current site. It is expected that this method
    /// is only called during a logged in session. If called from a logged out
    /// Session an fatal error is raised.
    ///
    /// - Returns: An NSFetchedResultsController instance
    ///
    func getResultsController() -> NSFetchedResultsController<StoryFolder> {
        guard let siteID = currentSiteID else {
            fatalError()
        }

        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site.uuid = %@", siteID as CVarArg)
        fetchRequest.sortDescriptors = currentSortDescriptors()
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)

    }
}

extension FolderStore {

    /// Creates a single, default, folder under the site's folder if there is a
    /// site, and there are currently no folders.
    ///
    private func createDefaultStoryFolderIfNeeded() {
        guard let _ = currentSiteID, getStoryFolderCount() == 0 else {
            return
        }
        createStoryFolder()
    }

    /// Select the default story folder if needed.
    ///
    private func selectDefaultStoryFolderIfNeeded() {
        guard
            let _ = currentSiteID,
            getStoryFolderByID(uuid: currentStoryFolderID) == nil,
            let storyFolder = getStoryFolders().first
        else {
            return
        }
        selectStoryFolder(uuid: storyFolder.uuid)
    }

    /// Create a new story folder using the supplied string as its path.
    ///
    /// - Parameters:
    ///   - path: The folder name and (optionally) a path to the story folder.
    ///   If a path, only the last path component will be used for the StoryFolder
    ///   name in core data.
    ///   - addSuffix: Whether to add a numeric suffix to the folder name if there
    /// is already a folder with that name.
    ///
    func createStoryFolder(path: String = Constants.defaultStoryFolderName, addSuffix: Bool = false) {
        guard
            let siteID = currentSiteID,
            let siteObjID = StoreContainer.shared.siteStore.getSiteByUUID(siteID)?.objectID
        else {
            LogError(message: "Attempted to create story folder, but no site was found,")
            return
        }

        guard let url = folderManager.createFolderAtPath(path: path, ifExistsAppendSuffix: addSuffix) else {
            LogError(message: "Unable to create the folder at \(path)")
            return
        }
        LogDebug(message: "Success: \(url.path)")

        // Create the core data proxy for the story folder.
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let site = context.object(with: siteObjID) as! Site
            let folderManager = SessionManager.shared.folderManager

            let storyFolder = StoryFolder(context: context)
            storyFolder.uuid = UUID()
            storyFolder.date = Date()
            storyFolder.name = url.pathComponents.last
            storyFolder.site = site
            storyFolder.bookmark = folderManager.bookmarkForURL(url: url)

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                self?.selectDefaultStoryFolderIfNeeded()
            }
        }
    }


    /// Rename a story folder. This updates the name of the story folder's underlying
    /// directory as well as the name field in core data.
    ///
    /// - Parameters:
    ///   - uuid: The uuid of the StoryFolder to update.
    ///   - name: The new name.
    ///
    func renameStoryFolder(uuid: UUID, to name: String) {
        // Get the folder.
        guard let storyFolder = getStoryFolderByID(uuid: uuid) else {
            LogError(message: "Unable to rename story folder")
            return
        }

        // Update the name of its folder. We will assume it is not stale.
        guard
            let url = folderManager.urlFromBookmark(bookmark: storyFolder.bookmark),
            let newUrl = folderManager.renameFolder(at: url, to: name)
        else {
            LogError(message: "Unable to rename story folder")
            return
        }

        LogDebug(message: "Success: \(newUrl)")

        // Save the name in core data.
        let objID = storyFolder.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let folder = context.object(with: objID) as! StoryFolder
            folder.name = name

            CoreDataManager.shared.saveContext(context: context)
        }
    }

    /// Ensure the selected story folder is any folder other than the one listed.
    ///
    /// - Parameter uuid: The uuid of the story folder we do not want selected.
    ///
    func selectStoryOtherThan(uuid: UUID) {
        // If this isn't the currently selected folder then there is nothing to do.
        guard
            currentStoryFolderID == uuid,
            let siteID = currentSiteID
        else {
            return
        }

        let context = CoreDataManager.shared.mainContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StoryFolder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site.uuid = %@", siteID as CVarArg)
        fetchRequest.sortDescriptors = currentSortDescriptors()
        fetchRequest.propertiesToFetch = ["uuid"]
        fetchRequest.resultType = .dictionaryResultType

        guard let results = try? context.fetch(fetchRequest) as? [[String: UUID]] else {
            LogError(message: "Error fetching StoryFolders.")
            return
        }

        guard results.count > 0 else {
            // Nothing to select.
            return
        }

        // Get the index of the storyfolder that's selected.
        guard let index = (results.firstIndex { item -> Bool in
            item["uuid"] == uuid
        }) else { return }

        // Normally we want to select the preceding item.
        var newIndex = index - 1
        // However, if that would be a negative index, we want to select the
        // following item.
        newIndex = max(newIndex, 0)

        selectStoryFolder(uuid: results[newIndex]["uuid"]!)
    }

    /// Delete the specified StoryFolder. This removes the entity from core data
    /// as well as the underlying directory.
    ///
    /// - Parameter uuid: The UUID of the folder.
    ///
    func deleteStoryFolder(uuid: UUID) {
        guard let storyFolder = getStoryFolderByID(uuid: uuid) else {
            LogError(message: "Unable to delete story folder.")
            return
        }

        guard let url = folderManager.urlFromBookmark(bookmark: storyFolder.bookmark) else {
            return
        }

        // If the story folder is the current folder, choose a different folder and select it.
        selectStoryOtherThan(uuid: storyFolder.uuid)

        // Remove the underlying directory
        if !folderManager.deleteFolder(at: url) {
            // TODO: For now emit change even if not successful. We'll wire up
            // proper error handling later.
            LogError(message: "Unable to delete the folder at \(url)")
        }

        // Clean up core data.
        let objID = storyFolder.objectID
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let folder = context.object(with: objID) as! StoryFolder
            context.delete(folder)

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                self?.createDefaultStoryFolderIfNeeded()
            }
        }
    }

    /// Returns an array of StoryFolder instances for the current site.
    /// - Returns: An array of StoryFolder instances.
    ///
    func getStoryFolders() -> [StoryFolder] {
        guard let siteID = currentSiteID else {
            LogError(message: "Attempted to fetch story folders without a current site.")
            return [StoryFolder]()
        }

        let context = CoreDataManager.shared.mainContext
        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site.uuid = %@", siteID as CVarArg)
        fetchRequest.sortDescriptors = currentSortDescriptors()

        if let results = try? context.fetch(fetchRequest) {
            return results
        }

        return [StoryFolder]()
    }

    func currentSortDescriptors() -> [NSSortDescriptor] {
        return [NSSortDescriptor(key: "date", ascending: false)]
    }

    /// Get the number of story folders for the current site.
    ///
    /// - Returns: The number of folders.
    ///
    func getStoryFolderCount() -> Int {
        guard let siteID = currentSiteID else {
            return 0
        }

        let context = CoreDataManager.shared.mainContext
        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site.uuid = %@", siteID as CVarArg)

        if let count = try? context.count(for: fetchRequest) {
            return count
        }

        return 0
    }

    func listStoryFolders() -> [URL] {
        return folderManager.enumerateFolders(url: folderManager.currentFolder)
    }

    func getStoryFolderByID(uuid: UUID) -> StoryFolder? {
        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
        let context = CoreDataManager.shared.mainContext
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            let error = error as NSError
            LogError(message: error.localizedDescription)
        }
        return nil
    }

    /// Set the specified story folder as the selected folder.
    ///
    /// - Parameter uuid: The uuid of the story folder.
    ///
    func selectStoryFolder(uuid: UUID) {
        guard let storyFolder = getStoryFolderByID(uuid: uuid) else {
            LogError(message: "Unable to select story folder.")
            return
        }
        selectStoryFolder(folder: storyFolder)
    }

    /// Set the specified story folder as the selected folder.
    ///
    /// - Parameter uuid: The story folder.
    ///
    func selectStoryFolder(folder: StoryFolder) {
        currentStoryFolderID = folder.uuid
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
