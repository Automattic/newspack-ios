import XCTest
@testable import Newspack

class UserServiceRemoteTests: BaseTest {

    func testRemoteUserEditFields() {
        guard let response = Loader.jsonObject(for: "remote-user-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        // Just check that the specific types are correctly cast.
        let user = RemoteUser(dict: response)
        XCTAssertEqual(user.id, 101)
        XCTAssertEqual(user.name, "example")
        XCTAssertEqual(user.username, "example")
        XCTAssertEqual(user.email, "example@example.com")
        XCTAssertEqual(user.locale, "en")
        XCTAssertEqual(user.nickname, "example")
        XCTAssertEqual(user.firstName, "example")
        XCTAssertEqual(user.lastName, "example")

        XCTAssertEqual(user.capabilities["editor"], true)
        XCTAssertNil(user.capabilities["foo"])

        XCTAssertEqual(user.roles.count, 1)
        XCTAssertEqual(user.roles[0], "editor")

        XCTAssertEqual(user.avatarUrls["24"], "https://secure.gravatar.com/avatar/101?s=24&d=identicon&r=g")
        XCTAssertEqual(user.avatarUrls.count, 3)
    }

    func testRemoteUserViewFields() {
        guard let response = Loader.jsonObject(for: "remote-user-view") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        // Just check that the specific types are correctly cast.
        let user = RemoteUser(dict: response)
        XCTAssertEqual(user.id, 101)
        XCTAssertEqual(user.name, "example")
        XCTAssertEqual(user.username, "")
        XCTAssertEqual(user.email, "")
        XCTAssertEqual(user.locale, "")
        XCTAssertEqual(user.nickname, "")
        XCTAssertEqual(user.firstName, "")
        XCTAssertEqual(user.lastName, "")

        XCTAssertEqual(user.capabilities.count, 0)

        XCTAssertEqual(user.roles.count, 0)

        XCTAssertEqual(user.avatarUrls["24"], "https://secure.gravatar.com/avatar/101?s=24&d=identicon&r=g")
        XCTAssertEqual(user.avatarUrls.count, 3)
    }

}
