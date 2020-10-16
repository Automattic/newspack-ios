import XCTest
import CoreData
@testable import Newspack

class AssetStoreTests: BaseTest {

    var account: Account!
    var site: Site!
    var folderStore: FolderStore!
    var assetStore: AssetStore!
    var siteStore: SiteStore!

    override func setUp() {
        super.setUp()

        // Test account and site
        site = ModelFactory.getTestSite(context: CoreDataManager.shared.mainContext)

        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: site.url)
        site.account = account

        CoreDataManager.shared.saveContext(context: CoreDataManager.shared.mainContext)

        StoreContainer.shared.resetStores(dispatcher: testDispatcher, site: site)

        siteStore = StoreContainer.shared.siteStore

        folderStore = StoreContainer.shared.folderStore

        assetStore = StoreContainer.shared.assetStore

        createTestAssets()
    }

    override func tearDown() {
        super.tearDown()

        account = nil
        site = nil
    }

    func createTestAssets() {
        let paths = ["alpha", "beta", "gamma"]
        let expect = expectation(description: "expect")
        folderStore.createStoryFoldersForPaths(paths: paths, onComplete: {
            expect.fulfill()
        })
        wait(for: [expect], timeout: 1)

        let expectA = expectation(description: "expectA")
        let expectB = expectation(description: "expectB")
        let expectC = expectation(description: "expectC")
        assetStore.createAssetFor(text: "alpha", onComplete: {
            expectA.fulfill()
        })
        assetStore.createAssetFor(text: "beta", onComplete: {
            expectB.fulfill()
        })
        assetStore.createAssetFor(text: "gamma", onComplete: {
            expectC.fulfill()
        })
        wait(for: [expectA, expectB, expectC], timeout: 1)

        let asset = assetStore.createAsset(type: .textNote, name: "epsilon", mimeType: "plain/text", url: nil, storyFolder: folderStore.currentStoryFolder!, in: CoreDataManager.shared.mainContext)
        asset.remoteID = 100
        try? CoreDataManager.shared.mainContext.save()

        CoreDataManager.shared.mainContext.refreshAllObjects()
    }

    func testAssetNameFromString() {
        let shortString = "This is a short test string"
        let longString = "This is a long test string with some spaces abcdefghijklmnopqrstuvwxyz"
        let longStringNoBreaks = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

        let shortName = assetStore.assetName(from: shortString)
        let longName = assetStore.assetName(from: longString)
        let longNameNoBreaks = assetStore.assetName(from: longStringNoBreaks)

        XCTAssertEqual(shortName, shortString)
        XCTAssertEqual(longName, "This is a long test string with some spaces...")
        XCTAssertEqual(longNameNoBreaks, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX...")
    }

    func testDeleteAsset() {
        let folder = folderStore.currentStoryFolder!
        let asset = folder.assets.first!
        XCTAssertNotNil(asset)

        let expect = expectation(description: "expect")
        let assetID = asset.uuid!
        assetStore.deleteAsset(assetID: assetID, onComplete: {
            expect.fulfill()
        })
        wait(for: [expect], timeout: 1)
        XCTAssertTrue(asset.isDeleted)

        XCTAssertNil(assetStore.getStoryAssetByID(uuid: assetID))
    }

    func testDeleteAssets() {
        let folder = folderStore.currentStoryFolder!
        let assets = Array(folder.assets)
        XCTAssertTrue(assets.count > 1)

        let expect = expectation(description: "expect")

        assetStore.deleteAssets(assets: assets, onComplete: {
            expect.fulfill()
        })
        wait(for: [expect], timeout: 1)

        XCTAssertTrue(assetStore.getStoryAssets(storyFolder: folder).count == 0)
    }

    func testHandleDeletedRemoteMedia() {
        let folder = folderStore.currentStoryFolder!
        let asset = assetStore.getStoryAsset(for: [folder], with: 100)!

        let uuid = asset.uuid!
        let expect = expectation(description: "expect")
        assetStore.handleDeletedRemoteMedia(for: [folder.uuid!], remoteIDs: [100]) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        let fetched = assetStore.getStoryAssetByID(uuid: uuid)!
        XCTAssertTrue(fetched.remoteID == 0)
    }

    func testUpdateCaption() {
        let folder = folderStore.currentStoryFolder!
        let asset = folder.assets.first!

        let uuid = asset.uuid!
        let expect = expectation(description: "expect")
        assetStore.updateCaption(assetID: uuid, caption: "Hello", onComplete: {
            expect.fulfill()
        })
        wait(for: [expect], timeout: 1)

        let fetched = assetStore.getStoryAssetByID(uuid: uuid)!
        XCTAssertTrue(fetched.caption == "Hello")
    }

    func testUpdateAltText() {
        let folder = folderStore.currentStoryFolder!
        let asset = folder.assets.first!

        let uuid = asset.uuid!
        let expect = expectation(description: "expect")
        assetStore.updateAltText(assetID: uuid, altText: "Hello", onComplete: {
            expect.fulfill()
        })
        wait(for: [expect], timeout: 1)

        let fetched = assetStore.getStoryAssetByID(uuid: uuid)!
        XCTAssertTrue(fetched.altText == "Hello")
    }

    func testUpdateAsset() {
        guard var response = Loader.jsonObject(for: "remote-media-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        let folder = folderStore.currentStoryFolder!
        let asset = folder.assets.first!
        XCTAssertEqual(0, asset.remoteID)

        var remoteItem = RemoteMedia(dict: response)

        // The date modified in the imported data is too old. No change should be made.
        assetStore.updateAsset(asset: asset, with: remoteItem)
        XCTAssertEqual(0, asset.remoteID)

        // Update the dates.
        response["modified_gmt"] = ISO8601DateFormatter().string(from: Date()) as AnyObject
        remoteItem = RemoteMedia(dict: response)
        asset.modified = Date().addingTimeInterval(-86400)

        assetStore.updateAsset(asset: asset, with: remoteItem)

        XCTAssertTrue(asset.remoteID > 0)
    }

    func testGetRemoteIDsForFolders() {
        let folder = folderStore.currentStoryFolder!
        let remoteIDs = assetStore.getStoryAssetsRemoteIDsForFolders(folders: [folder])
        XCTAssertTrue(remoteIDs.count == 1)
        XCTAssertEqual(remoteIDs.first!, 100)
    }

    func testGetAssetsForFoldersWithIDs() {
        let folder = folderStore.currentStoryFolder!
        let assets = assetStore.getStoryAssets(for: [folder], with: [100])

        XCTAssertTrue(assets.count == 1)
        XCTAssertEqual(assets.first!.remoteID, 100)
    }

    func testGetAssetForFoldersWithRemoteID() {
        let folder = folderStore.currentStoryFolder!
        let asset = assetStore.getStoryAsset(for: [folder], with: 100)

        XCTAssertNotNil(asset)
        XCTAssertEqual(asset!.remoteID, 100)
    }

    func testGetAssetsWithChanges() {
        let folder = folderStore.currentStoryFolder!
        let asset = folder.assets.first!
        let uuid = asset.uuid!

        let expect = expectation(description: "expect")
        assetStore.updateCaption(assetID: uuid, caption: "Hello", onComplete: {
            expect.fulfill()
        })
        wait(for: [expect], timeout: 1)

        let assets = assetStore.getStoryAssetsWithChanges(storyFolders: [folder])
        XCTAssertTrue(assets.count == 1)
        XCTAssertTrue(assets.first!.uuid! == uuid)
    }

    func testGetAssetsNeedingUpload() {
        let folder = folderStore.currentStoryFolder!
        let asset = folder.assets.first!
        let uuid = asset.uuid!

        var assets = assetStore.storyAssetsNeedingUpload(limit: 3)
        XCTAssertTrue(assets.count == 0)

        // Make one ready for upload.
        asset.assetType = .image
        asset.bookmark = "Test".data(using: .utf8)
        asset.remoteID = 0
        try? CoreDataManager.shared.mainContext.save()

        assets = assetStore.storyAssetsNeedingUpload(limit: 3)
        XCTAssertTrue(assets.count == 1)
        XCTAssertTrue(assets.first!.uuid! == uuid)

    }

}
