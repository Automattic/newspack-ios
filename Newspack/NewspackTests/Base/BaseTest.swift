import Foundation
import XCTest
import CoreData
@testable import Newspack

class BaseTest: XCTestCase {

    var accountStore: AccountStore?

    override func setUp() {
        super.setUp()

        CoreDataManager.shared.resetForTests()

        accountStore = AccountStore(dispatcher: .global, keychainServiceName: "com.automattic.newspack.test")
    }

    override func tearDown() {
        super.tearDown()

        accountStore?.clearAuthTokens()
        accountStore = nil
    }

}
