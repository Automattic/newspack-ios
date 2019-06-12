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

        store = StoreContainer.shared.accountDetailsStore

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
        let remoteUser = self.remoteUser!
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
        let remoteUser = self.remoteUser!
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

        let details1 = ModelFactory.getTestAccountDetails(context: context)
        details1.userID = 1

        account1.details = details1
        CoreDataManager.shared.saveContext()

        XCTAssertEqual(account1.details!.userID, 1)

         let details2 = ModelFactory.getTestAccountDetails(context: context)
        details2.userID = 2

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
        account2.networkUrl = "http://account2.com"

        let details = ModelFactory.getTestAccountDetails(context: context)

        account1.details = details
        CoreDataManager.shared.saveContext()

        XCTAssertNotNil(account1.details)
        XCTAssertNil(account2.details)

        account2.details = account1.details
        CoreDataManager.shared.saveContext()

        XCTAssertNil(account1.details)
        XCTAssertNotNil(account2.details)
    }

}
