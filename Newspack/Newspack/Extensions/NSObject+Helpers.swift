import Foundation

extension NSObject {
    class var classnameWithoutNamespaces: String {
        return String(describing: self)
    }
}
