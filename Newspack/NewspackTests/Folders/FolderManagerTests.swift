import XCTest
@testable import Newspack

class FolderManagerTests: XCTestCase {

    var folderManager: FolderManager!

    override func setUpWithError() throws {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let tempDirectory = try! FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: documentDirectory, create: true)
        folderManager = FolderManager(rootFolder: tempDirectory)
    }

    func testCreateFolder() {
        let path = "TestFolder"
        guard let url = folderManager.createFolderAtPath(path: path) else {
            XCTFail("URL is expected to not be nil")
            return
        }

        XCTAssertNotNil(url)
        XCTAssertTrue(url.lastPathComponent.hasSuffix(path))
        XCTAssertTrue(folderManager.folderExists(url: url))
    }
}
