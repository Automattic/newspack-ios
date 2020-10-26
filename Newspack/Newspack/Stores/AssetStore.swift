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
        let nameStr = NSLocalizedString("Name", comment: "Noun. An item's name.")
        let dateStr = NSLocalizedString("Date", comment: "Noun. The date something was created.")
        let typeStr = NSLocalizedString("Type", comment: "Noun. The type or category of something.")
        let nameRule = SortRule(field: "name", displayName: nameStr, ascending: true, caseInsensitive: true)
        let dateRule = SortRule(field: "date", displayName: dateStr, ascending: true)

        let typeRules = [
            SortRule(field: "type", displayName: typeStr, ascending: false, caseInsensitive: true),
            nameRule,
            dateRule
        ]
        let typeSort = SortMode(defaultsKey: "AssetSortModeType",
                                title: typeStr,
                                rules: typeRules,
                                hasSections: true) { (title) -> String in
                                    guard let type = StoryAssetType(rawValue: title) else {
                                        return NSLocalizedString("Unrecognized", comment: "Adjective. Refers to an object that was not an expected type.")
                                    }
                                    return type.displayName()
                                }
        let dateRules = [dateRule, nameRule]
        let dateSort = SortMode(defaultsKey: "AssetSortModeDate",
                                 title: dateStr,
                                 rules: dateRules,
                                 hasSections: true) { (title) -> String in
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ssZ"
                                    guard let date = formatter.date(from: title) else {
                                        return ""
                                    }

                                    formatter.dateStyle = .medium
                                    formatter.timeStyle = .none

                                    return formatter.string(from: date)
                                }
        return SortOrganizer(defaultsKey: "AssetSortOrganizerIndex", modes: [typeSort, dateSort])
    }()

    // TODO: This is a stub for now and will be improved as features are added.
    var allowedExtensions: [String] {
        return ["png", "jpg", "jpeg"]
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
            case .sortDirection(let ascending):
                setSortDirection(ascending: ascending)
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
            case .flagToUpload(let assetID):
                flagToUpload(assetID: assetID)
            }
        }
    }
}

// MARK: - Sorting

extension AssetStore {

    /// Update the sort rules for story assets returned by the stores results controller.
    ///
    /// - Parameter sortMode: The sort mode to sort by.
    ///
    func selectSortMode(index: Int) {
        sortOrganizer.select(index: index)
    }

    func setSortDirection(ascending: Bool) {
        sortOrganizer.setAscending(ascending: ascending)
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
            let asset = self.createAsset(type: .textNote, name: name, mimeType: "text/plain", url: nil, storyFolder: folder, in: context)
            asset.text = text
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
        let objID = storyFolder.objectID
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let folder = context.object(with: objID) as! StoryFolder

            for url in urls {
                // Get the type based off the fileURLs extension.
                // By convention treat unknown types as images (for now) as this will work for heic files.
                var type: StoryAssetType = .image
                if url.isVideo {
                    type = .video
                } else if url.isAudio {
                    type = .audioNote
                }
                let mime = url.mimeType ?? "application/octet-stream"
                let _ = self?.createAsset(type: type, name: url.lastPathComponent, mimeType: mime, url: url, storyFolder: folder, in: context)
            }

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
            }
        }
    }

    /// Create new StoryAsset instances for the specified ImportedMedia.
    ///
    /// - Parameters:
    ///   - importedMedia: An array of ImportedMedia items.
    ///   - storyFolder: The parent StoryFolder for the new StoryAssets
    ///   - onComplete: A closure to call when finished.
    ///
    func createAssetsForImportedMedia(importedMedia: [ImportedMedia], storyFolder: StoryFolder, onComplete:(() -> Void)? = nil) {
        let objID = storyFolder.objectID
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let folder = context.object(with: objID) as! StoryFolder

            for media in importedMedia {
                // Get the type based off the mime type of the imported asset.
                // By convention treat unknown types as images (for now) as this will work for heic files.
                let type = StoryAssetType.typeFromMimeType(mimeType: media.mimeType) ?? .image
                let _ = self?.createAsset(type: type, name: media.fileURL.lastPathComponent, mimeType: media.mimeType, url: media.fileURL, storyFolder: folder, in: context)
            }

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
                SyncCoordinator.shared.process(steps: [.createRemoteStories, .createRemoteAssets])
            }
        }
    }

    /// Create a new StoryAsset.
    ///
    /// - Parameters:
    ///   - type: The type of asset.
    ///   - name: The asset's name.
    ///   - mimeType: The mimeType for the asset.
    ///   - url: The file URL of the asset if there is a corresponding file system object.
    ///   - storyFolder: The asset's StoryFolder.
    ///   - context: A NSManagedObjectContext to use.
    /// - Returns: A new StoryAsset
    ///
    func createAsset(type: StoryAssetType, name: String, mimeType: String, url: URL?, storyFolder: StoryFolder, in context: NSManagedObjectContext) -> StoryAsset {
        let asset = StoryAsset(context: context)
        if let url = url {
            asset.bookmark = folderManager.bookmarkForURL(url: url)
        }
        asset.assetType = type
        asset.name = assetName(from: name)
        let date = Date()
        // The date field is used for sorting table sections. We only care about the day of the week so normalize the time value.
        asset.date = Calendar(identifier: Calendar.Identifier.iso8601).startOfDay(for: date)
        asset.modified = date
        asset.synced = date
        asset.uuid = UUID()
        asset.mimeType = mimeType
        asset.folder = storyFolder

        return asset
    }

    /// Create assets for imported media.
    ///
    /// - Parameters:
    ///   - imports: A dictionary of imported assets. PHAsset IDs are keys.
    ///   - errors: A dictionary of errors. PHAsset IDs are keys.
    ///
    func createAssetsForImports(imports: [String: ImportedMedia], errors: [String: Error]) {
        guard let storyFolder = StoreContainer.shared.folderStore.currentStoryFolder else {
            return
        }
        if imports.count > 0 {
            createAssetsForImportedMedia(importedMedia: Array(imports.values), storyFolder: storyFolder)
        }
        if errors.count > 0 {
            LogError(message: "Errors Importing Media: \(errors)")
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
    func deleteAsset(assetID: UUID, onComplete: (() -> Void)? = nil) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }
        deleteAssets(assets: [asset], onComplete: onComplete)
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

    /// Updates the caption of a StoryAsset matching the specified UUID.
    ///
    /// - Parameters:
    ///   - assetID: The UUID of the StoryAsset
    ///   - caption: The text for the caption.
    ///
    func updateCaption(assetID: UUID, caption: String, onComplete: (() -> Void)? = nil) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }

        let objID = asset.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let asset = context.object(with: objID) as! StoryAsset
            asset.caption = caption
            asset.modified = Date()
            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
                SyncCoordinator.shared.process(steps: [.pushAssetUpdates])
            }
        }
    }

    /// Updates the altText of a StoryAsset matching the specified UUID.
    ///
    /// - Parameters:
    ///   - assetID: The UUID of the StoryAsset
    ///   - altText: The text for the altText.
    ///
    func updateAltText(assetID: UUID, altText: String, onComplete: (() -> Void)? = nil) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }

        let objID = asset.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let asset = context.object(with: objID) as! StoryAsset
            asset.altText = altText
            asset.modified = Date()
            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
                SyncCoordinator.shared.process(steps: [.pushAssetUpdates])
            }
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
        asset.modified = remoteMedia.modifiedGMT
        asset.synced = Date()
        asset.flagToUpload = false
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
    func updateAsset(assetID: UUID, with remoteMedia: RemoteMedia, onComplete: @escaping () -> Void) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }

        let objID = asset.objectID
        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let asset = context.object(with: objID) as! StoryAsset

            self?.updateAsset(asset: asset, with: remoteMedia)

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete()
            }
        }
    }

    /// Flag an asset for upload.
    ///
    /// - Parameters:
    ///   - assetID: The UUID of the StoryAsset to upload.
    ///   - onComplete: A block called after changes are saved.
    ///
    func flagToUpload(assetID: UUID, onComplete: (() -> Void)? = nil) {
        guard
            let asset = getStoryAssetByID(uuid: assetID),
            asset.assetType != .textNote, // Do not flag text notes.
            asset.remoteID == 0, // Do not flag assets that already have a remote.
            asset.flagToUpload == false // Skip if asset is already flagged.
        else {
            onComplete?()
            return
        }

        let objID = asset.objectID
        CoreDataManager.shared.performOnWriteContext { context in
            let asset = context.object(with: objID) as! StoryAsset

            asset.flagToUpload = true

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
                SyncCoordinator.shared.process(steps: [.createRemoteAssets])
            }
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
    /// The returned assets can belong to any folder for the current site.
    ///
    /// - Parameter limit: The max number of results to return.
    /// - Returns: An array of StoryAssets.
    ///
    func storyAssetsNeedingUpload(limit: Int = 0) -> [StoryAsset] {
        guard
            let currentFolder = StoreContainer.shared.folderStore.currentStoryFolder,
            let site = currentFolder.site
        else {
            return []
        }

        let context = CoreDataManager.shared.mainContext
        let fetchRequest = StoryAsset.defaultFetchRequest()

        let predicateA = NSPredicate(format: "folder.site == %@ AND remoteID == 0 AND type != 'textNote'", site)
        let predicateB = NSPredicate(format: "folder.autoSyncAssets == true OR flagToUpload == true")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateA, predicateB])

        if limit > 0 {
            fetchRequest.fetchLimit = limit
        }
        if let results = try? context.fetch(fetchRequest) {
            return results
        }

        return []
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
    func batchCreateRemoteMedia(batchSize: Int, onComplete: @escaping (Int, [Error]) -> Void) {
        let assets = storyAssetsNeedingUpload(limit: batchSize)
        let count = assets.count
        guard count > 0 else {
            // Nothing to upload.
            onComplete(0, [])
            return
        }

        let folderManager = SessionManager.shared.folderManager
        let remote = MediaServiceRemote(wordPressComRestApi: SessionManager.shared.api)
        let dispatchGroup = DispatchGroup()
        var remoteErrors = [Error]()

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

            let progress = remote.createMedia(mediaParameters: params, localURL: fileURL, filename: asset.name, mimeType: asset.mimeType) { [weak self] (remoteMedia, error) in

                StoreContainer.shared.progressStore.remove(for: assetID)

                guard let remoteMedia = remoteMedia else {
                    if let error = error {
                        remoteErrors.append(error)
                        dispatchGroup.leave()
                    }
                    return
                }

                self?.updateAsset(assetID: assetID, with: remoteMedia, onComplete: {
                    dispatchGroup.leave()
                })
            }

            if let progress = progress {
                StoreContainer.shared.progressStore.add(progress: progress, for: assetID)
            }
        }

        dispatchGroup.notify(queue: .main) {
            onComplete(count, remoteErrors)
        }
    }

}
