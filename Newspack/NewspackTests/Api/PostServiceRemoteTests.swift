import XCTest
@testable import Newspack

class PostServiceRemoteTests: XCTestCase {


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
