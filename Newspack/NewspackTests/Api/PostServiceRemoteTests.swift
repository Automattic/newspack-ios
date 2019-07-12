import XCTest
import OHHTTPStubs
import WordPressFlux
@testable import Newspack

class PostServiceRemoteTests: RemoteTestCase {

    let remotePostEditFile = "remote-post-edit.json"
    let remotePostIDEditFile = "remote-post-id-edit.json"
    let remotePostsEditFile = "remote-posts-edit.json"
    let remotePostsIDsEditFile = "remote-posts-ids-edit.json"

    // Used to retain receipts while fulfilling expectations.
    var receipt: Receipt?

    override func tearDown() {
        super.tearDown()

        receipt = nil
    }

    func testFetchPost() {
        let expect = expectation(description: "fetch post")

        receipt = ActionDispatcher.global.subscribe { action in
            defer {
                expect.fulfill()
            }
            guard let postAction = action as? PostFetchedApiAction else {
                XCTAssert(false)
                return
            }

            XCTAssertFalse(postAction.isError())
            XCTAssertTrue(postAction.payload != nil)
        }

        stubRemoteResponse("posts", filename: remotePostEditFile, contentType: .ApplicationJSON)

        let remote = PostServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent") )
        remote.fetchPost(postID: 1, fromSite: UUID())

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testFetchPosts() {
        let expect = expectation(description: "fetch posts")

        receipt = ActionDispatcher.global.subscribe { action in
            defer {
                expect.fulfill()
            }
            guard let postAction = action as? PostsFetchedApiAction else {
                XCTAssert(false)
                return
            }

            XCTAssertFalse(postAction.isError())
            XCTAssertTrue(postAction.payload != nil)
        }

        stubRemoteResponse("posts", filename: remotePostsEditFile, contentType: .ApplicationJSON)

        let remote = PostServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent") )
        remote.fetchPosts(siteUUID: UUID())

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testFetchPostIDs() {
        let expect = expectation(description: "fetch post IDs")

        receipt = ActionDispatcher.global.subscribe { action in
            defer {
                expect.fulfill()
            }
            guard let postAction = action as? PostIDsFetchedApiAction else {
                XCTAssert(false)
                return
            }

            XCTAssertFalse(postAction.isError())
            XCTAssertTrue(postAction.payload != nil)
        }

        stubRemoteResponse("posts", filename: remotePostsIDsEditFile, contentType: .ApplicationJSON)

        let remote = PostServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent") )
        remote.fetchPostIDs(siteUUID: UUID(), page: 1)

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testRemotePost() {
        
        guard let response = Loader.jsonObject(for: "remote-post-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        let remotePost = RemotePost(dict: response)

        XCTAssert(remotePost.postID == 6815)
        XCTAssert(remotePost.categories.count == 3)
        XCTAssert(remotePost.tags.count == 3)
        XCTAssert(remotePost.featuredMedia == 0)
    }

    func testRemotePostID() {

        guard let response = Loader.jsonObject(for: "remote-post-id-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        let remotePostID = RemotePostID(dict: response)

        XCTAssert(remotePostID.postID == 6815)
    }

}
