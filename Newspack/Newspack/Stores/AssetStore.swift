import Foundation
import CoreData
import Photos
import WordPressFlux

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
                break
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
            let asset = self.createAsset(name: name, url: nil, storyFolder: folder, in: context)
            asset.text = text
            asset.assetType = .textNote
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
                let asset = self.createAsset(name: url.lastPathComponent, url: url, storyFolder: folder, in: context)
                // TODO: There is more to do depending on the type of item.
                // But we'll deal with this as we build out the individual features.
                // For testing purposes we'll default to image for now.
                asset.assetType = .image
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
    ///   - name: The asset's name.
    ///   - url: The file URL of the asset if there is a corresponding file system object.
    ///   - storyFolder: The asset's StoryFolder.
    ///   - context: A NSManagedObjectContext to use.
    /// - Returns: A new StoryAsset
    ///
    func createAsset(name: String, url: URL?, storyFolder: StoryFolder, in context: NSManagedObjectContext) -> StoryAsset {
        let asset = StoryAsset(context: context)
        if let url = url {
            asset.bookmark = folderManager.bookmarkForURL(url: url)
        }
        asset.name = assetName(from: name)
        asset.date = Date()
        asset.uuid = UUID()
        asset.folder = storyFolder

        return asset
    }

    /// Retursn the name to use for a story asset based on the supplied string.
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

    /// Import the array of PHAssets from PHotoKit to the current StoryFolder
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
        importer?.importAssets(assets: assets)
    }

}

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

extension AssetStore {

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
    /// - Parameter storyFolder: storyFolder description
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
}
