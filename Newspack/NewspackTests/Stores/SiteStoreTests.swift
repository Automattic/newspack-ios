import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class SiteStoreTests: BaseTest {

    var remoteSettings: RemoteSiteSettings?
    var account: Account?
    let siteURL = "http://example.com"
    var siteStore: SiteStore!

    override func setUp() {
        super.setUp()

        siteStore = SiteStore()

        // Test account
        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: siteURL)

        // Test settings
        let response = Loader.jsonObject(for: "remote-site-settings") as! [String: AnyObject]
        remoteSettings = RemoteSiteSettings(dict: response)
    }

    override func tearDown() {
        super.tearDown()
        siteStore = nil
        account = nil
        remoteSettings = nil
    }

    func testCreateSite() {
        let account = self.account!
        let remoteSettings = self.remoteSettings!

        let expect = expectation(description: "expect")
        siteStore.createSites(sites:[remoteSettings], accountID: account.uuid, onComplete: {
            guard let site = account.sites.first else {
                XCTFail("The site can not be nil.")
                return
            }
            XCTAssertEqual(site.url, self.siteURL) // NOTE: The url is defined in the mock data. The actual endpoint does not currently return this value.
            XCTAssertEqual(site.title, remoteSettings.title)

            expect.fulfill()
        })

        wait(for: [expect], timeout: 1)
    }

    func testUpdateSite() {
        let account = self.account!
        var remoteSettings = self.remoteSettings!
        let testTitle = "Test Title"
        var site: Site?

        siteStore.createSites(sites: [remoteSettings], accountID: account.uuid)

        let expect1 = expectation(description: "expect")
        siteStore.createSites(sites:[remoteSettings], accountID: account.uuid, onComplete: {
            guard let site = account.sites.first else {
                XCTFail("The site can not be nil.")
                return
            }
            XCTAssertEqual(site.url, self.siteURL) // NOTE: The url is defined in the mock data. The actual endpoint does not currently return this value.
            XCTAssertEqual(site.title, remoteSettings.title)

            expect1.fulfill()
        })

        wait(for: [expect1], timeout: 1)

        site = account.sites.first
        siteStore = SiteStore(dispatcher: testDispatcher, siteID: site!.uuid)
        let receipt = siteStore.onChange {}

        var dict = Loader.jsonObject(for: "remote-site-settings") as! [String: AnyObject]
        dict["title"] = testTitle as AnyObject
        remoteSettings = RemoteSiteSettings(dict: dict)

        // Error when missing account
        let action = SiteFetchedApiAction(payload: remoteSettings, error: nil)
        testDispatcher.dispatch(action)

        XCTAssertNotNil(receipt)

        let expect2 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (notification) -> Bool in
            guard
                let objects = notification.userInfo![NSRefreshedObjectsKey] as? NSSet,
                (objects.contains { (object) -> Bool in
                    return object is Site
                })
            else {
                return false
            }

            guard let site = account.sites.first else {
                XCTFail("The site can not be nil.")
                return true
            }

            XCTAssertNotNil(site)
            XCTAssertEqual(site.url, self.siteURL) // NOTE: The url is defined in the mock data. The actual endpoint does not currently return this value.
            XCTAssertEqual(site.title, testTitle)

            return true
        }

        wait(for: [expect2], timeout: 1)
    }

    func testSingleAccountHasMultipleSites() {
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

        CoreDataManager.shared.saveContext(context: context)

        XCTAssertEqual(account.sites.count, 2)
    }

    func testMultipleAccountsCannotShareSite() {
        let context = CoreDataManager.shared.mainContext

        let account1 = Account(context: context)
        account1.uuid = UUID()
        account1.networkUrl = "http://account1.com"

        let account2 = Account(context: context)
        account2.uuid = UUID()
        account2.networkUrl = "http://account2.com"

        let site = ModelFactory.getTestSite(context: context)
        site.account = account1

        CoreDataManager.shared.saveContext(context: context)

        XCTAssertNotNil(account1.sites.first)
        XCTAssertNil(account2.sites.first)

        site.account = account2
        CoreDataManager.shared.saveContext(context: context)

        XCTAssertNil(account1.sites.first)
        XCTAssertNotNil(account2.sites.first)
    }

    func testRemovingAccountRemovesSites() {
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

        CoreDataManager.shared.saveContext(context: context)

        let fetchRequest = Site.defaultFetchRequest()
        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 2)

        context.delete(account)
        CoreDataManager.shared.saveContext(context: context)

        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 0)
    }

    func testRemovingAccountDoesNotRemoveOtherAccountSites() {
        let context = CoreDataManager.shared.mainContext

        let account1 = Account(context: context)
        account1.uuid = UUID()
        account1.networkUrl = "http://account1.com"

        let site1 = ModelFactory.getTestSite(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.account = account1

        let account2 = Account(context: context)
        account2.uuid = UUID()
        account2.networkUrl = "http://account2.com"

        let site2 = ModelFactory.getTestSite(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.account = account2

        CoreDataManager.shared.saveContext(context: context)

        let fetchRequest = Site.defaultFetchRequest()
        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 2)

        context.delete(account1)
        CoreDataManager.shared.saveContext(context: context)

        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)
    }

    func testSingleAccountNoDuplicateSites() {
        // TODO.  This is going to be tricky.
    }

    func testFolderNameForSite() {
        let expectedName = "www-example-com"
        let context = CoreDataManager.shared.mainContext
        let site = ModelFactory.getTestSite(context: context)
        site.account = account
        let store = SiteStore()

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
        let store = SiteStore()

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
