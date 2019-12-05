import Foundation
import CoreData
import WordPressFlux

class PendingMediaStore: Store {

    private(set) var currentSiteID: UUID?
    private(set) var mediaImporter: StagedMediaImporter?
    private(set) var mediaUploader: StagedMediaUploader?

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID

        super.init(dispatcher: dispatcher)

        guard
            let siteID = siteID,
            let site = StoreContainer.shared.siteStore.getSiteByUUID(siteID) else {
            return
        }
        mediaImporter = StagedMediaImporter(site: site)
        mediaUploader = StagedMediaUploader(site: site)

        if site.stagedMedia.count == 0 {
            mediaImporter?.purgeStagedMediaFiles()
        }
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        if let action = action as? PendingMediaAction {
            switch action {
            case .enqueueMedia(let assetIdentifiers):
                enqueueAssets(identifiers: assetIdentifiers)
            }
        } else if let action = action as? MediaCreatedApiAction {
            if !action.isError() {
                deleteStagedMedia(uuid: action.uuid)
            }
        }
    }

    /// Get existing staged media matching any of the specified PHAsset.identifiers
    /// - Parameter identifiers: An array of PHAsset.identifiers
    ///
    func getStagedMediaMatchingIdentifiers(identifiers: [String]) -> [StagedMedia] {
        guard
            let siteID = currentSiteID,
            let site = StoreContainer.shared.siteStore.getSiteByUUID(siteID)
        else {
            LogError(message: "handleMediaFetchedAction: A value was unexpectedly nil.")
            return [StagedMedia]()
        }

        let context = CoreDataManager.shared.mainContext

        // Remove any duplicates
        let request = StagedMedia.defaultFetchRequest()
        request.predicate = NSPredicate(format: "assetIdentifier IN %@ AND site == %@", identifiers, site)
        do {
            return try context.fetch(request)
        } catch {
            let error = error as NSError
            LogError(message: "getStagedMediaMatchingIdentifiers: " + error.localizedDescription)
        }

        return [StagedMedia]()
    }


    /// Delete the StagedMedia instance for the specified objectID
    /// - Parameter objectID: an NSManagedObjectID for the StagedMedia to delete.
    ///
    func deleteStagedMedia(objectID: NSManagedObjectID) {
        CoreDataManager.shared.performOnWriteContext { (context) in
            let media = context.object(with: objectID)
            context.delete(media)
            CoreDataManager.shared.saveContext(context: context)
        }
    }


    func deleteStagedMedia(uuid: UUID) {
        CoreDataManager.shared.performOnWriteContext { (context) in
            let request = StagedMedia.defaultFetchRequest()
            request.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)

            do {
                if let media = try context.fetch(request).first {
                    context.delete(media)
                    CoreDataManager.shared.saveContext(context: context)
                }
            } catch {
                let err = error as NSError
                LogError(message: "deleteStagedMedia: Error deleting staged media. \(err)")
            }
        }
    }
}

// MARK: - Fetch and Enqueue StagedMedia
extension PendingMediaStore {

    /// Creates a new StagedMedia instance for the specified PHAsset.identifiers.
    /// - Parameter identifiers: An array of PHAsset.identifiers
    ///
    func enqueueAssets(identifiers: [String]) {
        let identifiers = removeDuplicateAssetIdentifiers(identifiers: identifiers)
        createStagedMediaForIdentifiers(identifiers: identifiers)
    }

    /// Removes any identifiers matching assetIdentifiers of existing stagedMedia, returning a new array.
    /// - Parameter identifiers: An array of PHAsset.identifiers
    ///
    func removeDuplicateAssetIdentifiers(identifiers: [String]) -> [String] {
        var filteredIdentifiers = identifiers

        let stagedMedia = getStagedMediaMatchingIdentifiers(identifiers: identifiers)
        let existing = stagedMedia.compactMap({ (item) -> String in
            return item.assetIdentifier!
        })

        filteredIdentifiers = identifiers.filter { (identifier) -> Bool in
            return !existing.contains(identifier)
        }

        return filteredIdentifiers
    }

    /// Creates a new StagedMedia object in core data for each identifier passed.
    /// - Parameters:
    ///   - identifiers: An array of PHAsset.identifiers
    ///
    func createStagedMediaForIdentifiers(identifiers: [String]) {
        guard
            let siteID = currentSiteID,
            let siteObjID = StoreContainer.shared.siteStore.getSiteByUUID(siteID)?.objectID
        else {
            LogError(message: "handleMediaFetchedAction: A value was unexpectedly nil.")
            return
        }

        CoreDataManager.shared.performOnWriteContext { (context) in
            let site = context.object(with: siteObjID) as! Site

            for identifier in identifiers {
                let stagedMedia = StagedMedia(context: context)
                stagedMedia.uuid = UUID()
                stagedMedia.lastModified = Date()
                stagedMedia.assetIdentifier = identifier
                stagedMedia.site = site
            }

            CoreDataManager.shared.saveContext(context: context)
        }
    }

}
