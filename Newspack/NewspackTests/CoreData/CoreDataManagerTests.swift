import XCTest
import CoreData
@testable import Newspack

class CoreDataManagerTests: BaseTest {

    // Ensure we're using an in-memory store for tests.
    //
    func testPersistentContainerIsInMemory() {
        guard let type = CoreDataManager.shared.mainContext.persistentStoreCoordinator?.persistentStores.first?.type else {
            XCTFail("Could not retrive the type of the store.")
            return
        }
        XCTAssertTrue(type == NSInMemoryStoreType)
    }

    // Check that blocks are ran on a background thread.
    //
    func testPerformOnWriteContextIsRanInBackground() {
        let expectation = XCTestExpectation(description: "Check if background thread")

        CoreDataManager.shared.performOnWriteContext { _ in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

}
