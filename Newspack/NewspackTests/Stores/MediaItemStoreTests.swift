import XCTest
import CoreData
@testable import Newspack

class MediaItemStoreTests: BaseTest {

    let remoteMediaEditFile = "remote-media-edit.json"

    var account: Account?
    var site: Site?
    var store: MediaItemStore?

    override func setUp() {
        super.setUp()

        // Test account
        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")

        // Test site
        let context = CoreDataManager.shared.mainContext
        site = ModelFactory.getTestSite(context: context)
        site!.account = account

        CoreDataManager.shared.saveContext(context: context)

        // Test store
        store = MediaItemStore(dispatcher: .global, siteID: site!.uuid)

        let expect = expectation(description: "Default media queries saved.")
        store?.setupDefaultMediaQueriesIfNeeded(siteUUID: site!.uuid, onComplete: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }

    override func tearDown() {
        super.tearDown()

        account = nil
        site = nil
        store = nil
    }

    func testMediaQueryByFilter() {
        let filter = ["media_type": "image" as AnyObject]
        let query = store!.mediaQueryByFilter(filter: filter , siteUUID: site!.uuid)
        XCTAssert(query != nil)
    }

    func testMediaQueryByTitle() {
        let queryName = "images"
        let query = store!.mediaQueryByTitle(title: queryName, siteUUID: site!.uuid)
        XCTAssertNotNil(query)
    }

    func testHandleMediaItemsFetched() {
        guard let response = Loader.jsonObject(for: "remote-media-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }
        let remoteItem = RemoteMediaItem(dict: response)
        let filter = ["media_type": "image" as AnyObject]

        let mediaQuery = store!.mediaQueryByFilter(filter: filter, siteUUID: site!.uuid)
        XCTAssertTrue(mediaQuery!.items.count == 0)

        let action = MediaItemsFetchedApiAction(payload: [remoteItem], error: nil, count: 1, filter: filter, page: 1, hasMore: false)
        store?.handleMediaItemsFetched(action: action)
        let expect1 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            return true
        }
        wait(for: [expect1], timeout: 1)

        XCTAssertTrue(mediaQuery!.items.count == 1)
    }

}
