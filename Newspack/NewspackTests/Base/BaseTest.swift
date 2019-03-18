import Foundation
import XCTest
import CoreData
@testable import Newspack

class BaseTest: XCTestCase {

    override func setUp() {
        super.setUp()
        replaceCoreDataStack()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// Replaces the default core data stack with one that is in-memory.
    ///
    func replaceCoreDataStack() {
        let container = NSPersistentContainer(name: "Newspack")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        CoreDataManager.shared.replaceContainer(container)
    }
}
