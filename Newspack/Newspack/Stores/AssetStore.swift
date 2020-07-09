import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing asset related things.
///
class AssetStore: Store {

    private let folderManager: FolderManager

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
            case .createAssetFor(let text):
                createAssetFor(text: text)
            case .deleteAsset(let uuid):
                deleteAsset(assetID: uuid)
            }
        }
    }
}

// MARK: - Actions
extension AssetStore {

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

    func deleteAsset(assetID: UUID) {
        guard let asset = getStoryAssetByID(uuid: assetID) else {
            return
        }
        deleteAssets(assets: [asset])
    }

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

        let sortDescriptors = [
            NSSortDescriptor(key: "sorted", ascending: false),
            NSSortDescriptor(key: "order", ascending: true),
            NSSortDescriptor(key: "date", ascending: true)
        ]
        let fetchRequest = StoryAsset.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder = %@", storyFolder)
        fetchRequest.sortDescriptors = sortDescriptors
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: "sorted",
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
