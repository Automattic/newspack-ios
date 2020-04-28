import XCTest
@testable import Newspack

class FolderStoreTests: BaseTest {

    func testFolderNameForSite() {
        let expectedName = "www-example-com"
        let context = CoreDataManager.shared.mainContext
        let site = ModelFactory.getTestSite(context: context)
        let store = FolderStore(dispatcher: testDispatcher, siteID: site.uuid)

        // Check that site with a URL uses the URL
        site.url = "https://www.example.com/"
        var name = store.folderNameForSite(site: site)
        XCTAssertTrue(name == expectedName)

        // Check that a site without a URL uses the UUID
        site.url = ""
        name = store.folderNameForSite(site: site)
        XCTAssertTrue(name == site.uuid.uuidString)
    }

    func testSanitizedFolderNames() {
        let store = FolderStore()

        // Try a simple domain.
        var expectedName = "www-example-com"
        var name = store.sanitizedFolderName(name: "www.example.com")
        XCTAssertTrue(name == expectedName)

        // Simple domain with a trailing directory path
        name = store.sanitizedFolderName(name: "www.example.com/")
        XCTAssertTrue(name == expectedName)

        // Try a domain with a simple path
        expectedName = "www-example-com-path"
        name = store.sanitizedFolderName(name: "www.example.com/path")
        XCTAssertTrue(name == expectedName)

        // Simple domain with a path having a trailing directory path
        name = store.sanitizedFolderName(name: "www.example.com/path/")
        XCTAssertTrue(name == expectedName)

        // A domain and complex path
        expectedName = "www-example-com-path-to-some-thing"
        name = store.sanitizedFolderName(name: "www.example.com/path/to/some/thing")
        XCTAssertTrue(name == expectedName)

        // A domain and complex path havng a trailing directory path
        name = store.sanitizedFolderName(name: "www.example.com/path/to/some/thing/")
        XCTAssertTrue(name == expectedName)

        // A UUID should be already be valid.
        expectedName = UUID().uuidString
        name = store.sanitizedFolderName(name: expectedName)
        XCTAssertTrue(name == expectedName)
    }

}
