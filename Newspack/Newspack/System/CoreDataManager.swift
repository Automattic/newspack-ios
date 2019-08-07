import Foundation
import CoreData

// CoreDataManager is a singleton wrapper around a NSPersistentContainer.
// Its responsible for providing NSManagedObjectContexts and saving contexts.
//
class CoreDataManager {

    // The shared singleton instance of the CoreDataManager.
    //
    static let shared = CoreDataManager()

    // Private lazy constructor for the default internally managed NSPersistentContainer
    //
    private lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Newspack")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // TODO: Rebuild the stack anew.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    /// A convenience method used for tests.
    /// Replaces the default NSPersistentContainer with the one supplied.
    ///
    /// - Parameters:
    ///     - container: An instance of NSPersistentContainer to use instead of the default one.
    ///
    func replaceContainer(_ container: NSPersistentContainer) {
        self.container = container
    }

    // The main NSManagedObjectContext, Its operations are performed on the UI thread.
    // It is a child context of a private background context performing IO.
    //
    public var mainContext: NSManagedObjectContext {
        return container.viewContext
    }

    // A convenience method for performing work in the supplied block on a
    // background thread.
    //
    // Parameters:
    // - block: An anonymous block executed on a background thread.
    //
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            block(context)
        }
    }

    // Returns an NSManagedObjectContext that is a child of the mainContext and
    // is configured to run on a private background queue.
    //
    public func newPrivateChildContext() -> NSManagedObjectContext {
        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = mainContext
        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return childContext
    }

    // Returns an NSManagedObjectContext that is a child of the NSPersistentContainer's
    // private context--a sibling of the public mainContext.
    //
    public func newPrivateContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    // A convenience method for saving the mainContext.
    //
    public func saveContext() {
        saveContext(context: mainContext)
    }

    // Saves the passed NSManagedObjectContext if it has changes.
    //
    // Parameters
    // - context: The NSManagedObjectContext to save.
    //
    public func saveContext(context: NSManagedObjectContext) {
        if context.hasChanges {
            context.performAndWait {
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
}
