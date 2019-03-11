import XCTest
import CoreData
@testable import Newspack

class AuthenticationManagerTests: BaseTest {

    func testAuthIsRequred() {

        let authManager = AuthenticationManager()
        XCTAssertTrue(authManager.authenticationRequred())

        let context = CoreDataManager.shared.mainContext
        NSEntityDescription.insertNewObject(forEntityName: "Account", into: context)

        XCTAssertFalse(authManager.authenticationRequred())
    }
}
