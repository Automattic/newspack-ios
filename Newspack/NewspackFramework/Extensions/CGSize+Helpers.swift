import UIKit

// Helper extension to make CGSize hashable so it can be used as dictionary keys.
//
extension CGSize: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return hasher.finalize()
    }

}
