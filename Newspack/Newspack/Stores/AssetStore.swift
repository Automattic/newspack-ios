import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing asset related things.
///
class AssetStore: Store {

    private let folderManager: FolderManager

    override init(dispatcher: ActionDispatcher = .global) {

        folderManager = SessionManager.shared.folderManager

        super.init(dispatcher: dispatcher)
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {

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
        guard let storyFolder = StoreContainer.shared.folderStore.getCurrentStoryFolder() else {
            fatalError()
        }
        let fetchRequest = StoryAsset.defaultFetchRequest()

        fetchRequest.predicate = NSPredicate(format: "folder = %@", storyFolder)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }
}

extension AssetStore {

    /// Get the assets for the currently selected story folder, sorted by date.
    ///
    /// - Returns: An array of StoryAssets for the currently selected story folder.
    func getStoryAssets() -> [StoryAsset] {
        guard let storyFolder = StoreContainer.shared.folderStore.getCurrentStoryFolder() else {
            fatalError()
        }
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
