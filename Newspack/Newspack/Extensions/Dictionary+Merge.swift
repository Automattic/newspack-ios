import Foundation

extension Dictionary where Key == String, Value == AnyObject {
    func mergedWith(_ dict:[String: AnyObject]) -> [String: AnyObject] {
        return self.merging(dict) { (current, _) in current }
    }
}
