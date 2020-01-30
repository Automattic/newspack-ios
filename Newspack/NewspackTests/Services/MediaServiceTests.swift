import XCTest
import OHHTTPStubs
import WordPressFlux
@testable import Newspack

class MediaServiceTests: RemoteTestCase {

    let remoteMediaEditFile = "remote-media-edit.json"
    let previewImage = "preview.png"

    // Used to retain receipts while fulfilling expectations.
    var receipt: Receipt?

    override func tearDown() {
        super.tearDown()

        receipt = nil
    }


    func testFetchMedia() {
        // Confirm RemoteMedia ad Image are both acquired.
        let expect = expectation(description: "fetch media")
        receipt = testDispatcher.subscribe { action in
            defer {
                expect.fulfill()
            }
            guard let mediaAction = action as? MediaFetchedApiAction else {
                XCTAssert(false)
                return
            }

            XCTAssertFalse(mediaAction.isError())
            XCTAssertTrue(mediaAction.payload != nil)
            XCTAssertTrue(mediaAction.image != nil)
        }

        stubRemoteResponse("media", filename: remoteMediaEditFile, contentType: .ApplicationJSON)
        stubRemoteResponse("preview.png", filename: previewImage, contentType: .imagePNG)

        let remote = MediaApiService(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"), dispatcher: testDispatcher )
        remote.fetchMedia(mediaID: 1, having: "http://example.com/preview.png")

        waitForExpectations(timeout: timeout, handler: nil)

    }

}
