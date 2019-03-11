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


}
