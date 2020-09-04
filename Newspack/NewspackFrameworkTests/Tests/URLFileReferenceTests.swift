import XCTest
@testable import NewspackFramework

class URLFileReferenceTests: XCTestCase {

    var folderManager: FolderManager!

    override func setUpWithError() throws {
        let tempDirectory = FolderManager.createTemporaryDirectory()
        folderManager = FolderManager(rootFolder: tempDirectory)
    }

    func testURLFileReferenceCreated() {
        let path = "TestFolder"
        guard let url = folderManager.createFolderAtPath(path: path) else {
            XCTFail("URL is expected to not be nil")
            return
        }
        XCTAssertNotNil(url)
        XCTAssertTrue(url.lastPathComponent.hasSuffix(path))
        XCTAssertTrue(folderManager.folderExists(url: url))

        let refURL = url.getFileReferenceURL()
        XCTAssertNotNil(refURL)
    }

    func testURLFileReferenceEquality() {
        // Create a test target.
        let path = "TestFolder/TestChildFolder"
        guard let url = folderManager.createFolderAtPath(path: path) else {
            XCTFail("URL is expected to not be nil")
            return
        }
        XCTAssertNotNil(url)
        XCTAssertTrue(folderManager.folderExists(url: url))

        // Create a bunch of different URLs that point to the same destination, just in different ways.

        let rootURL = folderManager.currentFolder.absoluteURL

        let url1 = URL(fileURLWithPath: path, isDirectory: false, relativeTo: rootURL)
        XCTAssertTrue(folderManager.folderExists(url: url1))

        let url2 = URL(fileURLWithPath: path, isDirectory: true, relativeTo: rootURL)
        XCTAssertTrue(folderManager.folderExists(url: url2))

        let combinedPath = rootURL.path + "/" + path

        let url3 = URL(fileURLWithPath: combinedPath, isDirectory: false)
        XCTAssertTrue(folderManager.folderExists(url: url3))

        let url4 = URL(fileURLWithPath: combinedPath + "/", isDirectory: true)
        XCTAssertTrue(folderManager.folderExists(url: url4))

        // None of the URLs should be equal because they have different paths and bases.
        XCTAssertFalse(url1 == url2)
        XCTAssertFalse(url2 == url3)
        XCTAssertFalse(url3 == url4)
        XCTAssertFalse(url1 == url4)
        XCTAssertFalse(url1 == url3)
        XCTAssertFalse(url2 == url4)

        let ref1 = url.getFileReferenceURL()!
        let ref2 = url2.getFileReferenceURL()!
        let ref3 = url3.getFileReferenceURL()!
        let ref4 = url4.getFileReferenceURL()!

        XCTAssertTrue(ref1.isEqual(ref2))
        XCTAssertTrue(ref2.isEqual(ref3))
        XCTAssertTrue(ref3.isEqual(ref4))
    }

}
