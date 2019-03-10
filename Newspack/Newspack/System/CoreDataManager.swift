import Foundation
import CoreData

// PersistentContainerManager is a protocol specifying a single method for
// creating and returning an NSPersistentContainer.
// This protocol, and its default extension, is used to define a default
// NSPersistentContainer for CoreDataManager that can be overridden by
// tests that provide their own implementation via an extension to
// CoreDataManager.
//
protocol PersistentContainerManager {

    // Create and return an NSPersistentContainer.
    //
    func createContainer() -> NSPersistentContainer
}

// A protocol extension providing a default implementation of the createContainer
// method.
//
extension PersistentContainerManager {
    private var name: String {
        return "Newspack"
    }

    func createContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }
}

// CoreDataManager is a singleton wrapper around a NSPersistentContainer.
// Its responsible for providing NSManagedObjectContexts and saving contexts.
//
class CoreDataManager: PersistentContainerManager {

    // The shared singleton instance of the CoreDataManager.
    //
    static let shared = CoreDataManager()

    // Private lazy constructor for the internally managed NSPersistentContainer
    //
    private lazy var container: NSPersistentContainer = {
        return createContainer()
    }()

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
    // - block: An anonymous block exectued on a background thread.
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

    // Returns an NSManagedObjectContext that is a child of the NSPersistentContiner's
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
