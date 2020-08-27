import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class AccountCapabilitiesStoreTests: BaseTest {

    var store: AccountCapabilitiesStore?
    var remoteUser: RemoteUser?
    var account: Account?
    let siteURL = "http://example.com"

    override func setUp() {
        super.setUp()

        // Test account
        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")

        // Test site
        var response = Loader.jsonObject(for: "remote-site-settings") as! [String: AnyObject]
        let settings = RemoteSiteSettings(dict: response)
        let siteStore = SiteStore(dispatcher: testDispatcher)

        let context = CoreDataManager.shared.mainContext
        let site = Site(context: context)
        let siteUUID = UUID()
        site.account = account
        site.uuid = siteUUID
        site.url = siteURL
        siteStore.updateSite(site: site, withSettings: settings)
        CoreDataManager.shared.saveContext(context: context)

        store = AccountCapabilitiesStore(dispatcher: testDispatcher, siteID: siteUUID)

        // Test remote user
        response = Loader.jsonObject(for: "remote-user-edit") as! [String: AnyObject]
        remoteUser = RemoteUser(dict: response)
    }

    override func tearDown() {
        super.tearDown()

        store = nil
        remoteUser = nil
        account = nil;
    }

    func testUpdateAccountCapabilitiesCreatesCapabilities() {
        let account = self.account!
        let remoteUser = self.remoteUser!
        let site = account.sites.first!

        let receipt = store?.onChange{}

        XCTAssertNotNil(site)
        XCTAssertNil(site.capabilities)

        let action = AccountFetchedApiAction(payload: remoteUser, error: nil)
        testDispatcher.dispatch(action)

        XCTAssertNotNil(receipt)

        let expect = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { notification -> Bool in
            guard
                let objects = notification.userInfo![NSInsertedObjectsKey] as? NSSet,
                (objects.contains { (object) -> Bool in
                    return object is AccountCapabilities
                })
            else {
                return false
            }
            CoreDataManager.shared.mainContext.refreshAllObjects()
            XCTAssertNotNil(site.capabilities)
            XCTAssertEqual(remoteUser.roles.first, site.capabilities!.roles.first)

            return true
        }

        wait(for: [expect], timeout: 1)
    }

    func testUpdateAccountCapabilitiesUpdatesExistingCapabilities() {
        let account = self.account!
        var remoteUser = self.remoteUser!
        let site = account.sites.first!
        let testRole = "TestRole"

        let receipt = store?.onChange{}
        var action = AccountFetchedApiAction(payload: remoteUser, error: nil)
        testDispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        let expect1 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            XCTAssertNotNil(site.capabilities)
            XCTAssertNotEqual(site.capabilities!.roles.first, testRole)
            return true
        }

        wait(for: [expect1], timeout: 1)

        var dict = Loader.jsonObject(for: "remote-user-edit") as! [String: AnyObject]
        dict["roles"] = [testRole] as AnyObject
        remoteUser = RemoteUser(dict: dict)

        action = AccountFetchedApiAction(payload: remoteUser, error: nil)
        testDispatcher.dispatch(action)

        let expect2 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            XCTAssertNotNil(site.capabilities)
            XCTAssertEqual(site.capabilities!.roles.first, testRole)
            return true
        }

        wait(for: [expect2], timeout: 1)
    }

    func testSiteHasOnlyOneSetOfAccountCapabilities() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!
        let site = account.sites.first!
        let role1 = "role1"
        let role2 = "role2"

        let cap1 = AccountCapabilities(context: context)
        cap1.capabilities = [String: Bool]()
        cap1.roles = [role1]

        site.capabilities = cap1
        CoreDataManager.shared.saveContext(context: context)

        XCTAssertEqual(site.capabilities?.roles.first, role1)

        let cap2 = AccountCapabilities(context: context)
        cap2.capabilities = [String: Bool]()
        cap2.roles = [role2]

        site.capabilities = cap2
        CoreDataManager.shared.saveContext(context: context)

        XCTAssertEqual(site.capabilities?.roles.first, role2)

        let fetchRequest = AccountCapabilities.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site = %@", site)

        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)

        fetchRequest.predicate = NSPredicate(format: "site = NULL")
        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 0)
    }

    func testMultipleSitesCannotShareAccountCapabilities() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!

        let site1 = ModelFactory.getTestSite(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.account = account

        let site2 = ModelFactory.getTestSite(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.account = account

        let cap1 = AccountCapabilities(context: context)
        cap1.capabilities = [String: Bool]()
        cap1.roles = ["ROLE"]

        site1.capabilities = cap1
        CoreDataManager.shared.saveContext(context: context)

        XCTAssertNotNil(site1.capabilities)
        XCTAssertNil(site2.capabilities)

        site2.capabilities = cap1
        CoreDataManager.shared.saveContext(context: context)

        XCTAssertNil(site1.capabilities)
        XCTAssertNotNil(site2.capabilities)
    }

    func testSiteHasCapability() {
        let account = self.account!
        let site = account.sites.first!

        let remoteUser = self.remoteUser!

        let capabilities = AccountCapabilities(context: CoreDataManager.shared.mainContext)

        store?.updateCapabilities(capabilities, with: remoteUser)
        site.capabilities = capabilities

        XCTAssertTrue(site.hasCapability(string: "moderate_comments"))
        XCTAssertTrue(site.hasCapability(string: "MODERATE_COMMENTS"))
        XCTAssertFalse(site.hasCapability(string: "NON-EXISTANT-CAP"))
    }

    func testSiteUserHasRole() {
        let account = self.account!
        let site = account.sites.first!

        let remoteUser = self.remoteUser!
        let capabilities = AccountCapabilities(context: CoreDataManager.shared.mainContext)

        store?.updateCapabilities(capabilities, with: remoteUser)
        site.capabilities = capabilities

        XCTAssertTrue(site.hasRole(string: "editor"))
        XCTAssertTrue(site.hasRole(string: "EDITOR"))
        XCTAssertFalse(site.hasRole(string: "subscriber"))
    }

}
