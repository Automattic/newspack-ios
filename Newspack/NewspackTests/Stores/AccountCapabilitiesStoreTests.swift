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

        store = StoreContainer.shared.accountCapabilitiesStore

        // Test account
        accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")
        account = accountStore!.currentAccount

        // Test site
        var response = Loader.jsonObject(for: "remote-site-settings") as! [String: AnyObject]
        let settings = RemoteSiteSettings(dict: response)
        let siteStore = SiteStore(dispatcher: .global)
        siteStore.createSite(url: siteURL, settings: settings, accountID: account!.uuid)

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

    func testCreateAccountCapabilitiesError() {
        let account = self.account!
        let remoteUser = self.remoteUser!
        var capabilities: AccountCapabilities?
        var error: Error?

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? AccountCapabilitiesEvent else {
                XCTFail("Wrong event type")
                return
            }
            switch event {
            case AccountCapabilitiesEvent.accountCapabilitiesUpdated(let c, let e) :
                capabilities = c
                error = e
            }
        })

        let dispatcher = ActionDispatcher.global

        // Error when missing account
        var action = AccountCapabilitiesAction.update(user: remoteUser, siteUrl: siteURL, accountID: UUID())
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNotNil(error)
        XCTAssertNil(capabilities)
        var capabilitiesError = error as! AccountCapabilitiesError
        XCTAssertEqual(capabilitiesError, AccountCapabilitiesError.updateAccountMissing)

        action = AccountCapabilitiesAction.update(user: remoteUser, siteUrl: "http://foo.bar", accountID: account.uuid)
        dispatcher.dispatch(action)
        XCTAssertNotNil(receipt)
        XCTAssertNotNil(error)
        XCTAssertNil(capabilities)
        capabilitiesError = error as! AccountCapabilitiesError
        XCTAssertEqual(capabilitiesError, AccountCapabilitiesError.updateSiteMissing)
    }

    func testUpdateAccountCapabilitiesCreatesCapabilities() {
        var capabilities: AccountCapabilities?
        var error: Error?
        let account = self.account!
        let remoteUser = self.remoteUser!
        let site = account.currentSite!

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? AccountCapabilitiesEvent else {
                XCTFail("Wrong event type")
                return
            }
            switch event {
            case AccountCapabilitiesEvent.accountCapabilitiesUpdated(let c, let e) :
                capabilities = c
                error = e
            }
        })

        XCTAssertNotNil(site)
        XCTAssertNil(site.capabilities)

        let action = AccountCapabilitiesAction.update(user: remoteUser, siteUrl: site.url, accountID: account.uuid)
        let dispatcher = ActionDispatcher.global
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNil(error)
        XCTAssertNotNil(capabilities)
        XCTAssertNotNil(site.capabilities)
        XCTAssertEqual(site.capabilities!.objectID, capabilities!.objectID)
        XCTAssertEqual(remoteUser.roles.first, capabilities!.roles.first)
    }

    func testUpdateAccountCapabilitiesUpdatesExistingCapabilities() {
        let dispatcher = ActionDispatcher.global
        let account = self.account!
        var remoteUser = self.remoteUser!
        let site = account.currentSite!
        let testRole = "TestRole"
        var capabilities: AccountCapabilities?
        var error: Error?

        store?.updateAccountCapabilities(user: remoteUser, siteUrl: site.url, accountID: account.uuid)
        XCTAssertNotNil(site.capabilities)
        XCTAssertNotEqual(remoteUser.roles.first, testRole)

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? AccountCapabilitiesEvent else {
                XCTFail("Wrong event type")
                return
            }
            switch event {
            case AccountCapabilitiesEvent.accountCapabilitiesUpdated(let c, let e) :
                capabilities = c
                error = e
            }
        })

        var dict = Loader.jsonObject(for: "remote-user-edit") as! [String: AnyObject]
        dict["roles"] = [testRole] as AnyObject
        remoteUser = RemoteUser(dict: dict)

        let action = AccountCapabilitiesAction.update(user: remoteUser, siteUrl: site.url, accountID: account.uuid)
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNil(error)
        XCTAssertNotNil(capabilities)
        XCTAssertNotNil(site.capabilities)
        XCTAssertEqual(site.capabilities!.objectID, capabilities!.objectID)
        XCTAssertEqual(remoteUser.roles.first, testRole)
    }

    func testSiteHasOnlyOneSetOfAccountCapabilities() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!
        let site = account.currentSite!
        let role1 = "role1"
        let role2 = "role2"

        let cap1 = AccountCapabilities(context: context)
        cap1.capabilities = [String: Bool]()
        cap1.roles = [role1]

        site.capabilities = cap1
        CoreDataManager.shared.saveContext()

        XCTAssertEqual(site.capabilities?.roles.first, role1)

        let cap2 = AccountCapabilities(context: context)
        cap2.capabilities = [String: Bool]()
        cap2.roles = [role2]

        site.capabilities = cap2
        CoreDataManager.shared.saveContext()

        XCTAssertEqual(site.capabilities?.roles.first, role2)

        let fetchRequest = AccountCapabilities.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "site = %@", site)

        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)

        fetchRequest.predicate = nil
        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)
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
        CoreDataManager.shared.saveContext()

        XCTAssertNotNil(site1.capabilities)
        XCTAssertNil(site2.capabilities)

        site2.capabilities = cap1
        CoreDataManager.shared.saveContext()

        XCTAssertNil(site1.capabilities)
        XCTAssertNotNil(site2.capabilities)
    }

    func testHasCapabilities() {
        let account = self.account!
        let site = account.currentSite!
        let remoteUser = self.remoteUser!
        let dispatcher = ActionDispatcher.global

        let action = AccountCapabilitiesAction.update(user: remoteUser, siteUrl: site.url, accountID: account.uuid)
        dispatcher.dispatch(action)

        XCTAssertTrue(site.hasCapability(string: "moderate_comments"))
        XCTAssertTrue(site.hasCapability(string: "MODERATE_COMMENTS"))
        XCTAssertFalse(site.hasCapability(string: "NON-EXISTANT-CAP"))
    }

    func testHasRole() {
        let account = self.account!
        let site = account.currentSite!
        let remoteUser = self.remoteUser!
        let dispatcher = ActionDispatcher.global

        let action = AccountCapabilitiesAction.update(user: remoteUser, siteUrl: site.url, accountID: account.uuid)
        dispatcher.dispatch(action)

        XCTAssertTrue(site.hasRole(string: "editor"))
        XCTAssertTrue(site.hasRole(string: "EDITOR"))
        XCTAssertFalse(site.hasRole(string: "subscriber"))
    }

}
