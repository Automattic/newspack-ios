import XCTest
@testable import Newspack

class SiteServiceRemoteTests: BaseTest {

    func testRemoteSiteSettingsAllFields() {
        guard let response = Loader.jsonObject(for: "remote-site-settings") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        // Just check that the specific types are correctly cast.
        let settings = RemoteSiteSettings(dict: response)
        XCTAssertEqual(settings.title, "Example")
        XCTAssertEqual(settings.postsPerPage, 10)
        XCTAssertEqual(settings.useSmilies, true)
        XCTAssertEqual(settings.timezone, "")
        XCTAssertEqual(settings.defaultCommentStatus, "open")

    }

    func testRemoteSiteNoFields() {
        // Just check that the defaults are correctly set.
        let settings = RemoteSiteSettings(dict: [String: AnyObject]())
        XCTAssertEqual(settings.title, "")
        XCTAssertEqual(settings.postsPerPage, 0)
        XCTAssertEqual(settings.useSmilies, false)
        XCTAssertEqual(settings.timezone, "")
        XCTAssertEqual(settings.defaultCommentStatus, "")
    }

}
