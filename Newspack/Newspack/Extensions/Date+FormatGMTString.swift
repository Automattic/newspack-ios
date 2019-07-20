import Foundation

extension Date {
    static func dateFromGMTString(string: String) -> Date? {
        let formatter = ISO8601DateFormatter.init()
        formatter.formatOptions = .withInternetDateTime

        let str = string.hasSuffix("Z") ? string : string + "Z"

        return formatter.date(from: str)
    }
}
