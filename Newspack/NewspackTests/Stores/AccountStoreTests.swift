import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class AccountStoreTests: BaseTest {

    /// Test that numberOfAccounts returns the correct values.
    ///
    func testNumberOfAccountsIsZero() {
        let store = accountStore!
        XCTAssertTrue(store.numberOfAccounts() == 0)

        let context = CoreDataManager.shared.mainContext
        NSEntityDescription.insertNewObject(forEntityName: "Account", into: context)

        XCTAssertTrue(store.numberOfAccounts() == 1)
    }

    /// Test that an authentication token is properly saved.
    ///
    func testAccountAndAuthTokenSaved() {
        let context = CoreDataManager.shared.mainContext
        let token = "testToken"
        let store = accountStore!
        store.createAccount(authToken: token, forNetworkAt: "example.com")

        let accounts = try! context.fetch(Account.defaultFetchRequest() as! NSFetchRequest<NSFetchRequestResult>) as! [Account]
        let account = accounts.first
        let savedToken = store.getAuthTokenForAccount(account!)

        XCTAssertTrue(savedToken == token)
    }

    /// Test that a single token is removed.
    ///
    func testRemoveAuthToken() {
        let context = CoreDataManager.shared.mainContext
        let token = "testToken"
        let store = accountStore!
        let account = Account(context: context)
        account.uuid = UUID()

        store.setAuthToken(token, for: account)
        XCTAssertTrue(token == store.getAuthTokenForAccount(account)!)

        store.clearAuthTokenForAccount(account)
        XCTAssertNil(store.getAuthTokenForAccount(account))
    }

    /// Test that all tokens are removed.
    ///
    func testClearAuthTokens() {
        let context = CoreDataManager.shared.mainContext
        let token = "testToken"
        let store = accountStore!
        let account1 = Account(context: context)
        account1.uuid = UUID()
        store.setAuthToken(token, for: account1)

        let account2 = Account(context: context)
        account2.uuid = UUID()
        store.setAuthToken(token, for: account2)

        let account3 = Account(context: context)
        account3.uuid = UUID()
        store.setAuthToken(token, for: account3)

        XCTAssertTrue(token == store.getAuthTokenForAccount(account1)!)
        XCTAssertTrue(token == store.getAuthTokenForAccount(account2)!)
        XCTAssertTrue(token == store.getAuthTokenForAccount(account3)!)

        store.clearAuthTokens()

        XCTAssertNil(store.getAuthTokenForAccount(account1))
        XCTAssertNil(store.getAuthTokenForAccount(account2))
        XCTAssertNil(store.getAuthTokenForAccount(account3))
    }

    func testMultipleAccountsCannotShareAuthToken() {
        // TODO
    }
}
