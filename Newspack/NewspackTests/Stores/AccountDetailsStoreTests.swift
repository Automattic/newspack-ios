import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class AccountDetailsStoreTests: BaseTest {

    var store: AccountDetailsStore?
    var remoteUser: RemoteUser?
    var account: Account?

    override func setUp() {
        super.setUp()

        store = AccountDetailsStore(dispatcher: .global)

        // Test account
        accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")
        account = accountStore!.currentAccount

        // Test remote user
        let response = Loader.jsonObject(for: "remote-user-edit") as! [String: AnyObject]
        remoteUser = RemoteUser(dict: response)
    }

    override func tearDown() {
        super.tearDown()

        store = nil
        remoteUser = nil
        account = nil;
    }

    func testUpdateAccountDetailsError() {
        let dispatcher = ActionDispatcher.global
        var remoteUser = self.remoteUser!
        var details: AccountDetails?
        var error: Error?

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? AccountDetailsEvent else {
                XCTFail("Wrong event type")
                return
            }
            switch event {
            case AccountDetailsEvent.accountDetailsUpdated(let d, let e) :
                details = d
                error = e
            }
        })

        let action = AccountDetailsAction.update(user: remoteUser, accountID: UUID())
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNotNil(error)
        XCTAssertNil(details)
    }

    func testUpdateAccountDetailsCreatesDetails() {
        let dispatcher = ActionDispatcher.global
        let account = self.account!
        var remoteUser = self.remoteUser!
        var details: AccountDetails?
        var error: Error?

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? AccountDetailsEvent else {
                XCTFail("Wrong event type")
                return
            }

            switch event {
            case AccountDetailsEvent.accountDetailsUpdated(let d, let e) :
                details = d
                error = e
            }
        })

        let action = AccountDetailsAction.update(user: remoteUser, accountID: account.uuid)

        XCTAssertNil(account.details)

        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNil(error)
        XCTAssertNotNil(details)
        XCTAssertNotNil(account.details)
        XCTAssertEqual(account.details!.objectID, details!.objectID)
        XCTAssertEqual(remoteUser.email, details!.email)
    }

    func testUpdateAccountDetailsUpdatesExistingDetails() {
        let dispatcher = ActionDispatcher.global
        let account = self.account!
        var remoteUser = self.remoteUser!
        var details: AccountDetails?
        var error: Error?

        store?.updateAccountDetails(user: remoteUser, accountID: account.uuid)
        XCTAssertNotNil(account.details)

        let receipt = store?.onChangeEvent({ (changeEvent) in
            guard let event = changeEvent as? AccountDetailsEvent else {
                XCTFail("Wrong event type")
                return
            }

            switch event {
            case AccountDetailsEvent.accountDetailsUpdated(let d, let e) :
                details = d
                error = e
            }
        })

        let testEmail = "test@test.com"
        var dict = Loader.jsonObject(for: "remote-user-edit") as! [String: AnyObject]
        dict["email"] = testEmail as AnyObject
        remoteUser = RemoteUser(dict: dict)

        let action = AccountDetailsAction.update(user: remoteUser, accountID: account.uuid)

        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNil(error)
        XCTAssertNotNil(details)
        XCTAssertNotNil(account.details)
        XCTAssertEqual(account.details!.objectID, details!.objectID)
        XCTAssertEqual(remoteUser.email, details!.email)
    }

    func testAccountHasOnlyOneSetOfAccountDetails() {
        let context = CoreDataManager.shared.mainContext
        let account1 = Account(context: context)
        account1.uuid = UUID()
        account1.networkUrl = "http://account1.com"
        CoreDataManager.shared.saveContext()

        let details1 = AccountDetails(context: context)
        details1.userID = 1
        details1.name = "name"
        details1.firstName = "firstName"
        details1.lastName = "lastName"
        details1.nickname = "nickname"
        details1.email = "email"
        details1.avatarUrls = [String: String]()
        details1.link = "link"
        details1.locale = "locale"
        details1.slug = "slug"
        details1.summary = "description"
        details1.url = "url"
        details1.username = "username"
        details1.registeredDate = "registeredDate"

        account1.details = details1
        CoreDataManager.shared.saveContext()

        XCTAssertEqual(account1.details!.userID, 1)

        let details2 = AccountDetails(context: context)
        details2.userID = 2
        details2.name = "name"
        details2.firstName = "firstName"
        details2.lastName = "lastName"
        details2.nickname = "nickname"
        details2.email = "email"
        details2.avatarUrls = [String: String]()
        details2.link = "link"
        details2.locale = "locale"
        details2.slug = "slug"
        details2.summary = "description"
        details2.url = "url"
        details2.username = "username"
        details2.registeredDate = "registeredDate"

        account1.details = details2
        CoreDataManager.shared.saveContext()

        XCTAssertEqual(account1.details!.userID, 2)

        let fetchRequest = AccountDetails.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "account = %@", account1)

        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)

        fetchRequest.predicate = nil
        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)
    }

    func testMultipleAccountsCannotShareAccountDetails() {
        let context = CoreDataManager.shared.mainContext
        let account1 = Account(context: context)
        account1.uuid = UUID()
        account1.networkUrl = "http://account1.com"

        let account2 = Account(context: context)
        account2.uuid = UUID()
        account2.networkUrl = "http://account1.com"

        let details1 = AccountDetails(context: context)
        details1.userID = 1
        details1.name = "name"
        details1.firstName = "firstName"
        details1.lastName = "lastName"
        details1.nickname = "nickname"
        details1.email = "email"
        details1.avatarUrls = [String: String]()
        details1.link = "link"
        details1.locale = "locale"
        details1.slug = "slug"
        details1.summary = "description"
        details1.url = "url"
        details1.username = "username"
        details1.registeredDate = "registeredDate"

        account1.details = details1
        CoreDataManager.shared.saveContext()

        XCTAssertNotNil(account1.details)
        XCTAssertNil(account2.details)

        account2.details = account1.details
        CoreDataManager.shared.saveContext()

        XCTAssertNil(account1.details)
        XCTAssertNotNil(account2.details)
    }

}
