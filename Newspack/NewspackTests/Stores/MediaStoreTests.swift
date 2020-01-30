import XCTest
import CoreData
@testable import Newspack

class MediaStoreTests: BaseTest {

    let remoteMediaEditFile = "remote-media-edit.json"

    var account: Account?
    var site: Site?
    var store: MediaStore?

    override func setUp() {
        super.setUp()

        // Test account
        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")

        // Test site
        let context = CoreDataManager.shared.mainContext
        site = ModelFactory.getTestSite(context: context)
        site!.account = account

        // Test store
        store = MediaStore(dispatcher: testDispatcher, siteID: site!.uuid)
        CoreDataManager.shared.saveContext(context: context)
    }

    override func tearDown() {
        super.tearDown()

        account = nil
        site = nil
        store = nil
    }

    func testGetMediaItemWithID() {
        let context = CoreDataManager.shared.mainContext
        let mediaItemStore = MediaItemStore()
        guard let response = Loader.jsonObject(for: "remote-media-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        let remoteItem = RemoteMediaItem(dict: response)
        let mediaItem = MediaItem(context: context)
        mediaItem.site = site!
        mediaItemStore.updateMediaItem(mediaItem, with: remoteItem)

        CoreDataManager.shared.saveContext(context: context)

        let retrievedItem = store!.getMediaItemWithID(mediaID: remoteItem.mediaID)!

        XCTAssertEqual(mediaItem.objectID, retrievedItem.objectID)
    }

    func testHandleMediaFetchedAction() {
        let context = CoreDataManager.shared.mainContext
        let mediaItemStore = MediaItemStore()
        guard let response = Loader.jsonObject(for: "remote-media-edit") as? [String: AnyObject] else {
            XCTAssert(false)
            return
        }

        // Set up MediaItem
        //
        let remoteItem = RemoteMediaItem(dict: response)
        let mediaItem = MediaItem(context: context)
        mediaItem.site = site!
        mediaItemStore.updateMediaItem(mediaItem, with: remoteItem)
        CoreDataManager.shared.saveContext(context: context)

        let mediaID = remoteItem.mediaID

        // Setup Media Action
        let remoteMedia = RemoteMedia(dict: response)
        let action = MediaFetchedApiAction(payload: remoteMedia, error: nil, image: UIImage(), previewURL: "http://example.com/image.png", mediaID: mediaID)

        store?.handleMediaFetchedAction(action: action)

        let expect1 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (notification) -> Bool in
            guard let insertedObjects = notification.userInfo![NSInsertedObjectsKey] as? NSSet else {
                return false
            }
            return insertedObjects.contains { (object) -> Bool in
                return object is Media
            }
        }
        wait(for: [expect1], timeout: 1)

        let fetchRequest = Media.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mediaID = %ld", mediaID)

        let count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)
    }

}
