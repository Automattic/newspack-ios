import XCTest
import OHHTTPStubs
import WordPressFlux
@testable import Newspack

class MediaServiceTests: RemoteTestCase {

        // Used to retain receipts while fulfilling expectations.
    var receipt: Receipt?

    override func tearDown() {
        super.tearDown()

        receipt = nil
    }


    func testFetchMedia() {
        // Confirm RemoteMedia ad Image are both acquired.
    }

}
