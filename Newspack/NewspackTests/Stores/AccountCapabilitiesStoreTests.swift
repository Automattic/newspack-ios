import XCTest
import CoreData
@testable import Newspack

class AccountCapabilitiesStoreTests: BaseTest {

    var capabilities: AccountCapabilitiesStore?

    override func setUp() {
        super.setUp()

        capabilities = AccountCapabilitiesStore(dispatcher: .global)
    }

    override func tearDown() {
        super.tearDown()

        capabilities = nil
    }

    func testCreateAccountCapabilitiesSuccess() {

    }

    func testCreateAccountCapabilitiesError() {

    }

    func testUpdateAccountCapabilitiesSuccess() {

    }

    func testUpdateAccountCapabilitiesError() {

    }

    func testSiteHasOnlyOneSetOfAccountCapabilities() {

    }

    func testMultipleSitesCannotShareAccountCapabilities() {

    }

    func testSpecificCapabilityFound() {

    }

    func testSpecificCapabilityMissing() {

    }

    func testGetRole() {

    }

}
