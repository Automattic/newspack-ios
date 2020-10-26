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

    func testFetchPostStubs() {
        let expect = expectation(description: "fetch post stubs")

        stubRemoteResponse("posts", filename: remotePostsEditFile, contentType: .ApplicationJSON)

        let remote = PostServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"))
        remote.fetchPostStubs(for: [1], page: 1, perPage: 1) { (stubs, error) in
            XCTAssertNotNil(stubs)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCreatePost() {
        let expect = expectation(description: "create POST result")

        stubRemoteResponse("posts", filename: remotePostsCreateFile, contentType: .ApplicationJSON)

        let remote = PostServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"))
        remote.createPost(postParams: [String: AnyObject](), onComplete: { (post, error) in
            XCTAssertNotNil(post)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testEditPost() {
        let expect = expectation(description: "Update POST result")

        stubRemoteResponse("posts/1", filename: remotePostsUpdateFile, contentType: .ApplicationJSON)

        let remote = PostServiceRemote(wordPressComRestApi: WordPressCoreRestApi(oAuthToken: "token", userAgent: "agent"))
        remote.updatePost(postID: 1, postParams: [String: AnyObject](), onComplete: { (post, error) in
            XCTAssertNotNil(post)
            expect.fulfill()
        })

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

}
