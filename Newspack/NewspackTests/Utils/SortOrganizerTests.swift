import Foundation
import XCTest
import CoreData
@testable import Newspack

class SortOrganizerTests: XCTestCase {

    let organizerKey = "TestSortOrganizer"
    let modeAKey = "TestSortModeA"
    let modeBKey = "TestSortModeB"

    var organizer: SortOrganizer!
    var mode: SortMode!
    var rule: SortRule!

    override func setUpWithError() throws {
        let rulesA = [
            SortRule(field: "alpha", displayName: "Alpha", ascending: false),
            SortRule(field: "beta", displayName: "Beta", ascending: true)
        ]
        let rulesB = [
            SortRule(field: "gamma", displayName: "Gamma", ascending: false),
            SortRule(field: "delta", displayName: "Delta", ascending: true)
        ]
        let modeA = SortMode(defaultsKey: modeAKey, title: "ModeA", rules: rulesA, hasSections: true, resolver: nil)
        let modeB = SortMode(defaultsKey: modeBKey, title: "ModeB", rules: rulesB, hasSections: false, resolver: nil)

        organizer = SortOrganizer(defaultsKey: organizerKey, modes: [modeA, modeB])
    }

    override func tearDownWithError() throws {
        UserDefaults.shared.removeObject(forKey: organizerKey)
        UserDefaults.shared.removeObject(forKey: modeAKey)
        UserDefaults.shared.removeObject(forKey: modeBKey)
    }

    func testCreateRuleFromDictionary() {
        let dict: [String: Any] = [
            "field": "alpha",
            "displayName": "Alpha",
            "ascending": false
        ]
        let rule = SortRule(dict: dict)

        XCTAssertTrue(rule.field == "alpha")
        XCTAssertTrue(rule.displayName == "Alpha")
        XCTAssertFalse(rule.ascending)
    }

    func testSelectMode() {
        // Starting should be 0
        XCTAssertTrue(organizer.selectedIndex == 0)
        XCTAssertTrue(organizer.selectedMode.title == "ModeA")

        organizer.select(index: 1)

        XCTAssertTrue(organizer.selectedIndex == 1)
        XCTAssertTrue(organizer.selectedMode.title == "ModeB")
    }

    func testModeAtIndex() {
        var mode = organizer.mode(at: 0)
        XCTAssertTrue(mode.title == "ModeA")

        mode = organizer.mode(at: 1)
        XCTAssertTrue(mode.title == "ModeB")

    }

    func testModeSetRules() {
        let rule = SortRule(field: "epsilon", displayName: "Epsilon", ascending: true)

        let mode = organizer.mode(at: 0)
        XCTAssertTrue(mode.title == "ModeA")
        XCTAssertTrue(mode.rules.count == 2)

        let firstRule = mode.rules.first!
        XCTAssertTrue(firstRule.field == "alpha")

        mode.setRules(newRules: [rule])
        XCTAssertTrue(mode.rules.count == 1)

        let newRule = mode.rules.first!
        XCTAssertTrue(newRule.field == "epsilon")
    }

    func testModeUpdateRule() {
        var rule = SortRule(field: "epsilon ", displayName: "Epsilon", ascending: true)
        XCTAssertTrue(rule.ascending)
        rule.setAscending(value: false)
        XCTAssertFalse(rule.ascending)

        let mode = organizer.mode(at: 0)
        var alpha = mode.rules.first!
        XCTAssertFalse(alpha.ascending)

        mode.updateRule(for: "alpha", value: true)
        alpha = mode.rules.first!
        XCTAssertTrue(alpha.ascending)
    }

    func testDescriptors() {
        let descriptors = organizer.mode(at: 1).descriptors

        XCTAssertTrue(descriptors.count == 2)

        var descriptor = descriptors[0]
        XCTAssertTrue(descriptor.key == "gamma")
        XCTAssertFalse(descriptor.ascending)

        descriptor = descriptors[1]
        XCTAssertTrue(descriptor.key == "delta")
        XCTAssertTrue(descriptor.ascending)
    }

}
