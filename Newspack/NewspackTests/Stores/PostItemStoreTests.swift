import XCTest
import CoreData
@testable import Newspack

class PostItemStoreTests: BaseTest {

    var account: Account?
    var site: Site?
    var store: PostItemStore?

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
        store = PostItemStore(dispatcher: testDispatcher, siteID: site!.uuid)

        let expect = expectation(description: "Default post queries saved.")
        store?.setupDefaultPostQueriesIfNeeded(siteUUID: site!.uuid, onComplete: {
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

    func testPostQueryByFilter() {
        let filter = ["status": ["publish","draft","pending","private","future"] as AnyObject]
        let query = store!.postQueryByFilter(filter: filter , siteUUID: site!.uuid)
        XCTAssert(query != nil)
    }

    func testPostQueryByName() {
        let queryName = "all"
        let query = store!.postQueryByName(name: queryName, siteUUID: site!.uuid)
        XCTAssertNotNil(query)
    }

    func testHandlePostItemsFetched() {
        guard let response = Loader.jsonObject(for: "remote-post-id-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }
        let remoteItem = RemotePostID(dict: response)

        let postQuery = store!.postQueryByName(name: "all", siteUUID: site!.uuid)
        let filter = postQuery!.filter as [String: AnyObject]

        XCTAssertTrue(postQuery!.items.count == 0)

        let action = PostIDsFetchedApiAction(payload: [remoteItem], error: nil, count: 1, filter: filter, page: 1, hasMore: false)
        store?.handlePostIDsFetched(action: action)
        let expect1 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            return true
        }
        wait(for: [expect1], timeout: 1)

        XCTAssertTrue(postQuery!.items.count == 1)
    }

}
