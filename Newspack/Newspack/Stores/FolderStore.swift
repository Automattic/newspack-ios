import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing folder related things.
///
class FolderStore: Store {

    private(set) var currentSiteID: UUID?

    private let folderManager: FolderManager

    /// Warning: We initialize with a random UUID due to the way sessions work.
    /// Durning normal opperation this is updated to an actual StoryFolder's uuid
    /// before it is used.
    private(set) var currentStoryFolderID = UUID()

    lazy private(set) var sortRules: SortRulesBook = {
        return SortRulesBook(storageKey: "FolderStoreSortRules", fields: ["date", "name"], defaults: ["date": false], caseInsensitiveFields: ["name"])
    }()

    /// A convenience getter to get the current story folder.
    ///
    var currentStoryFolder: StoryFolder? {
        getStoryFolderByID(uuid: currentStoryFolderID)
    }

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
            case .sortBy(let field, let ascending):
                sortFolders(by: field, ascending: ascending)
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
        fetchRequest.sortDescriptors = sortRules.descriptors()
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)

    }
}

extension FolderStore {

    /// Update sort rules for folders and refetch data if the sort order has changed.
    ///
    /// - Parameters:
    ///   - field: The field to sort by.
    ///   - ascending: true if the sort order should be ascending, or false if descending.
    ///
    private func sortFolders(by field: String, ascending: Bool) {
        guard !sortRules.hasRule(field: field, ascending: ascending) else {
            return
        }
        var rules = SortRules()
        rules[field] = ascending
        sortRules.setRules(rules: rules)
    }

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
    func createStoryFolder(path: String = Constants.defaultStoryFolderName, addSuffix: Bool = false, onComplete:(()-> Void)? = nil) {
        createStoryFoldersForPaths(paths: [path], addSuffix: addSuffix, onComplete: onComplete)
    }

    /// Create new StoryFolders for each of the specified folder names.
    /// - Parameters:
    ///   - paths: An array of folder name and (optionally) a path to the story folder.
    ///   If a path, only the last path component will be used for the StoryFolder
    ///   name in core data.
    ///   - addSuffix: Whether to add a numeric suffix to the folder name if there
    /// is already a folder with that name.
    ///
    func createStoryFoldersForPaths(paths: [String], addSuffix: Bool = false, onComplete:(()-> Void)? = nil) {
        var urls = [URL]()
        for path in paths {
            guard let url = folderManager.createFolderAtPath(path: path, ifExistsAppendSuffix: addSuffix) else {
                LogError(message: "Unable to create the folder at \(path)")
                continue
            }
            LogDebug(message: "Success: \(url.path)")
            urls.append(url)
        }

        createStoryFoldersForURLs(urls: urls, onComplete: onComplete)
    }

    /// Create new story folders for each of the specified URLs.
    /// - Parameter urls: An array of file URLs
    ///
    func createStoryFoldersForURLs(urls: [URL], onComplete:(()-> Void)? = nil) {
        guard
            let siteID = currentSiteID,
            let siteObjID = StoreContainer.shared.siteStore.getSiteByUUID(siteID)?.objectID
        else {
            LogError(message: "Attempted to create story folders, but no site was found,")
            return
        }

        // Create the core data proxy for the story folder.
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let site = context.object(with: siteObjID) as! Site
            let folderManager = SessionManager.shared.folderManager

            for url in urls {
                let storyFolder = StoryFolder(context: context)
                storyFolder.uuid = UUID()
                storyFolder.date = Date()
                storyFolder.name = url.pathComponents.last
                storyFolder.site = site
                storyFolder.bookmark = folderManager.bookmarkForURL(url: url)
            }

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                self?.selectDefaultStoryFolderIfNeeded()
                onComplete?()
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
    /// - Parameter uuids: The uuids of the story folders we do not want selected.
    ///
    func selectStoryOtherThan(uuids: [UUID]) {
        // If this isn't the currently selected folder then there is nothing to do.
        guard
            uuids.contains(currentStoryFolderID),
            let siteID = currentSiteID
        else {
            return
        }

        // Make an array of uuids without the currently selected one and use this
        // to filter results from our fetch request.
        let uuidsToExclude = uuids.filter { (uuid) -> Bool in
            return uuid != currentStoryFolderID
        }

        let context = CoreDataManager.shared.mainContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StoryFolder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site.uuid = %@ AND NOT (uuid IN %@)", siteID as CVarArg, uuidsToExclude)
        fetchRequest.sortDescriptors = sortRules.descriptors()
        fetchRequest.propertiesToFetch = ["uuid"]
        fetchRequest.resultType = .dictionaryResultType

        guard let results = try? context.fetch(fetchRequest) as? [[String: UUID]] else {
            LogError(message: "Error fetching StoryFolders.")
            return
        }

        guard results.count > 1 else {
            // Nothing new to select.
            return
        }

        // Default to 1 if, for some reason there is not a current selected index found.
        var index = 0
        if let currentSelectedIndex = (results.firstIndex { item -> Bool in
            item["uuid"] == currentStoryFolderID
        }) {
            index = currentSelectedIndex
        }

        // If the index is greater than zero we can just select the preceding item.
        // If the index is zero it means the currently selected story is index zero.
        // In this scenario we want the new index to be 1, so the next item in
        // in the list is selected.
        let newIndex = (index > 0) ? index - 1 : 1
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

        deleteStoryFolders(folders: [storyFolder])
    }

    /// Delete each of the specified story folders.
    ///
    /// - Parameter folders: An array of StoryFolders
    ///
    func deleteStoryFolders(folders: [StoryFolder], onComplete:(()->Void)? = nil) {
        // For each story folder, remove its bookmarked content and then delete.

        let uuids: [UUID] = folders.map { (folder) -> UUID in
            return folder.uuid
        }

        // If the story folder is the current folder, choose a different folder and select it.
        selectStoryOtherThan(uuids: uuids)

        var objIDs = [NSManagedObjectID]()
        for folder in folders {
            objIDs.append(folder.objectID)

            guard let url = folderManager.urlFromBookmark(bookmark: folder.bookmark) else {
                continue
            }

            // Remove the underlying directory
            if !folderManager.deleteFolder(at: url) {
                // TODO: For now emit change even if not successful. We'll wire up
                // proper error handling later.
                LogError(message: "Unable to delete the folder at \(url)")
            }
        }

        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            for objID in objIDs {
                let folder = context.object(with: objID) as! StoryFolder
                context.delete(folder)
            }
            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                self?.createDefaultStoryFolderIfNeeded()
                onComplete?()
            }
        }
    }

    /// Returns an array of StoryFolder instances for the current site.
    ///
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
        fetchRequest.sortDescriptors = sortRules.descriptors()

        if let results = try? context.fetch(fetchRequest) {
            return results
        }

        return [StoryFolder]()
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

}

extension FolderStore {
    private struct Constants {
        static let defaultStoryFolderName = NSLocalizedString("New Story", comment: "Noun. This is the default name given to a new story folder.")
    }
}
