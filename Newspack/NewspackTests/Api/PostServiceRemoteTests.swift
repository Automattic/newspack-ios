import XCTest
import OHHTTPStubs
import WordPressFlux
@testable import Newspack

class PostServiceRemoteTests: RemoteTestCase {

    let remotePostEditFile = "remote-post-edit.json"
    let remotePostIDEditFile = "remote-post-id-edit.json"
    let remotePostsEditFile = "remote-posts-edit.json"
    let remotePostsIDsEditFile = "remote-posts-ids-edit.json"
    let remoteAutosaveFile = "remote-autosave.json"
    let remotePostsCreateFile = "remote-posts-create.json"
    let remotePostsUpdateFile = "remote-posts-update.json"

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

        let remote = PostApiService(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"), dispatcher: ActionDispatcher.global )
        remote.fetchPost(postID: 1)

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

        let remote = PostApiService(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"), dispatcher: ActionDispatcher.global )
        remote.fetchPostIDs(filter: [:], page: 1)

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testAutosave() {
        let expect = expectation(description: "autosaves POST result")

        receipt = ActionDispatcher.global.subscribe { action in
            defer {
                expect.fulfill()
            }
            guard let autosaveAction = action as? AutosaveApiAction else {
                XCTAssert(false)
                return
            }

            XCTAssertFalse(autosaveAction.isError())
            XCTAssertTrue(autosaveAction.payload != nil)
        }

        stubRemoteResponse("posts/1/autosaves", filename: remoteAutosaveFile, contentType: .ApplicationJSON)

        let remote = PostApiService(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"), dispatcher: ActionDispatcher.global )
        remote.autosave(postID: 1, title: "Testing", content: "Testing")

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCreatePost() {
        let expect = expectation(description: "create POST result")
        let uuid = UUID()

        receipt = ActionDispatcher.global.subscribe { action in
            defer {
                expect.fulfill()
            }
            guard let postAction = action as? PostCreatedApiAction else {
                XCTAssert(false)
                return
            }

            XCTAssertFalse(postAction.isError())
            XCTAssertTrue(postAction.payload != nil)
            XCTAssertTrue(postAction.uuid == uuid)
        }

        stubRemoteResponse("posts", filename: remotePostsCreateFile, contentType: .ApplicationJSON)

        let remote = PostApiService(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"), dispatcher: ActionDispatcher.global )
        remote.createPost(uuid: uuid, postParams: [String: AnyObject]())

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testEditPost() {
        let expect = expectation(description: "Update POST result")

        receipt = ActionDispatcher.global.subscribe { action in
            defer {
                expect.fulfill()
            }
            guard let postAction = action as? PostUpdatedApiAction else {
                XCTAssert(false)
                return
            }

            XCTAssertFalse(postAction.isError())
            XCTAssertTrue(postAction.payload != nil)
        }

        stubRemoteResponse("posts/1", filename: remotePostsUpdateFile, contentType: .ApplicationJSON)

        let remote = PostApiService(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"), dispatcher: ActionDispatcher.global )
        remote.updatePost(postID: 1, postParams: [String: AnyObject]())

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

    func testRemoteRevision() {
        guard let response = Loader.jsonObject(for: "remote-revision") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        let remoteRevision = RemoteRevision(dict: response)

        XCTAssert(remoteRevision.revisionID == 6860)
        XCTAssert(remoteRevision.parentID == 6858)
        XCTAssert(remoteRevision.previewLink == "")
    }

    func testRemoteRevisionAsAutosaveResponse() {
        guard let response = Loader.jsonObject(for: "remote-autosave") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        let remoteRevision = RemoteRevision(dict: response)

        XCTAssert(remoteRevision.revisionID == 6860)
        XCTAssert(remoteRevision.parentID == 6858)
        XCTAssert(remoteRevision.previewLink == "https://example.com/2019/08/15/private-post/?preview_id=6858&preview_nonce=ed89b5a440&preview=true")
    }

}
