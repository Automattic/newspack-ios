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

        // Test account
        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: "example.com")

        store = AccountDetailsStore(dispatcher: .global, accountID: account!.uuid)

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

    func testUpdateAccountDetailsCreatesDetails() {
        let dispatcher = ActionDispatcher.global
        let account = self.account!
        let remoteUser = self.remoteUser!

        XCTAssertNil(account.details)

        let receipt = store?.onChange{}
        let action = AccountFetchedApiAction(payload: remoteUser, error: nil)
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)

        let expect = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            XCTAssertNotNil(account.details)
            XCTAssertEqual(remoteUser.email, account.details!.email)
            return true
        }

        wait(for: [expect], timeout: 1)
    }

    func testUpdateAccountDetailsUpdatesExistingDetails() {
        let dispatcher = ActionDispatcher.global
        let account = self.account!
        var remoteUser = self.remoteUser!

        let receipt = store?.onChange{}
        var action = AccountFetchedApiAction(payload: remoteUser, error: nil)
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)

        let expect1 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            XCTAssertNotNil(account.details)
            XCTAssertEqual(remoteUser.email, account.details!.email)
            return true
        }

        wait(for: [expect1], timeout: 1)

        let testEmail = "test@test.com"
        var dict = Loader.jsonObject(for: "remote-user-edit") as! [String: AnyObject]
        dict["email"] = testEmail as AnyObject
        remoteUser = RemoteUser(dict: dict)

        action = AccountFetchedApiAction(payload: remoteUser, error: nil)
        dispatcher.dispatch(action)

        let expect2 = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            XCTAssertNotNil(account.details)
            XCTAssertEqual(remoteUser.email, account.details!.email)
            return true
        }

        wait(for: [expect2], timeout: 1)
    }

    func testAccountHasOnlyOneSetOfAccountDetails() {
        let context = CoreDataManager.shared.mainContext
        let account1 = Account(context: context)
        account1.uuid = UUID()
        account1.networkUrl = "http://account1.com"
        CoreDataManager.shared.saveContext(context: context)

        let details1 = ModelFactory.getTestAccountDetails(context: context)
        details1.userID = 1

        account1.details = details1
        CoreDataManager.shared.saveContext(context: context)

        XCTAssertEqual(account1.details!.userID, 1)

         let details2 = ModelFactory.getTestAccountDetails(context: context)
        details2.userID = 2

        account1.details = details2
        CoreDataManager.shared.saveContext(context: context)

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
        CoreDataManager.shared.saveContext(context: context)

        XCTAssertNotNil(account1.details)
        XCTAssertNil(account2.details)

        account2.details = account1.details
        CoreDataManager.shared.saveContext(context: context)

        XCTAssertNil(account1.details)
        XCTAssertNotNil(account2.details)
    }

}
