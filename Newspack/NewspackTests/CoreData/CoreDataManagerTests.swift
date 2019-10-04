import XCTest
import CoreData
@testable import Newspack

class CoreDataManagerTests: BaseTest {

    // Check that the context is a private sibling of the public main context.
    //
    func testPrivateContextIsSiblingOfMainContext() {
        let context = CoreDataManager.shared.newPrivateContext()

        XCTAssertTrue(context.parent == CoreDataManager.shared.mainContext.parent)
        XCTAssertTrue(context.concurrencyType == .privateQueueConcurrencyType)
    }

    // Check that blocks are ran on a background thread.
    //
    func testPerformBackgroundTaskIsRanInBackground() {
        let expectation = XCTestExpectation(description: "Check if background thread")

        CoreDataManager.shared.performBackgroundTask { _ in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
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
