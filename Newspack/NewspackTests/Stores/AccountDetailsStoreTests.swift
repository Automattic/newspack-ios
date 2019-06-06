import XCTest
import CoreData
@testable import Newspack

class AccountDetailsStoreTests: BaseTest {

    var accountDetailsStore: AccountDetailsStore?

    override func setUp() {
        super.setUp()

        accountDetailsStore = AccountDetailsStore(dispatcher: .global)
    }

    override func tearDown() {
        super.tearDown()

        accountDetailsStore = nil
    }

    func testCreateAccountDetailsSuccess() {

    }

    func testCreateAccountDetailsError() {

    }

    func testUpdateAccountDetailsSuccess() {

    }

    func testUpdateAccountDetailsError() {

    }

    func testAccountHasOnlyOneSetOfAccountDetails() {

    }

    func testMultipleAccountsCannotShareAccountDetails() {

    }

}
