import UIKit

extension UITableViewCell {
    class var reuseIdentifier: String {
        return String(describing: self)
    }
}
