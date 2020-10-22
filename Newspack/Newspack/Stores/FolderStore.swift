import Foundation
import CoreData
import WordPressFlux
import NewspackFramework

/// Responsible for managing folder related things.
///
class FolderStore: Store {

    private(set) var currentSiteID: UUID?

    private let folderManager: FolderManager

    /// Warning: We initialize with a random UUID due to the way sessions work.
    /// Durning normal opperation this is updated to an actual StoryFolder's uuid
    /// before it is used.
    private(set) var currentStoryFolderID = UUID()

    lazy var sortRules: [SortRule] = {
        let dateField = "date"
        let nameField = "name"
        return [
            SortRule(field: dateField, displayName: displayNameForField(field: dateField), ascending: true),
            SortRule(field: nameField, displayName: displayNameForField(field: nameField), ascending: true)
        ]
    }()

    lazy private(set) var sortMode: SortMode = {
        let rule = sortRules.first!
        return SortMode(defaultsKey: "FolderStoreSortMode", title: "", rules: [rule], hasSections: false, resolver: nil)
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
            case .createStoryFolderNamed(let path, let addSuffix, let autoSync):
                createStoryFolder(path: path, addSuffix: addSuffix, autoSyncAssets: autoSync)
            case .updateStoryFolderName(let uuid, let name):
                updateStoryFolderName(uuid: uuid, to: name)
            case .updateStoryFolderAutoSync(let uuid, let autoSync):
                updateStoryFolderAutoSync(uuid: uuid, to: autoSync)
            case .deleteStoryFolder(let uuid):
                deleteStoryFolder(uuid: uuid)
            case .selectStoryFolder(let uuid):
                selectStoryFolder(uuid: uuid)
            }
        }
    }
}

// MARK: - Results Controller

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
        fetchRequest.sortDescriptors = sortMode.descriptors
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)

    }
}

// MARK: - Sorting

extension FolderStore {

    /// Update sort rules for folders and refetch data if the sort order has changed.
    ///
    /// - Parameters:
    ///   - field: The field to sort by.
    ///   - ascending: true if the sort order should be ascending, or false if descending.
    ///
    private func sortFolders(by field: String, ascending: Bool) {
        let rule = SortRule(field: field, displayName: displayNameForField(field: field), ascending: ascending)
        sortMode.setRules(newRules: [rule])
    }

    /// Get the user facing display name to use for the specified field.
    ///
    /// - Parameter field: The name of the sort field.
    /// - Returns: The user facing String or an empty string if the specified field was not found.
    ///
    private func displayNameForField(field: String) -> String {
        if field == "name" {
            return NSLocalizedString("Name", comment: "Noun. An item's name.")
        }
        if field == "date" {
            return NSLocalizedString("Date", comment: "Noun. An item's creation date.")
        }
        return ""
    }

}

// MARK: - Story Folder Creation

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

    /// Create a new story folder using the supplied string as its path.
    ///
    /// - Parameters:
    ///   - path: The folder name and (optionally) a path to the story folder.
    ///   If a path, only the last path component will be used for the StoryFolder
    ///   name in core data.
    ///   - addSuffix: Whether to add a numeric suffix to the folder name if there
    /// is already a folder with that name.
    ///   - autoSyncAssets: True if the folder's assets should automatically sync when added. False otherwise.
    ///   - onComplete: A block to call when creation is complete.
    ///
    func createStoryFolder(path: String = Constants.defaultStoryFolderName, addSuffix: Bool = false, autoSyncAssets: Bool = true, onComplete:(()-> Void)? = nil) {
        createStoryFoldersForPaths(paths: [path], addSuffix: addSuffix, autoSyncAssets: autoSyncAssets, onComplete: onComplete)
    }

    /// Create new StoryFolders for each of the specified folder names.
    /// - Parameters:
    ///   - paths: An array of folder name and (optionally) a path to the story folder.
    ///   If a path, only the last path component will be used for the StoryFolder
    ///   name in core data.
    ///   - addSuffix: Whether to add a numeric suffix to the folder name if there
    /// is already a folder with that name.
    ///   - autoSyncAssets: True if the folder's assets should automatically sync when added. False otherwise.
    ///   - onComplete: A block to call when creation is complete.
    ///
    func createStoryFoldersForPaths(paths: [String], addSuffix: Bool = false, autoSyncAssets: Bool = true, onComplete:(()-> Void)? = nil) {
        var urls = [URL]()
        for path in paths {
            guard let url = folderManager.createFolderAtPath(path: path, ifExistsAppendSuffix: addSuffix) else {
                LogError(message: "Unable to create the folder at \(path)")
                continue
            }
            LogDebug(message: "Success: \(url.path)")
            urls.append(url)
        }

        createStoryFoldersForURLs(urls: urls, autoSyncAssets: autoSyncAssets, onComplete: onComplete)
    }

    /// Create new story folders for each of the specified URLs.
    ///
    /// - Parameters:
    ///   - urls: An array of file URLs
    ///   - autoSyncAssets: True if the folder's assets should automatically sync when added. False otherwise.
    ///   - onComplete: A block to call when creation is complete.
    ///
    func createStoryFoldersForURLs(urls: [URL], autoSyncAssets: Bool, onComplete:(()-> Void)? = nil) {
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
                let date = Date()
                let storyFolder = StoryFolder(context: context)
                storyFolder.uuid = UUID()
                storyFolder.synced = date
                storyFolder.modified = date
                storyFolder.name = url.pathComponents.last
                storyFolder.site = site
                storyFolder.bookmark = folderManager.bookmarkForURL(url: url)
                storyFolder.autoSyncAssets = autoSyncAssets
            }

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                self?.selectDefaultStoryFolderIfNeeded()
                onComplete?()
                ShadowCaster.shared.castShadows()
                SyncCoordinator.shared.process(steps: [.createRemoteStories])
            }
        }
    }

}

// MARK: - Story Folder Selection

extension FolderStore {

    /// Select the default story folder if needed.
    ///
    private func selectDefaultStoryFolderIfNeeded() {
        // Make sure there are story folders to retrieve.
        guard
            let _ = currentSiteID,
            getStoryFolderByID(uuid: currentStoryFolderID) == nil,
            let firstFolder = getStoryFolders().first
        else {
            return
        }

        let folder = getLastSelectedStoryFolder() ?? firstFolder
        selectStoryFolder(uuid: folder.uuid)
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
        fetchRequest.sortDescriptors = sortMode.descriptors
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
        if let siteID = currentSiteID {
            let key = AppConstants.lastSelectedStoryFolderKey + siteID.uuidString
            UserDefaults.shared.set(folder.uuid.uuidString, forKey: key)
        }
        currentStoryFolderID = folder.uuid
        emitChange()
    }

}

// MARK: - Story Folder Retrieval

extension FolderStore {

    /// Get the last selected story folder if one exists.
    ///
    /// - Returns: A StoryFolder instance or nil.
    ///
    func getLastSelectedStoryFolder() -> StoryFolder? {
        guard let siteID = currentSiteID else {
            return nil
        }

        let key = AppConstants.lastSelectedStoryFolderKey + siteID.uuidString
        guard
            let uuidString = UserDefaults.shared.string(forKey: key),
            let uuid = UUID(uuidString: uuidString),
            let storyFolder = getStoryFolderByID(uuid: uuid)
        else {
            return nil
        }

        return storyFolder
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
        fetchRequest.sortDescriptors = sortMode.descriptors

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

    /// Get the StoryFolder that has the specified UUID.
    ///
    /// - Parameter uuid: The UUID of the StoryFolder.
    /// - Returns: The StoryFolder instance or nil.
    ///
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

    /// Get the StoryFolders that have the specified UUIDs.
    ///
    /// - Parameters:
    ///   - uuids: The UUIDs of the StoryFolders.
    ///   - context: The NSManagedObjectContext to fetch from.
    /// - Returns: An array of StoryFolders.
    ///
    func getStoryFoldersForIDs(uuids: [UUID], context: NSManagedObjectContext) -> [StoryFolder] {
        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid IN %@", uuids)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            let error = error as NSError
            LogError(message: error.localizedDescription)
        }
        return []
    }

    /// Get a list of the post IDs for stories that have backing drafts.
    ///
    /// - Returns: An array of integers.
    ///
    func getStoryFolderPostIDs() -> [Int64] {
        var postIDs = [Int64]()
        guard let siteID = currentSiteID else {
            LogError(message: "Attempted to fetch story folders without a current site.")
            return postIDs
        }

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StoryFolder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "postID > 0 AND site.uuid = %@", siteID as CVarArg)
        fetchRequest.propertiesToFetch = ["postID"]
        fetchRequest.resultType = .dictionaryResultType

        let context = CoreDataManager.shared.mainContext

        guard let results = try? context.fetch(fetchRequest) as? [[String: Int64]] else {
            LogError(message: "Error fetching Story postIDs.")
            return postIDs
        }

        for item in results {
            guard let postID = item["postID"] else {
                continue
            }
            postIDs.append(postID)
        }

        return postIDs
    }

    /// Get the story folder for the current site that has the specified postID.
    ///
    /// - Parameter postID: A post ID.
    /// - Returns: A StoryFolder instance or nil if there was no match.
    ///
    func getStoryFolder(for postID: Int64) -> StoryFolder? {
        guard let siteID = currentSiteID else {
            LogError(message: "Attempted to fetch story folders without a current site.")
            return nil
        }

        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "postID == %d AND site.uuid = %@", postID, siteID as CVarArg)
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

    /// Get an array of StoryFolders that need a remote draft to be created.
    ///
    /// - Returns: An array of StoryFolders.
    ///
    func getStoryFoldersNeedingRemote() -> [StoryFolder] {
        let folders = [StoryFolder]()
        guard let siteID = currentSiteID else {
            LogError(message: "Attempted to fetch story folders without a current site.")
            return folders
        }

        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "postID == 0 AND assets.@count > 0 AND site.uuid = %@", siteID as CVarArg)

        let context = CoreDataManager.shared.mainContext
        do {
            return try context.fetch(fetchRequest)
        } catch {
            let error = error as NSError
            LogError(message: error.localizedDescription)
        }

        return folders
    }

    /// Get an array of StoryFolders that have changes needing to be synced.
    /// StoryFolders that do not have a remote post are not included.
    ///
    /// - Returns: An array of story folders.
    ///
    func getStoryFoldersWithChanges() -> [StoryFolder] {
        let folders = [StoryFolder]()
        guard let siteID = currentSiteID else {
            LogError(message: "Attempted to fetch story folders without a current site.")
            return folders
        }

        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "modified > synced AND postID > 0 AND site.uuid = %@", siteID as CVarArg)

        let context = CoreDataManager.shared.mainContext
        do {
            return try context.fetch(fetchRequest)
        } catch {
            let error = error as NSError
            LogError(message: error.localizedDescription)
        }

        return folders
    }

    /// Get an array of StoryFolders for the current site that have existing remote posts.
    ///
    /// - Returns: An array of StoryFolders.
    ///
    func getStoryFoldersWithPosts() -> [StoryFolder] {
        let folders = [StoryFolder]()
        guard let siteID = currentSiteID else {
            LogError(message: "Attempted to fetch story folders without a current site.")
            return folders
        }

        let fetchRequest = StoryFolder.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "postID > 0 AND site.uuid = %@", siteID as CVarArg)

        let context = CoreDataManager.shared.mainContext
        do {
            return try context.fetch(fetchRequest)
        } catch {
            let error = error as NSError
            LogError(message: error.localizedDescription)
        }

        return folders
    }

}

// MARK: - Story Folder Modification

extension FolderStore {

    /// Rename a story folder. This updates the name of the story folder's underlying
    /// directory as well as the name field in core data.
    ///
    /// - Parameters:
    ///   - uuid: The uuid of the StoryFolder to update.
    ///   - name: The new name.
    ///
    func updateStoryFolderName(uuid: UUID, to name: String, onComplete: (() -> Void)? = nil) {
        // Get the folder.
        guard let storyFolder = getStoryFolderByID(uuid: uuid) else {
            LogError(message: "Unable to find the story folder to rename.")
            onComplete?()
            return
        }

        // Update the name of its folder. We will assume it is not stale.
        guard
            let url = folderManager.urlFromBookmark(bookmark: storyFolder.bookmark),
            let newUrl = folderManager.renameFolder(at: url, to: name)
        else {
            LogError(message: "Unable to rename story folder")
            onComplete?()
            return
        }

        LogInfo(message: "Success: \(newUrl)")

        // Save the name in core data.
        let objID = storyFolder.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let folder = context.object(with: objID) as! StoryFolder
            folder.name = name
            folder.modified = Date()

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
                SyncCoordinator.shared.process(steps: [.pushStoryUpdates])
            }
        }
    }

    func updateStoryFolderAutoSync(uuid: UUID, to autoSyncAssets: Bool, onComplete: (() -> Void)? = nil) {
        // Get the folder.
        guard let storyFolder = getStoryFolderByID(uuid: uuid) else {
            LogError(message: "Unable to find the story folder to update.")
            onComplete?()
            return
        }

        // Save the name in core data.
        let objID = storyFolder.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let folder = context.object(with: objID) as! StoryFolder
            folder.autoSyncAssets = autoSyncAssets

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
                if autoSyncAssets {
                    SyncCoordinator.shared.process(steps: SyncSteps.assetSteps())
                }
            }
        }
    }

    /// After creating a draft post, associate the post ID to its StoryFolder.
    ///
    /// - Parameters:
    ///   - postID: A post ID.
    ///   - folderID: The uuid of the StoryFolder to update.
    ///
    func assignPostIDAfterCreatingDraft(postID: Int64, to folderID: UUID, onComplete: (() -> Void)? = nil) {
        guard let folder = getStoryFolderByID(uuid: folderID) else {
            return
        }

        let objID = folder.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let folder = context.object(with: objID) as! StoryFolder
            folder.postID = postID

            let date = Date()
            folder.synced = date
            folder.modified = date

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
            }
        }
    }

    /// After syncing a story folder, update its synced date.
    ///
    /// - Parameter folderID: The UUID of the StoryFolder
    ///
    func updateSyncedDate(for folderID: UUID, onComplete:(() -> Void)? = nil) {
        guard let folder = getStoryFolderByID(uuid: folderID) else {
            return
        }

        let objID = folder.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let folder = context.object(with: objID) as! StoryFolder

            folder.synced = Date()

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
            }
        }
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
    func deleteStoryFolders(folders: [StoryFolder], onComplete:(() -> Void)? = nil) {
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
                ShadowCaster.shared.castShadows()
            }
        }
    }

}

// MARK: - Syncing related

extension FolderStore {

    /// Syncs post data for StoryFolders that have a remote post (i.e. their postID
    /// is not zero). Processes returned remote draft data.
    ///
    /// - Parameter onComplete: A block that is called when syncing and processing
    /// is complete or if there is an error.
    ///
    func syncAndProcessRemoteDrafts(onComplete: @escaping (Error?) -> Void) {
        let postIDs = getStoryFolderPostIDs()
        let perPage = min(postIDs.count, 100)

        // Sync the posts for these POST IDs.
        let remote = PostServiceRemote(wordPressComRestApi: SessionManager.shared.api)
        remote.fetchPostStubs(for: postIDs, page: 1, perPage: perPage) { [weak self] (postStubs, error) in
            guard let stubs = postStubs else {
                LogError(message: "Error fetching post stubs.")
                onComplete(error)
                return
            }

            self?.processRemoteDrafts(postStubs: stubs, onComplete: onComplete)
        }
    }

    /// Processes synced data from remote drafts.
    ///
    /// - Parameters:
    ///   - postStubs: An array of RemotePostStubs representing the synced data.
    ///   - onComplete: A block that is called when syncing and processing
    /// is complete or if there is an error.
    ///
    func processRemoteDrafts(postStubs: [RemotePostStub], onComplete: @escaping (Error?) -> Void) {
        var foldersToRemove = [StoryFolder]()

        let processGroup = DispatchGroup()
        // For each post stub
        for stub in postStubs {
            guard let folder = getStoryFolder(for: stub.postID) else {
                continue
            }

            if Constants.finishedStatuses.contains(stub.status) {
                foldersToRemove.append(folder)
                continue
            }

            if stub.titleRendered != folder.name && !folder.needsSync {
                processGroup.enter()
                updateStoryFolderName(uuid: folder.uuid, to: stub.titleRendered, onComplete: {
                    processGroup.leave()
                })
            }
        }

        processGroup.enter()
        deleteStoryFolders(folders: foldersToRemove, onComplete: {
            processGroup.leave()
        })

        processGroup.notify(queue: .main) {
            onComplete(nil)
        }
    }

    /// Create remote drafts for any stories that need one created.
    ///
    /// - Parameter onComplete: A block that is called when complete or if there
    /// is an error.
    ///
    func createRemoteDraftsIfNeeded(onComplete: @escaping (Error?) -> Void) {
        let folders = getStoryFoldersNeedingRemote()
        let processGroup = DispatchGroup()
        var hasError = false

        for folder in folders {
            processGroup.enter()
            createRemoteDraft(for: folder, onComplete: { error in
                if let _ = error {
                    hasError = true
                }
                processGroup.leave()
            })
        }

        processGroup.notify(queue: .main) {
            let error = hasError ? FolderSyncError.errorPushingRemoteUpdates : nil
            onComplete(error)
        }
    }

    /// Creates a remote draft for the specified story folder.
    /// - Parameters:
    ///   - storyFolder: The story folder needing a remote draft created.
    ///   - onComplete: A block that is called when complete or if there
    /// is an error.
    ///
    func createRemoteDraft(for storyFolder: StoryFolder, onComplete: @escaping (Error?) -> Void) {
        let uuid = storyFolder.uuid!
        let params = [
            "title": storyFolder.name,
            "status": "draft",
            ] as [String: AnyObject]
        let remote = PostServiceRemote(wordPressComRestApi: SessionManager.shared.api)
        remote.createPost(postParams: params) { (remotePost, error) in
            guard let remotePost = remotePost else {
                LogError(message: "Error creating a remote draft for a story: \(error.debugDescription)")
                onComplete(error)
                return
            }
            self.assignPostIDAfterCreatingDraft(postID: remotePost.postID, to: uuid, onComplete: {
                onComplete(nil)
            })
        }
    }

    /// Pushes any changes to StoryFolders to the remote site.
    ///
    /// - Parameter onComplete: A block that is called when complete or if there
    /// is an error.
    ///
    func pushUpdatesToRemote(onComplete: @escaping (Error?) -> Void) {
        let folders = getStoryFoldersWithChanges()
        let processGroup = DispatchGroup()
        var hasError = false

        for folder in folders {
            processGroup.enter()
            syncChangesForFolder(folder: folder) { (error) in
                if let _ = error {
                    hasError = true
                }
                processGroup.leave()
            }
        }

        processGroup.notify(queue: .main) {
            let error = hasError ? FolderSyncError.errorCreatingDrafts : nil
            onComplete(error)
        }
    }

    /// Syncs changes to the specified story folder to the remote site.
    ///
    /// - Parameters:
    ///   - folder: The StoryFolder to sync.
    ///   - onComplete: A block that is called when complete or if there
    /// is an error.
    ///
    func syncChangesForFolder(folder: StoryFolder, onComplete: @escaping (Error?) -> Void) {
        let uuid = folder.uuid!
        let remote = PostServiceRemote(wordPressComRestApi: SessionManager.shared.api)
        let params = [
            "title": folder.name
        ] as [String: AnyObject]

        remote.updatePost(postID: folder.postID, postParams: params) { (remotePost, error) in
            guard let _ = remotePost else {
                LogError(message: "Error updating a remote draft for a story: \(error.debugDescription)")
                onComplete(error)
                return
            }

            self.updateSyncedDate(for: uuid)
        }
    }
}

extension FolderStore {
    private struct Constants {
        static let defaultStoryFolderName = NSLocalizedString("New Story", comment: "Noun. This is the default name given to a new story folder.")
        static let finishedStatuses = ["publish", "future", "spam", "trash"]
    }
}

enum FolderSyncError: Error {
    case errorCreatingDrafts
    case errorPushingRemoteUpdates
}
