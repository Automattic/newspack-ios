
import XCTest
@testable import Newspack

class DictionaryMergeTests: XCTestCase {

    func testDictionaryMergedWith() {

        let a = ["one"] as AnyObject
        let b = NSNumber(integerLiteral: 2)
        let c = NSAttributedString(string: "three")
        let d = NSNumber(integerLiteral: 4)

        let foo: [String: AnyObject] = [
            "one": a,
            "two" : b
        ]

        let bar: [String: AnyObject] = [
            "three": c,
            "four": d
        ]

        let baz = foo.mergedWith(bar)

        XCTAssertTrue(baz["one"] === a)
        XCTAssertTrue(baz["two"] === b)
        XCTAssertTrue(baz["three"] === c)
        XCTAssertTrue(baz["four"] === d)
    }

}
