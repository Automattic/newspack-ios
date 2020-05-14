import XCTest
import CoreData
@testable import Newspack

class PostStoreTests: BaseTest {

    var account: Account?
    var site: Site?
    var store: PostStore?
    var itemStore: PostItemStore?

    override func setUp() {
        super.setUp()

        // Test account
        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")

        // Test site
        let context = CoreDataManager.shared.mainContext
        site = ModelFactory.getTestSite(context: context)
        site!.account = account

        CoreDataManager.shared.saveContext(context: context)

        // Test stores
        store = PostStore(dispatcher: testDispatcher, siteID: site!.uuid)
        itemStore = PostItemStore(dispatcher: testDispatcher, siteID: site!.uuid)

        let expect = expectation(description: "Default post queries saved.")
        itemStore?.setupDefaultPostQueriesIfNeeded(siteUUID: site!.uuid, onComplete: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)

        itemStore?.currentQuery = site?.postQueries.first
    }

    override func tearDown() {
        super.tearDown()

        account = nil
        site = nil
        store = nil
    }


    func testGetPostItemWithID() {
        let context = CoreDataManager.shared.mainContext

        guard let response = Loader.jsonObject(for: "remote-post-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        let remoteItem = RemotePostID(dict: response)
        let postItem = PostItem(context: context)
        postItem.siteUUID = site?.uuid!
        postItem.addToPostQueries(itemStore!.currentQuery!)
        itemStore!.updatePostItem(postItem, with: remoteItem)
        CoreDataManager.shared.saveContext(context: context)

        let retrievedItem = store!.getPostItemWithID(postID: remoteItem.postID)!

        XCTAssertEqual(postItem.objectID, retrievedItem.objectID)
    }

    func testHandlePostFetchedAction() {
        let context = CoreDataManager.shared.mainContext

        guard let response = Loader.jsonObject(for: "remote-post-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        // Set up PostItem
        //
        let remoteItem = RemotePostID(dict: response)
        let postItem = PostItem(context: context)
        postItem.siteUUID = site!.uuid!
        postItem.addToPostQueries(itemStore!.currentQuery!)
        itemStore!.updatePostItem(postItem, with: remoteItem)
        CoreDataManager.shared.saveContext(context: context)

        let postID = remoteItem.postID

        // Setup Post Action
        let remotePost = RemotePost(dict: response)
        let action = PostFetchedApiAction(payload: remotePost, error: nil, postID: postID)

        store?.handlePostFetchedAction(action: action)

        let expect = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            return true
        }
        wait(for: [expect], timeout: 1)

        let fetchRequest = Post.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "postID = %ld", postID)

        let count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)
    }

}
