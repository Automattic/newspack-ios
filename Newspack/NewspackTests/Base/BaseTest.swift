import Foundation
import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class BaseTest: XCTestCase {

    var accountStore: AccountStore?
    let testDispatcher = ActionDispatcher()

    override func setUp() {
        super.setUp()

        CoreDataManager.shared.resetForTests()

        accountStore = AccountStore(dispatcher: testDispatcher, keychainServiceName: "com.automattic.newspack.test")
    }

    override func tearDown() {
        super.tearDown()

        accountStore?.clearAuthTokens()
        accountStore = nil
    }

}
