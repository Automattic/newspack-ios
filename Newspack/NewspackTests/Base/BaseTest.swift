import Foundation
import XCTest
import CoreData
@testable import Newspack

class BaseTest: XCTestCase {

    var accountStore: AccountStore?

    override func setUp() {
        super.setUp()
        replaceCoreDataStack()

        accountStore = AccountStore(dispatcher: .global, keychainServiceName: "com.automattic.newspack.test")
    }

    override func tearDown() {
        super.tearDown()

        accountStore?.clearAuthTokens()
        accountStore = nil
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

    func getTestAccount() {
        
    }
}
