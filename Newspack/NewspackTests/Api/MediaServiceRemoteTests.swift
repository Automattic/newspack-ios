import XCTest
import OHHTTPStubs
import WordPressFlux
@testable import Newspack

class MediaServiceRemoteTests: RemoteTestCase {

    let remoteMediaEditFile = "remote-media-edit.json"
    let remoteMediasEditFile = "remote-medias-edit.json"
    let previewImage = "preview.png"

    // Used to retain receipts while fulfilling expectations.
    var receipt: Receipt?

    override func tearDown() {
        super.tearDown()

        receipt = nil
    }


    func testFetchMediaItems() {
        let expect = expectation(description: "fetch media")
        stubRemoteResponse("media", filename: remoteMediasEditFile, contentType: .ApplicationJSON)
        let filter = ["media_type": "image"] as [String: AnyObject]
        let remote = MediaServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent") )
        remote.fetchMediaItems(filter: filter, page: 1, perPage: 10) { (result, error) in
            expect.fulfill()
            XCTAssertEqual(result!.count, 10)
        }

        waitForExpectations(timeout: timeout, handler: nil)

    }

    func testFetchMedia() {
        let expect = expectation(description: "fetch media")

        stubRemoteResponse("media", filename: remoteMediaEditFile, contentType: .ApplicationJSON)

        let remote = MediaServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"))
        remote.fetchMedia(mediaID: 1) { (media, error) in
            XCTAssertNotNil(media)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCreateMedia() {
        let expect = expectation(description: "create media")
        stubRemoteResponse("media", filename: remoteMediaEditFile, contentType: .ApplicationJSON)

        let path = Bundle(for: type(of: self)).path(forResource: "preview", ofType: "png")!
        let localURL = URL(fileURLWithPath: path)

        let params = ["title": "Example"] as [String: AnyObject]
        let remote = MediaServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent") )

        remote.createMedia(mediaParameters: params, localURL: localURL, filename: "image.png", mimeType: "image/png") { (media, error) in
            expect.fulfill()
            XCTAssertNotNil(media)
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSanitizeMediaParameters() {
        let startingParams = ["title": "foo", "alt_text": "foo", "caption": "foo", "unsupportedKey": "foo"] as [String: AnyObject];
        let expectedKeys = ["title", "alt_text", "caption"];
        let remote = MediaServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"))
        let sanitizedParams = remote.sanitizeMediaParameters(parameters: startingParams)

        for param in sanitizedParams {
            XCTAssertTrue(expectedKeys.contains(param.key))
        }
    }

    func testRemoteItemsFromResponse() {
        guard let response = Loader.jsonObject(for: "remote-medias-edit") as? [[String: AnyObject]] else {
            XCTAssert(false)
            return
        }

        let remote = MediaServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"))
        let result = remote.remoteItemsFromResponse(response: response)

        XCTAssert(result.count == 10)
    }

    func testRemoteMediaArrayFromResponse() {
        guard let response = Loader.jsonObject(for: "remote-medias-edit") as? [[String: AnyObject]] else {
            XCTAssert(false)
            return
        }

        let remote = MediaServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"))
        let result = remote.remoteMediaArrayFromResponse(response: response)

        XCTAssert(result.count == 10)
    }

    func testRemoteMediaFromResponse() {
        guard let response = Loader.jsonObject(for: "remote-media-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        let remote = MediaServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"))
        let result = remote.remoteMediaFromResponse(response: response)
        let responseID = response["id"] as! Int64
        XCTAssert(result.mediaID == responseID)
    }
}
