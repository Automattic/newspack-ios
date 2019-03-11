import Foundation
import XCTest
import CoreData
@testable import Newspack

extension CoreDataManager {
    func createContainer() -> NSPersistentContainer {

        let container = NSPersistentContainer(name: "Newspack")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }
}

class BaseTest: XCTestCase {

    override func setUp() {

    }

    override func tearDown() {

    }

}
