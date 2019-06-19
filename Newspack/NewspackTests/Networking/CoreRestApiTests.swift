import XCTest
@testable import Newspack

class CoreRestApiTests: XCTestCase {

    func testBaseEndpointForSite() {
        let one = "somesite.example.com"
        let two = "http://somesite.example.com"
        let three = "http://somesite.example.com/fubar"
        let four = "somesite.example.com/test/test/test/test.txt?arg1=foo&arg2=bar#anchor"

        XCTAssertEqual(WordPressCoreRestApi.baseEndpointForSite(one),
                       "https://public-api.wordpress.com/wp/v2/sites/somesite.example.com/")

        XCTAssertEqual(WordPressCoreRestApi.baseEndpointForSite(two),
                       "https://public-api.wordpress.com/wp/v2/sites/somesite.example.com/")

        XCTAssertEqual(WordPressCoreRestApi.baseEndpointForSite(three),
                       "https://public-api.wordpress.com/wp/v2/sites/somesite.example.com/fubar/")

        XCTAssertEqual(WordPressCoreRestApi.baseEndpointForSite(four),
                       "https://public-api.wordpress.com/wp/v2/sites/somesite.example.com/test/test/test/")
    }

}
