import Foundation
import CoreData
import Photos
import WordPressFlux
import NewspackFramework

/// Responsible for managing asset related things.
///
class AssetStore: Store {

    private let folderManager: FolderManager

    /// Defines a SortOrganizer and its associated SortRules.
    lazy private(set) var sortOrganizer: SortOrganizer = {
        let typeRules: [SortRule] = [
            SortRule(field: "type", displayName: NSLocalizedString("Type", comment: "Noun. The type or category of something."), ascending: false),
            SortRule(field: "date", displayName: NSLocalizedString("Date", comment: "Noun. The date something was created."), ascending: true)
        ]
        let typeSort = SortMode(defaultsKey: "AssetSortModeType",
                                title: NSLocalizedString("Type", comment: "Noun. The title of a list that is sorted by the types of objects in the list."),
                                rules: typeRules,
                                hasSections: true) { (title) -> String in
                                    guard let type = StoryAssetType(rawValue: title) else {
                                        return NSLocalizedString("Unrecognized", comment: "Adjective. Refers to an object that was not an expected type.")
                                    }
                                    return type.displayName()
                                }
        let orderRules: [SortRule] = [
            SortRule(field: "sorted", displayName: NSLocalizedString("Sorted", comment: "Adjective. Refers whether items have been sorted or are unsorted."), ascending: false),
            SortRule(field: "order", displayName: NSLocalizedString("Order", comment: "Noun. Refers to the order or arrangement of items in a list."), ascending: true),
            SortRule(field: "date", displayName: NSLocalizedString("Date", comment: "Noun. The date something was created."), ascending: true)
        ]
        let orderSort = SortMode(defaultsKey: "AssetSortModeOrder",
                                 title: NSLocalizedString("Order", comment: "Noun. Refers to the order or arrangement of items in a list."),
                                 rules: orderRules,
                                 hasSections: true) { (title) -> String in
                                    let sorted = NSLocalizedString("Sorted", comment: "Noun. Refers to items that have been sorted into a specific order or grouping.")
                                    let unsorted = NSLocalizedString("Unsorted", comment: "Noun. Refers to items that have been not been sorted into a specific order or grouping.")
                                    return title == "1" ? sorted : unsorted
                                }
        return SortOrganizer(defaultsKey: "AssetSortOrganizerIndex", modes: [typeSort, orderSort])
    }()

    // TODO: This is a stub for now and will be improved as features are added.
    var allowedExtensions: [String] {
        return ["png", "jpg", "jpeg"]
    }

    /// Whethher the StoryAssets managed by the store can be sorted. This applies
    /// only to the assets wrangled by the SortOrganizer.
    var canSortAssets: Bool {
        // True if the selected sort option is orderSort.
        return sortOrganizer.selectedIndex == 1
    }

    override init(dispatcher: ActionDispatcher = .global) {

        folderManager = SessionManager.shared.folderManager

        super.init(dispatcher: dispatcher)
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        if let action = action as? AssetAction {
            switch action {
            case .sortMode(let index):
                selectSortMode(index: index)
            case .applyOrder(let order):
                applySortOrder(order: order)
            case .createAssetFor(let text):
                createAssetFor(text: text)
            case .deleteAsset(let uuid):
                deleteAsset(assetID: uuid)
            case .importMedia(let assets):
                importMedia(assets: assets)
            case .updateCaption(let assetID, let caption):
                updateCaption(assetID: assetID, caption: caption)
            case .updateAltText(let assetID, let altText):
                updateAltText(assetID: assetID, altText: altText)
            }
        }
    }
}

// MARK: - Actions

extension AssetStore {

    /// Update the sort rules for story assets returned by the stores results controller.
    ///
    /// - Parameter sortMode: The sort mode to sort by.
    ///
    func selectSortMode(index: Int) {
        sortOrganizer.select(index: index)
    }

}

// MARK: - Asset Creation

extension AssetStore {

    /// Create a new TextNote StoryAsset
    ///
    /// - Parameters:
    ///   - text: A string of text.
    ///   - onComplete: A closeure to call when finished.
    ///
    func createAssetFor(text: String, onComplete: (() -> Void)? = nil) {
        guard let folder = StoreContainer.shared.folderStore.currentStoryFolder else {
            LogError(message: "Attempted to create story asset, but a current story folder was not found.")
            onComplete?()
            return
        }
        let name = text.isEmpty ? NSLocalizedString("Text Note", comment: "A short textual note (as opposed to an audio note).") : text
        let objID = folder.objectID
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            guard let self = self else {
                onComplete?()
                return
            }
            let folder = context.object(with: objID) as! StoryFolder
            let asset = self.createAsset(type: .textNote, name: name, url: nil, storyFolder: folder, in: context)
            asset.text = text
            let date = Date()
            asset.modified = date
            asset.synced = date
            CoreDataManager.shared.saveContext(context: context)
            DispatchQueue.main.async {
                onComplete?()
            }
        }
    }

    /// Create new StoryAsset instances for the specified file URLs.
    ///
    /// - Parameters:
    ///   - urls: An array of file URLs.
    ///   - storyFolder: The parent StoryFolder for the new StoryAssets
    ///   - onComplete: A closure to call when finished.
    ///
    func createAssetsForURLs(urls: [URL], storyFolder: StoryFolder, onComplete:(() -> Void)? = nil) {
        // Create the core data proxy for the story asset.
        let objID = storyFolder.objectID
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            guard let self = self else {
                onComplete?()
                return
            }
            let folder = context.object(with: objID) as! StoryFolder

            for url in urls {
                // TODO: There is more to do depending on the type of item.
                // But we'll deal with this as we build out the individual features.
                // For testing purposes we'll default to image for now.
                let _ = self.createAsset(type: .image, name: url.lastPathComponent, url: url, storyFolder: folder, in: context)
            }

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
            }
        }
    }

    /// Create a new StoryAsset.
    ///
    /// - Parameters:
    ///   - type: The type of asset.
    ///   - name: The asset's name.
    ///   - url: The file URL of the asset if there is a corresponding file system object.
    ///   - storyFolder: The asset's StoryFolder.
    ///   - context: A NSManagedObjectContext to use.
    /// - Returns: A new StoryAsset
    ///
    func createAsset(type: StoryAssetType, name: String, url: URL?, storyFolder: StoryFolder, in context: NSManagedObjectContext) -> StoryAsset {
        let asset = StoryAsset(context: context)
        if let url = url {
            asset.bookmark = folderManager.bookmarkForURL(url: url)
        }
        asset.assetType = type
        asset.name = assetName(from: name)
        let date = Date()
        asset.date = date
        asset.modified = date
        asset.synced = date
        asset.uuid = UUID()
        asset.folder = storyFolder

        return asset
    }

    /// Create assets for imported media.
    ///
    /// - Parameters:
    ///   - imports: A dictionary of imported assets. PHAsset IDs are keys.
    ///   - errors: A dictionary of errors. PHAsset IDs are keys.
    ///
    func createAssetsForImports(imports: [String: URL], errors: [String: Error]) {
        guard let storyFolder = StoreContainer.shared.folderStore.currentStoryFolder else {
            return
        }
        if imports.count > 0 {
            createAssetsForURLs(urls: Array(imports.values), storyFolder: storyFolder)
        }
        if errors.count > 0 {
            //TODO: Handle errors
        }
    }

    /// Import the array of PHAssets from PhotoKit to the current StoryFolder
    ///
    /// - Parameter assets: An array of PHAsset instances.
    ///
    func importMedia(assets: [PHAsset]) {
        guard
            let storyFolder = StoreContainer.shared.folderStore.currentStoryFolder,
            let url = SessionManager.shared.folderManager.urlFromBookmark(bookmark: storyFolder.bookmark)
        else {
            LogError(message: "Unable to determine current folder path.")
            return
        }

        let importer = try? MediaImporter(destination: url)
        importer?.importAssets(assets: assets, onComplete: { [weak self] (imported, errors) in
            self?.createAssetsForImports(imports: imported, errors: errors)
        })
    }

}

// MARK: - Asset Modification

extension AssetStore {

    /// Returns the name to use for a story asset based on the supplied string.
    ///
    /// - Parameter string: A string from which to derived the StoryAsset's name.
    /// - Returns: The name for a StoryAsset.
    ///
    func assetName(from string: String) -> String {
        let maxLength = 50 // Fifty is an arbitrary number.
        guard let index = string.index(string.startIndex, offsetBy: maxLength, limitedBy: string.endIndex) else {
            return string
        }

        var str = String(string[..<index])
        if let index = str.lastIndex(of: " ") {
            str = String(str[..<index])
        }

        return str + "..."
    }

    /// Deletes the specified StoryAsset.
    ///
    /// - Parameter assetID: The UUID of the specified StoryAsset.
    ///
    func deleteAsset(assetID: UUID) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }
        deleteAssets(assets: [asset])
    }

    /// Deletes the specified assets and triggers the specified callback.
    ///
    /// - Parameters:
    ///   - assets: An array of StoryAssets to delete.
    ///   - onComplete: A closure to execute when finished, whether successful or not.
    ///
    func deleteAssets(assets: [StoryAsset], onComplete: (() -> Void)? = nil) {
        // For each asset, remove its bookmarked content and then delete.
        var objIDs = [NSManagedObjectID]()
        for asset in assets {
            objIDs.append(asset.objectID)

            guard
                let bookmark = asset.bookmark,
                let url = folderManager.urlFromBookmark(bookmark: bookmark)
            else {
                continue
            }

            // Remove the underlying object
            if !folderManager.deleteItem(at: url) {
                // TODO: For now emit change even if not successful. We'll wire up
                // proper error handling later.
                LogError(message: "Unable to delete the asset at \(url)")
            }
        }

        CoreDataManager.shared.performOnWriteContext { context in
            for objID in objIDs {
                let asset = context.object(with: objID) as! StoryAsset
                context.delete(asset)
            }
            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
            }
        }
    }

    /// Handles StoryAsset's who have media that was deleted remotely.
    /// Neither the StoryAsset nor its local file is deleted. Instead the remoteID
    /// is set to zero. A user may still delete the StoryAsset locally.
    ///
    /// - Parameters:
    ///   - folderIDs: The UUIDs of the folders that have StoryAssets with deleted remote media.
    ///   - remoteIDs: The IDs of the deleted media.
    ///   - onComplete: A block called after changes are saved.
    ///
    func handleDeletedRemoteMedia(for folderIDs: [UUID], remoteIDs: [Int64], onComplete: @escaping () -> Void) {
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let store = StoreContainer.shared.folderStore
            let folders = store.getStoryFoldersForIDs(uuids: folderIDs, context: context)

            if let assets = self?.getStoryAssets(for: folders, with: remoteIDs) {
                for asset in assets {
                    asset.remoteID = 0
                }

                CoreDataManager.shared.saveContext(context: context)
            }

            DispatchQueue.main.async {
                onComplete()
            }
        }
    }

    /// Updates the sort order of the StoryAssets matching the specified UUIDs.
    ///
    /// - Parameter order: A dictionary representing the StoryAssets to update.
    /// Keys should be the asset UUIDs and values should be the desired sort order
    /// for the assets.
    ///
    func applySortOrder(order: [UUID: Int]) {
        CoreDataManager.shared.performOnWriteContext { context in
            for (key, value) in order {
                let fetchRequest = StoryAsset.defaultFetchRequest()
                fetchRequest.predicate = NSPredicate(format: "uuid = %@", key as CVarArg)

                guard let asset = try? context.fetch(fetchRequest).first else {
                    continue
                }

                asset.order = Int16(value)
            }

            CoreDataManager.shared.saveContext(context: context)
        }
    }

    /// Updates the caption of a StoryAsset matching the specified UUID.
    ///
    /// - Parameters:
    ///   - assetID: The UUID of the StoryAsset
    ///   - caption: The text for the caption.
    ///
    func updateCaption(assetID: UUID, caption: String) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }

        let objID = asset.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let asset = context.object(with: objID) as! StoryAsset
            asset.caption = caption
            asset.modified = Date()
            CoreDataManager.shared.saveContext(context: context)
        }
    }

    /// Updates the altText of a StoryAsset matching the specified UUID.
    ///
    /// - Parameters:
    ///   - assetID: The UUID of the StoryAsset
    ///   - altText: The text for the altText.
    ///
    func updateAltText(assetID: UUID, altText: String) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }

        let objID = asset.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let asset = context.object(with: objID) as! StoryAsset
            asset.altText = altText
            asset.modified = Date()
            CoreDataManager.shared.saveContext(context: context)
        }
    }

    /// Update an individual StoryAsset instance with the relevant values from
    /// the specified RemoteMedia. This method DOES NOT save core data.
    /// Ideally the ManagedObject being modified should belong to the write context.
    ///
    /// - Parameters:
    ///   - asset: The StoryAsset to update.
    ///   - remoteMedia: The RemoteMedia to use for the update.
    ///
    func updateAsset(asset: StoryAsset, with remoteMedia: RemoteMedia) {
        // Safety net.  Do not overwrite local changes that are more recent
        // than the remote's last modified date.
        if asset.modified > remoteMedia.modifiedGMT {
            return
        }

        asset.remoteID = remoteMedia.mediaID
        asset.sourceURL = remoteMedia.sourceURL
        asset.link = remoteMedia.link
        asset.name = remoteMedia.title
        asset.altText = remoteMedia.altText
        asset.caption = remoteMedia.caption
        asset.date = remoteMedia.dateGMT
        asset.modified = remoteMedia.modifiedGMT
        asset.synced = Date()
    }

    /// Updates properties for the StoryAssets owned by the specified StoryFolders
    /// with the supplied RemoteMedia. StoryAssets must already have a remoteID set
    /// in order to match with one of the passed RemoteMedia.
    ///
    /// - Parameters:
    ///   - folderIDs: The UUIDs of the StoryFolders that own the StoryAssets.
    ///   - remoteMedia: An array of RemoteMedia.
    ///   - onComplete: A block called after changes are saved.
    ///
    func updateAssets(for folderIDs: [UUID], with remoteMedia: [RemoteMedia], onComplete: @escaping () -> Void) {
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let store = StoreContainer.shared.folderStore
            let folders = store.getStoryFoldersForIDs(uuids: folderIDs, context: context)

            for media in remoteMedia {
                guard let asset = self?.getStoryAsset(for: folders, with: media.mediaID) else {
                    continue
                }
                self?.updateAsset(asset: asset, with: media)
            }

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete()
            }
        }
    }

    /// Updates the remoteID of a StoryAsset matching the specified UUID. The remoteID
    /// should belong to an existing remote media object.
    ///
    /// - Parameters:
    ///   - assetID: The UUID of the StoryAsset to update.
    ///   - remoteID: A RemoteMedia instance.
    ///
    func updateAsset(assetID: UUID, with remoteMedia: RemoteMedia) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }

        let objID = asset.objectID
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let asset = context.object(with: objID) as! StoryAsset

            self?.updateAsset(asset: asset, with: remoteMedia)

            CoreDataManager.shared.saveContext(context: context)
        }
    }

}

// MARK: - Results Controller

extension AssetStore {

    /// Convenience method for getting an NSFetchedResultsController configured
    /// to fetch StoryAssets for the current story folder. It is expected that
    /// this method is only called during a logged in session. If called from a
    /// logged out session an fatal error is raised.
    ///
    /// - Returns: An NSFetchedResultsController instance
    ///
    func getResultsController() -> NSFetchedResultsController<StoryAsset> {
        guard let storyFolder = StoreContainer.shared.folderStore.currentStoryFolder else {
            fatalError()
        }

        let fetchRequest = StoryAsset.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder = %@", storyFolder)
        fetchRequest.sortDescriptors = sortOrganizer.selectedMode.descriptors
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: sortOrganizer.selectedMode.sectionNameKeyPath,
                                          cacheName: nil)
    }
}

// MARK: - Asset Retrieval

extension AssetStore {

    /// Get the StoryAsset that has the specified UUID.
    ///
    /// - Parameter uuid: The UUID of the StoryAsset
    /// - Returns: A StoryAsset or nil.
    ///
    func getStoryAssetByID(uuid: UUID) -> StoryAsset? {
        let fetchRequest = StoryAsset.defaultFetchRequest()
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

    /// Get the assets for the currently selected story folder, sorted by date.
    ///
    /// - Parameter storyFolder: A StoryFolder instance.
    /// - Returns: An array of StoryAssets for the currently selected story folder.
    ///
    func getStoryAssets(storyFolder: StoryFolder) -> [StoryAsset] {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = StoryAsset.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder = %@", storyFolder)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        if let results = try? context.fetch(fetchRequest) {
            return results
        }

        return [StoryAsset]()
    }

    /// Get an array of the remoteIDs for the StoryAssets belonging to the specified StoryFolders.
    ///
    /// - Parameter folder: An array of StoryFolder instances.
    /// - Returns: An array of remote IDs.
    ///
    func getStoryAssetsRemoteIDsForFolders(folders: [StoryFolder]) -> [Int64] {
        var remoteIDs = [Int64]()

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StoryAsset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteID > 0 AND folder IN %@", folders)
        fetchRequest.propertiesToFetch = ["remoteID"]
        fetchRequest.resultType = .dictionaryResultType

        let context = CoreDataManager.shared.mainContext

        guard let results = try? context.fetch(fetchRequest) as? [[String: Int64]] else {
            LogError(message: "Error fetching Asset remoteIDs.")
            return remoteIDs
        }

        for item in results {
            guard let remoteID = item["remoteID"] else {
                continue
            }
            remoteIDs.append(remoteID)
        }

        return remoteIDs
    }

    /// Gets the StoryAsset belonging to the specifie StoryFolder that has the
    /// specified remoteID. The StoryFolder's ManagedObjectContext will be used
    /// for fetching.
    ///
    /// - Parameters:
    ///   - folder: The StoryFolder that owns the StoryAsset.
    ///   - remoteID: The value of the StoryAsset's remoteID.
    /// - Returns: The StoryAsset instance or nil.
    ///
    func getStoryAsset(for folder: StoryFolder, with remoteID: Int64) -> StoryAsset? {
        guard let context =  folder.managedObjectContext else {
            return nil
        }

        let fetchRequest = StoryAsset.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder == %@ AND remoteID == %d", folder, remoteID)

        do {
            return try context.fetch(fetchRequest).first
        } catch {
            let error = error as NSError
            LogError(message: error.localizedDescription)
        }
        return nil
    }

    /// Get the StoryAsset's for the specified StoryFolders that have the specified remoteIDs.
    ///
    /// - Parameters:
    ///   - folders: The StoryFolders that own the StoryAssets.
    ///   - remoteIDs: The remoteIDs that the StoryAssets should have.
    /// - Returns: An array of StoryAssets
    ///
    func getStoryAssets(for folders: [StoryFolder], with remoteIDs: [Int64]) -> [StoryAsset] {
        let assets = [StoryAsset]()
        guard let context = folders.first?.managedObjectContext else {
            return assets
        }

        let fetchRequest = StoryAsset.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder IN %@ AND remoteID IN %@", folders, remoteIDs)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            let error = error as NSError
            LogError(message: error.localizedDescription)
        }
        return assets
    }

    /// Get the StoryAsset from the specified StoryFolders that has the specified remoteID.
    ///
    /// - Parameters:
    ///   - folders: The StoryFolders, one of which owns the StoryAsset.
    ///   - remoteIDs: The remoteID of the StoryAsset.
    /// - Returns: A StoryAsset instance or nil.
    ///
    func getStoryAsset(for folders: [StoryFolder], with remoteID: Int64) -> StoryAsset? {
        guard let context = folders.first?.managedObjectContext else {
            return nil
        }

        let fetchRequest = StoryAsset.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder IN %@ AND remoteID == %d", folders, remoteID)
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            let error = error as NSError
            LogError(message: error.localizedDescription)
        }
        return nil
    }

    /// Get a list of StoryAssets for the specified StoryFolder that have changes
    /// needing to be uploaded.
    ///
    /// - Parameter storyFolder: The StoryFolder that owns the StoryAssets
    /// - Returns: An array of StoryAssets
    ///
    func getStoryAssetsWithChanges(storyFolders: [StoryFolder]) -> [StoryAsset] {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = StoryAsset.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder IN %@ AND modified > synced", storyFolders)
        if let results = try? context.fetch(fetchRequest) {
            return results
        }

        return [StoryAsset]()
    }

    /// Get a list of StoryAssets needing to have their respective media file uploaded.
    ///
    /// - Parameter storyFolder: The StoryFolder that owns the StoryAssets.
    /// - Returns: An array of StoryAssets.
    ///
    func getStoryAssetsNeedingUpload(storyFolder: StoryFolder) -> [StoryAsset] {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = StoryAsset.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder == %@ AND remoteID == 0 AND type != 'text'", storyFolder)
        if let results = try? context.fetch(fetchRequest) {
            return results
        }

        return [StoryAsset]()
    }

}

// MARK: - Sync related

extension AssetStore {

    /// Syncs remote assets for the current site's stories.
    ///
    /// - Parameter onComplete: A block called after syncing is complete,
    /// or if there was an error.
    ///
    func syncRemoteAssets(onComplete: @escaping (Error?) -> Void) {
        let folderStore = StoreContainer.shared.folderStore
        let folders = folderStore.getStoryFoldersWithPosts()
        let folderUUIDs = folders.compactMap { $0.uuid }
        let remoteIDs = getStoryAssetsRemoteIDsForFolders(folders: folders)
        let dispatchGroup = DispatchGroup()
        let remote = MediaServiceRemote(wordPressComRestApi: SessionManager.shared.api)
        var remoteError: Error? = nil

        dispatchGroup.enter()

        remote.fetchMedia(for: remoteIDs) { [weak self] (mediaArray, error) in
            guard let mediaArray = mediaArray else {
                remoteError = error
                LogError(message: "Error fetching remote media: \(error.debugDescription)")
                dispatchGroup.leave()
                return
            }

            // Handle any deleted remote media.
            let fetchedIDs = mediaArray.map { item -> Int64 in
                return item.mediaID
            }
            let missing = Set(remoteIDs).subtracting(fetchedIDs)
            if missing.count > 0 {
                dispatchGroup.enter()
                self?.handleDeletedRemoteMedia(for: folderUUIDs, remoteIDs: Array(missing)) {
                    dispatchGroup.leave()
                }
            }

            self?.updateAssets(for: folderUUIDs, with: mediaArray, onComplete: {
                dispatchGroup.leave()
            })
        }

        dispatchGroup.notify(queue: .main) {
            onComplete(remoteError)
        }
    }

    /// Pushes any changes to the current site's StoryAssets to the site.
    ///
    /// - Parameter onComplete: A block to call when the update is complete.
    ///
    func pushUpdatesToRemote(onComplete: @escaping ([Error]) -> Void) {
        let folderStore = StoreContainer.shared.folderStore
        let folders = folderStore.getStoryFoldersWithPosts()
        let assets = getStoryAssetsWithChanges(storyFolders: folders)
        var remoteErrors = [Error]()

        guard assets.count > 0 else {
            onComplete(remoteErrors)
            return
        }

        let folderUUIDs = folders.compactMap { $0.uuid }
        let remote = MediaServiceRemote(wordPressComRestApi: SessionManager.shared.api)
        let dispatchGroup = DispatchGroup()
        var updatedMedia = [RemoteMedia]()

        for asset in assets {
            dispatchGroup.enter()

            let mediaID = asset.remoteID
            let params = [
                "title": asset.name,
                "caption": asset.caption,
                "alt_text": asset.altText
            ] as [String: AnyObject]

            remote.updateMediaProperties(mediaID: mediaID, mediaParameters: params) { (remoteMedia, error) in
                guard let remoteMedia = remoteMedia else {
                    if let error = error {
                        remoteErrors.append(error)
                    }

                    LogError(message: "Error fetching remote media: \(error.debugDescription)")
                    dispatchGroup.leave()
                    return
                }

                updatedMedia.append(remoteMedia)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard updatedMedia.count > 0 else {
                onComplete(remoteErrors)
                return
            }

            self?.updateAssets(for: folderUUIDs, with: updatedMedia, onComplete: {
                onComplete(remoteErrors)
            })
        }
    }

    /// Upload files and create remote media for any StoryAsset that does not yet
    /// have a remoteID.
    ///
    /// - Parameter onComplete: A block to call when the update is complete.
    ///
    func createRemoteMedia(onComplete: @escaping ([Error]) -> Void) {
        let folderStore = StoreContainer.shared.folderStore
        let folders = folderStore.getStoryFoldersWithPosts()
        let folderManager = SessionManager.shared.folderManager
        let remote = MediaServiceRemote(wordPressComRestApi: SessionManager.shared.api)
        let dispatchGroup = DispatchGroup()
        var remoteErrors = [Error]()

        for folder in folders {
            let assets = getStoryAssetsNeedingUpload(storyFolder: folder)
            guard assets.count > 0 else {
                continue
            }

            for asset in assets {
                guard
                    let bookmark = asset.bookmark,
                    let fileURL = folderManager.urlFromBookmark(bookmark: bookmark),
                    let assetID = asset.uuid
                else {
                    continue
                }

                dispatchGroup.enter()

                let params = [
                    "title": asset.name,
                    "caption": asset.caption,
                    "alt_text": asset.altText
                ] as [String: AnyObject]

                // TODO: Handle mime type in a better fashion
                let progress = remote.createMedia(mediaParameters: params, localURL: fileURL, filename: asset.name, mimeType: "image.jpg") { [weak self] (remoteMedia, error) in
                    dispatchGroup.leave()

                    // TODO: Clean up Progress now that it's finished.

                    guard let remoteMedia = remoteMedia else {
                        if let error = error {
                            remoteErrors.append(error)
                        }
                        return
                    }

                    self?.updateAsset(assetID: assetID, with: remoteMedia)
                }

                if let progress = progress {
                    LogInfo(message: progress.description)
                    // TODO: Implement mechanism to share progress with UI.
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            onComplete(remoteErrors)
        }
    }

}
