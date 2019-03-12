import XCTest
import CoreData
@testable import Newspack

class AccountStoreTests: BaseTest {

    /// Test that numberOfAccounts returns the correct values.
    ///
    func testNumberOfAccountsIsZero() {
        let store = AccountStore()
        XCTAssertTrue(store.numberOfAccounts() == 0)

        let context = CoreDataManager.shared.mainContext
        NSEntityDescription.insertNewObject(forEntityName: "Account", into: context)

        XCTAssertTrue(store.numberOfAccounts() == 1)
    }

    /// Test that an authentication token is properly saved.
    ///
    func testAuthTokenSaved() {
        let context = CoreDataManager.shared.mainContext
        let token = "testToken"
        let store = AccountStore()
        store.createAccount(username: "tstuser", authToken: token)

        let accounts = try! context.fetch(Account.accountFetchRequest() as! NSFetchRequest<NSFetchRequestResult>) as! [Account]
        let account = accounts.first
        let savedToken = store.authToken(for: account!)

        XCTAssertTrue(savedToken == token)
    }

}
