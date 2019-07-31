import XCTest
@testable import Newspack

class RequestQueueTests: XCTestCase {

    func testRequestQueue() {
        // Setup
        class Delegate: RequestQueueDelegate {
            var item = 0
            func itemEnqueued(item: Any) {
                self.item = item as! Int
            }
        }
        let delegate = Delegate()
        let queue = RequestQueue<Int>()
        queue.delegate = delegate

        // Test that the delgate is called when an item is enqueued.
        queue.append(item: 1)
        XCTAssert(delegate.item == 1)

        // Test that adding the same item does not lengthen the queue.
        queue.append(item: 1)
        queue.append(item: 1)
        queue.append(item: 1)
        XCTAssert(queue.queue.count == 1)

        // Test that the active queue size is constrained.
        queue.append(item: 2)
        queue.append(item: 3)
        queue.append(item: 4)
        XCTAssert(queue.queue.count == 4)
        XCTAssert(queue.activeQueue.count == 3)

        // Ensure the items appened above the max were not enqueued.
        XCTAssert(delegate.item == 3)

        // Test that removing an active item, will make the next item active.
        queue.remove(item: 1)
        // queue and active queue should now be 2,3,4 and the delegate's item should be 4.
        XCTAssert(delegate.item == 4)
        XCTAssert(queue.queue == queue.activeQueue)

    }


}
