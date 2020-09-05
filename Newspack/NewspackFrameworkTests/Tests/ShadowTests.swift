import XCTest
@testable import NewspackFramework

class ShadowTests: XCTestCase {

    func testCreateShadowSite() {
        let story = ShadowStory(uuid: "story", title: "story", bookmarkData: Data())
        let site = ShadowSite(uuid: "site", title: "site", stories: [story])

        let dict = site.dictionary

        let remadeSite = ShadowSite(dict: dict)
        XCTAssertTrue(remadeSite.uuid == site.uuid)
        XCTAssertTrue(remadeSite.title == site.title)

        let remadeStory = remadeSite.stories.first!
        XCTAssertTrue(remadeStory.uuid == story.uuid)
        XCTAssertTrue(remadeStory.title == story.title)
    }

    func testCreateShadowStory() {
        let data = "data".data(using: .ascii)!
        let story = ShadowStory(uuid: "story", title: "story", bookmarkData: data)

        let dict = story.dictionary

        let remadeStory = ShadowStory(dict: dict)
        XCTAssertTrue(remadeStory.uuid == story.uuid)
        XCTAssertTrue(remadeStory.title == story.title)
        XCTAssertTrue(remadeStory.bookmarkData == data)
    }

    func testCreateShadowAsset() {
        let data = "data".data(using: .ascii)!
        let asset = ShadowAsset(storyUUID: "story", bookmarkData: data)

        let dict = asset.dictionary

        let remadeAsset = ShadowAsset(dict: dict)
        XCTAssertTrue(remadeAsset.storyUUID == asset.storyUUID)
        XCTAssertTrue(remadeAsset.bookmarkData == data)
    }

    func testStoreAndRetrieveShadowSites() {
        let story = ShadowStory(uuid: "story", title: "story", bookmarkData: Data())
        let site = ShadowSite(uuid: "site", title: "site", stories: [story])

        let manager = ShadowManager()
        manager.storeShadowSites(sites: [site])

        let retrieved = manager.retrieveShadowSites()
        XCTAssertTrue(retrieved.count == 1)

        let retrievedSite = retrieved.first!
        XCTAssertTrue(retrievedSite.uuid == site.uuid)
        XCTAssertTrue(retrievedSite.title == site.title)

        let retrievedStory = retrievedSite.stories.first!
        XCTAssertTrue(retrievedStory.uuid == story.uuid)
        XCTAssertTrue(retrievedStory.title == story.title)
    }

    func testStoreAndRetrieveShadowAssets() {
        let data = "data".data(using: .ascii)!
        let asset = ShadowAsset(storyUUID: "story", bookmarkData: data)

        let manager = ShadowManager()
        manager.storeShadowAssets(assets: [asset])

        let retrieved = manager.retrieveShadowAssets()
        XCTAssertTrue(retrieved.count == 1)

        let retrievedAsset = retrieved.first!
        XCTAssertTrue(retrievedAsset.storyUUID == asset.storyUUID)
        XCTAssertTrue(retrievedAsset.bookmarkData == data)
    }

    func testClearShadowAssets() {
        let data = "data".data(using: .ascii)!
        let asset = ShadowAsset(storyUUID: "story", bookmarkData: data)

        let manager = ShadowManager()
        manager.storeShadowAssets(assets: [asset])

        let folderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier)!
        let file = FileManager.default.availableFileURL(for: "file.txt", isDirectory: false, relativeTo: folderURL)
        var success = false
        success = FileManager.default.createFile(atPath: file.path, contents: data, attributes: nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(success)

        var retrieved = manager.retrieveShadowAssets()
        XCTAssertTrue(retrieved.count == 1)

        manager.clearShadowAssets()

        retrieved = manager.retrieveShadowAssets()
        XCTAssertTrue(retrieved.count == 0)

        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

}
