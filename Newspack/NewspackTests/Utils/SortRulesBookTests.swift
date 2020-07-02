import Foundation
import XCTest
import CoreData
@testable import Newspack

class SortRulesBookTests: XCTestCase {

    let storageKey = "TestSortRules"
    let fields = ["alpha", "beta", "gamma"]
    let defaults = ["alpha": false]
    var sortRules: SortRulesBook!

    override func setUpWithError() throws {
        sortRules = SortRulesBook(storageKey: storageKey, fields: fields, defaults: defaults)
    }

    func testReset() {
        var rules = SortRules()
        for field in fields {
            rules[field] = true
        }

        sortRules.setRules(rules: rules)
        XCTAssertFalse(NSDictionary(dictionary: defaults).isEqual(to: sortRules.rules()))

        sortRules.reset()
        XCTAssertTrue(NSDictionary(dictionary: defaults).isEqual(to: sortRules.rules()))
    }

    func testHasRule() {
        XCTAssertTrue(sortRules.hasRule(field: "alpha", ascending: false))
        XCTAssertFalse(sortRules.hasRule(field: "alpha", ascending: true))
        XCTAssertFalse(sortRules.hasRule(field: "beta", ascending: false))
        XCTAssertFalse(sortRules.hasRule(field: "beta", ascending: true))
    }

    func testSetRule() {
        XCTAssertTrue(sortRules.hasRule(field: "alpha", ascending: false))
        sortRules.setRule(field: "alpha", ascending: true)
        XCTAssertFalse(sortRules.hasRule(field: "alpha", ascending: false))
        XCTAssertTrue(sortRules.hasRule(field: "alpha", ascending: true))

        XCTAssertFalse(sortRules.hasRule(field: "beta", ascending: true))
        XCTAssertFalse(sortRules.hasRule(field: "beta", ascending: false))
        sortRules.setRule(field: "beta", ascending: true)
        XCTAssertTrue(sortRules.hasRule(field: "beta", ascending: true))
        XCTAssertTrue(sortRules.hasRule(field: "alpha", ascending: true))
    }

    func testSetRules() {
        var rules = SortRules()
        for field in fields {
            rules[field] = true
        }
        sortRules.setRules(rules: rules)

        let setRules = sortRules.rules()
        for (key, value) in setRules {
            XCTAssertTrue(fields.contains(key))
            XCTAssertTrue(value)
        }
    }

    func testDescriptors() {
        let descriptors = sortRules.descriptors()
        for descriptor in descriptors {
            XCTAssertTrue(fields.contains(descriptor.key!))
            XCTAssertFalse(descriptor.ascending)
        }
    }

}
