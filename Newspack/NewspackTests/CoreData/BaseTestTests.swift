import XCTest
import CoreData
@testable import Newspack

class BaseTestTests: BaseTest {

    // Confirm that BaseTest successfully configures CoreDataManager to
    // use an in-memory store.
    //
    func testContainerIsInMemoryType() {
        let container = CoreDataManager.shared.createContainer()
        XCTAssertTrue(container.persistentStoreDescriptions.first!.type == NSInMemoryStoreType)
    }

}
