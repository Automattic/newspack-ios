import XCTest
@testable import Newspack

class DateTests: XCTestCase {

    func testDateFromGMTString() {
        let dateStringMissingZ = "2019-07-03T15:24:21"
        let dateStringWithZ = "2019-07-03T15:24:21Z"

        let date1 = Date.dateFromGMTString(string: dateStringMissingZ)
        XCTAssertNotNil(date1)

        let date2 = Date.dateFromGMTString(string: dateStringWithZ)
        XCTAssertNotNil(date2)

        XCTAssertEqual(date1, date2)
    }

}
