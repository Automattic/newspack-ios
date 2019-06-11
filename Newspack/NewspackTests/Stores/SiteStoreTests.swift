import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class SiteStoreTests: BaseTest {

    var store: SiteStore?
    var remoteSettings: RemoteSiteSettings?
    var account: Account?
    let siteURL = "http://example.com"

    override func setUp() {
        super.setUp()

        store = SiteStore(dispatcher: .global)

        // Test account
        accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")
        account = accountStore!.currentAccount

        // Test settings
        let response = Loader.jsonObject(for: "remote-site-settings") as! [String: AnyObject]
        remoteSettings = RemoteSiteSettings(dict: response)
    }

    override func tearDown() {
        super.tearDown()

        store = nil
        account = nil
        remoteSettings = nil
    }

    func testCreateSiteError() {
        let remoteSettings = self.remoteSettings!
        let dispatcher = ActionDispatcher.global
        var site: Site?
        var error: Error?

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? SiteEvent else {
                XCTFail("Wrong event type")
                return
            }
            switch event {
            case SiteEvent.siteCreated(let s, let e) :
                site = s
                error = e
            default:
                break
            }
        })

        let action = SiteAction.create(url: siteURL, settings: remoteSettings, accountID: UUID())
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNotNil(error)
        XCTAssertNil(site)
        let siteError = error as! SiteError
        XCTAssertEqual(siteError, SiteError.createAccountMissing)
    }

    func testCreateSite() {
        let account = self.account!
        let remoteSettings = self.remoteSettings!
        let dispatcher = ActionDispatcher.global
        var site: Site?
        var error: Error?

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? SiteEvent else {
                XCTFail("Wrong event type")
                return
            }
            switch event {
            case SiteEvent.siteCreated(let s, let e) :
                site = s
                error = e
            default:
                break
            }
        })

        // Error when missing account
        let action = SiteAction.create(url: siteURL, settings: remoteSettings, accountID: account.uuid)
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNil(error)
        XCTAssertNotNil(site)
        XCTAssertEqual(site!.url, siteURL)
        XCTAssertEqual(site!.title, remoteSettings.title)
    }

    func testUpdateSite() {
        let account = self.account!
        var remoteSettings = self.remoteSettings!
        let dispatcher = ActionDispatcher.global
        let testTitle = "Test Title"
        var site: Site?
        var error: Error?

        store?.createSite(url: siteURL, settings: remoteSettings, accountID: account.uuid)
        site = account.currentSite()!

        XCTAssertNotNil(site)
        XCTAssertEqual(site!.title, remoteSettings.title)
        XCTAssertNotEqual(site!.title, testTitle)

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? SiteEvent else {
                XCTFail("Wrong event type")
                return
            }
            switch event {
            case SiteEvent.siteCreated(let s, let e) :
                site = s
                error = e
            default:
                break
            }
        })

        var dict = Loader.jsonObject(for: "remote-site-settings") as! [String: AnyObject]
        dict["title"] = testTitle as AnyObject
        remoteSettings = RemoteSiteSettings(dict: dict)

        // Error when missing account
        let action = SiteAction.update(site: site!, settings: remoteSettings)
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNil(error)
        XCTAssertNotNil(site)
        XCTAssertEqual(site!.url, siteURL)
        XCTAssertEqual(site!.title, testTitle)
    }

    func testSingleAccountHasMultipleSites() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!
        
        let site1 = Site(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.summary = "description"
        site1.timezone = "timezone"
        site1.dateFormat = "dateFormat"
        site1.timeFormat = "timeFormat"
        site1.startOfWeek = "startOfWeek"
        site1.language = "language"
        site1.useSmilies = true
        site1.defaultCategory = 1
        site1.defaultPostFormat = 1
        site1.postsPerPage = 10
        site1.defaultPingStatus = "defaultPingStatus"
        site1.defaultCommentStatus = "defaultCommentStatus"
        site1.account = account

        let site2 = Site(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.summary = "description"
        site2.timezone = "timezone"
        site2.dateFormat = "dateFormat"
        site2.timeFormat = "timeFormat"
        site2.startOfWeek = "startOfWeek"
        site2.language = "language"
        site2.useSmilies = true
        site2.defaultCategory = 1
        site2.defaultPostFormat = 1
        site2.postsPerPage = 10
        site2.defaultPingStatus = "defaultPingStatus"
        site2.defaultCommentStatus = "defaultCommentStatus"
        site2.account = account

        CoreDataManager.shared.saveContext()

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

        let site1 = Site(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.summary = "description"
        site1.timezone = "timezone"
        site1.dateFormat = "dateFormat"
        site1.timeFormat = "timeFormat"
        site1.startOfWeek = "startOfWeek"
        site1.language = "language"
        site1.useSmilies = true
        site1.defaultCategory = 1
        site1.defaultPostFormat = 1
        site1.postsPerPage = 10
        site1.defaultPingStatus = "defaultPingStatus"
        site1.defaultCommentStatus = "defaultCommentStatus"
        site1.account = account1

        CoreDataManager.shared.saveContext()

        XCTAssertNotNil(account1.currentSite())
        XCTAssertNil(account2.currentSite())

        site1.account = account2
        CoreDataManager.shared.saveContext()

        XCTAssertNil(account1.currentSite())
        XCTAssertNotNil(account2.currentSite())
    }

    func testDefaultSiteAfterRemovingCurrentSite() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!

        let site1 = Site(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.summary = "description"
        site1.timezone = "timezone"
        site1.dateFormat = "dateFormat"
        site1.timeFormat = "timeFormat"
        site1.startOfWeek = "startOfWeek"
        site1.language = "language"
        site1.useSmilies = true
        site1.defaultCategory = 1
        site1.defaultPostFormat = 1
        site1.postsPerPage = 10
        site1.defaultPingStatus = "defaultPingStatus"
        site1.defaultCommentStatus = "defaultCommentStatus"
        site1.account = account

        let site2 = Site(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.summary = "description"
        site2.timezone = "timezone"
        site2.dateFormat = "dateFormat"
        site2.timeFormat = "timeFormat"
        site2.startOfWeek = "startOfWeek"
        site2.language = "language"
        site2.useSmilies = true
        site2.defaultCategory = 1
        site2.defaultPostFormat = 1
        site2.postsPerPage = 10
        site2.defaultPingStatus = "defaultPingStatus"
        site2.defaultCommentStatus = "defaultCommentStatus"
        site2.account = account

        CoreDataManager.shared.saveContext()
        XCTAssertEqual(account.sites.count, 2)

        var currentSite = account.currentSite()!
        let title = currentSite.title
        context.delete(currentSite)
        CoreDataManager.shared.saveContext()

        XCTAssertEqual(account.sites.count, 1)
        currentSite = account.currentSite()!
        XCTAssertNotNil(currentSite)
        XCTAssertNotEqual(title, currentSite.title)
    }

    func testRemovingAccountRemovesSites() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!

        let site1 = Site(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.summary = "description"
        site1.timezone = "timezone"
        site1.dateFormat = "dateFormat"
        site1.timeFormat = "timeFormat"
        site1.startOfWeek = "startOfWeek"
        site1.language = "language"
        site1.useSmilies = true
        site1.defaultCategory = 1
        site1.defaultPostFormat = 1
        site1.postsPerPage = 10
        site1.defaultPingStatus = "defaultPingStatus"
        site1.defaultCommentStatus = "defaultCommentStatus"
        site1.account = account

        let site2 = Site(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.summary = "description"
        site2.timezone = "timezone"
        site2.dateFormat = "dateFormat"
        site2.timeFormat = "timeFormat"
        site2.startOfWeek = "startOfWeek"
        site2.language = "language"
        site2.useSmilies = true
        site2.defaultCategory = 1
        site2.defaultPostFormat = 1
        site2.postsPerPage = 10
        site2.defaultPingStatus = "defaultPingStatus"
        site2.defaultCommentStatus = "defaultCommentStatus"
        site2.account = account

        CoreDataManager.shared.saveContext()

        let fetchRequest = Site.defaultFetchRequest()
        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 2)

        context.delete(account)
        CoreDataManager.shared.saveContext()

        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 0)
    }

    func testRemovingAccountDoesNotRemoveOtherAccountSites() {
        let context = CoreDataManager.shared.mainContext

        let account1 = Account(context: context)
        account1.uuid = UUID()
        account1.networkUrl = "http://account1.com"

        let site1 = Site(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.summary = "description"
        site1.timezone = "timezone"
        site1.dateFormat = "dateFormat"
        site1.timeFormat = "timeFormat"
        site1.startOfWeek = "startOfWeek"
        site1.language = "language"
        site1.useSmilies = true
        site1.defaultCategory = 1
        site1.defaultPostFormat = 1
        site1.postsPerPage = 10
        site1.defaultPingStatus = "defaultPingStatus"
        site1.defaultCommentStatus = "defaultCommentStatus"
        site1.account = account1

        let account2 = Account(context: context)
        account2.uuid = UUID()
        account2.networkUrl = "http://account2.com"

        let site2 = Site(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.summary = "description"
        site2.timezone = "timezone"
        site2.dateFormat = "dateFormat"
        site2.timeFormat = "timeFormat"
        site2.startOfWeek = "startOfWeek"
        site2.language = "language"
        site2.useSmilies = true
        site2.defaultCategory = 1
        site2.defaultPostFormat = 1
        site2.postsPerPage = 10
        site2.defaultPingStatus = "defaultPingStatus"
        site2.defaultCommentStatus = "defaultCommentStatus"
        site2.account = account2

        CoreDataManager.shared.saveContext()

        let fetchRequest = Site.defaultFetchRequest()
        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 2)

        context.delete(account1)
        CoreDataManager.shared.saveContext()

        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)
    }


    func testChangeCurrentSite() {
        // TODO: Need to update the store.
    }

    func testSingleAccountNoDuplicateSites() {
        // TODO.  This is going to be tricky.
    }
}
