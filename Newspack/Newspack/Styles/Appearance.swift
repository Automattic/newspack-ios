import Foundation
import UIKit

class Appearance {

    // MARK: - Tableview Styles

    static func style(view: UIView, tableView: UITableView) {
        view.backgroundColor = .basicBackground
        tableView.backgroundColor = .neutral(.shade0)
    }

    static func style(cell: UITableViewCell) {
        cell.backgroundColor = .basicBackground

        cell.textLabel?.font = .tableViewText
        cell.textLabel?.sizeToFit()

        cell.detailTextLabel?.font = .tableViewSubtitle
        cell.detailTextLabel?.sizeToFit()
        // we only set the text subtle color, so that system colors are used otherwise
        cell.detailTextLabel?.textColor = .textSubtle

        cell.imageView?.tintColor = .neutral(.shade30)
    }

}

// MARK: - Fonts

extension UIFont {

    static var tableViewText: UIFont {
        .preferredFont(forTextStyle: .callout)
    }

    static var tableViewSubtitle: UIFont {
        .preferredFont(forTextStyle: .callout)
    }

}
