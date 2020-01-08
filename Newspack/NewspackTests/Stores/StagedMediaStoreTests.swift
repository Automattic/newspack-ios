import XCTest
import CoreData
@testable import Newspack

class StagedMediaStoreTests: BaseTest {

    var account: Account?
    var site: Site?
    var store: StagedMediaStore?

    override func setUp() {
        super.setUp()

        // Test account
        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")

        // Test site
        let context = CoreDataManager.shared.mainContext
        site = ModelFactory.getTestSite(context: context)
        site!.account = account

        // Test store
        store = StagedMediaStore(dispatcher: testDispatcher, siteID: site!.uuid)
        CoreDataManager.shared.saveContext(context: context)
    }

    override func tearDown() {
        super.tearDown()

        account = nil
        site = nil
        store = nil
    }

    func testDeleteStagedMedia() {
        let context = CoreDataManager.shared.mainContext

        // First test deleting by UUID
        //
        var stagedMedia = StagedMedia(context: context)
        stagedMedia.site = site
        stagedMedia.uuid = UUID()
        stagedMedia.assetIdentifier = "identifier"

        CoreDataManager.shared.saveContext(context: context)

        XCTAssertFalse(stagedMedia.objectID.isTemporaryID)

        store?.deleteStagedMedia(uuid: stagedMedia.uuid)

        let expect1 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            XCTAssertTrue(stagedMedia.isDeleted)
            return true
        }
        wait(for: [expect1], timeout: 1)


        // Next test deleting by ObjectID
        //
        stagedMedia = StagedMedia(context: context)
        stagedMedia.site = site
        stagedMedia.uuid = UUID()
        stagedMedia.assetIdentifier = "identifier"

        CoreDataManager.shared.saveContext(context: context)

        XCTAssertFalse(stagedMedia.objectID.isTemporaryID)

        store?.deleteStagedMedia(objectID: stagedMedia.objectID)

        let expect2 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            XCTAssertTrue(stagedMedia.isDeleted)
            return true
        }
        wait(for: [expect2], timeout: 1)
    }

    func testRemoveDuplicateAssetIdentifiers() {
        let foo = "foo"
        let bar = "bar"
        let baz = "baz"

        let starting = [foo, bar, baz]
        let expected = [bar]

        let context = CoreDataManager.shared.mainContext
        for item in [foo, baz] {
            let stagedMedia = StagedMedia(context: context)
            stagedMedia.site = site
            stagedMedia.uuid = UUID()
            stagedMedia.assetIdentifier = item
        }
        CoreDataManager.shared.saveContext(context: context)

        let actual = store!.removeDuplicateAssetIdentifiers(identifiers: starting)

        XCTAssertEqual(actual.count, expected.count)

        for item in expected {
            XCTAssertTrue(actual.contains(item))
        }
    }

    func testCreateStagedMediaForIdentifiers() {
        let identifier = "identifier"

        let context = CoreDataManager.shared.mainContext

        store!.createStagedMediaForIdentifiers(identifiers: [identifier])
        let expect1 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: context) { (_) -> Bool in

            let context = CoreDataManager.shared.mainContext
            let fetchRequest = StagedMedia.defaultFetchRequest()
            fetchRequest.predicate = NSPredicate(format: "assetIdentifier = %@", identifier)
            let count = try! context.count(for: fetchRequest)

            XCTAssertTrue(count == 1)
            return true
        }
        wait(for: [expect1], timeout: 1)
    }
}
