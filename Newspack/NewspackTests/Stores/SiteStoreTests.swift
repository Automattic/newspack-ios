import XCTest
import CoreData
@testable import Newspack

class SiteStoreTests: BaseTest {

    var siteStore: SiteStore?

    override func setUp() {
        super.setUp()

        siteStore = SiteStore(dispatcher: .global)
    }

    override func tearDown() {
        super.tearDown()

        siteStore = nil
    }

    func testCreateSiteSuccess() {

    }

    func testCreateSiteError() {

    }

    func testUpdateSiteSuccess() {

    }

    func testUpdateSiteError() {

    }

    func testSingleAccountHasMultipleSites() {

    }

    func testSingleAccountNoDuplicateSites() {

    }

    func testMultipleAccountsCannotShareSite() {

    }

    func testChangeCurrentSite() {

    }

    func testDefaultSiteAfterRemovingCurrentSite() {

    }

    func testRemovingAccountRemovesSites() {

    }

}
