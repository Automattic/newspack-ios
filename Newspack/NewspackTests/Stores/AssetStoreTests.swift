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

        siteStore = SiteStore(dispatcher: testDispatcher, siteID: site.uuid)

        folderStore = FolderStore(dispatcher: testDispatcher, siteID: site.uuid)

        assetStore = AssetStore(dispatcher: testDispatcher)
    }

    override func tearDown() {
        super.tearDown()

        account = nil
        site = nil
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

    }

    func testDeleteAssets() {

    }

    func testHandleDeletedRemoteMedia() {

    }

    func testUpdateCaption() {

    }

    func testUpdateAltText() {

    }

    func testUpdateAsset() {

    }

    func testGetAssetByID() {

    }

    func testGetAssetsForFolder() {

    }

    func testGetRemoteIDsForFolders() {

    }

    func testGetAssetsForFoldersWithIDs() {

    }

    func testGetAssetForFoldersWithRemoteID() {

    }

    func testGetAssetsWithChanges() {

    }

    func testGetAssetsNeedingUpload() {

    }

}
