import XCTest
@testable import Newspack

class FolderManagerTests: XCTestCase {

    var folderManager: FolderManager!

    override func setUpWithError() throws {
        let tempDirectory = FolderManager.createTemporaryDirectory()
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

    func testCreatingExistingFolder() {
        let path = "TestFolder"
        let expectedPath2 = "TestFolder 2"
        let expectedPath3 = "TestFolder 3"

        // Create the starting folder
        _ = folderManager.createFolderAtPath(path: path)

        guard let url2 = folderManager.createFolderAtPath(path: path, ifExistsAppendSuffix: true) else {
            XCTFail("URL is expected to not be nil")
            return
        }

        XCTAssertNotNil(url2)
        XCTAssertTrue(url2.lastPathComponent.hasSuffix(expectedPath2))
        XCTAssertTrue(folderManager.folderExists(url: url2))


        guard let url3 = folderManager.createFolderAtPath(path: path, ifExistsAppendSuffix: true) else {
            XCTFail("URL is expected to not be nil")
            return
        }

        XCTAssertNotNil(url3)
        XCTAssertTrue(url3.lastPathComponent.hasSuffix(expectedPath3))
        XCTAssertTrue(folderManager.folderExists(url: url3))
    }

    func testSetCurrentFolder() {
        let path = "TestFolder"

        let originalCurrentFolder = folderManager.currentFolder

        // Create the starting folder
        let url = folderManager.createFolderAtPath(path: path)!
        var success = folderManager.setCurrentFolder(url: url)
        XCTAssertTrue(success)

        success = folderManager.setCurrentFolder(url: originalCurrentFolder)
        XCTAssertTrue(success)

        success = folderManager.setCurrentFolder(url: FileManager.default.temporaryDirectory)
        XCTAssertFalse(success)
    }
}
