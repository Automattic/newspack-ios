import Foundation
import UIKit

class Appearance {

    // MARK: - UserView styles

    static func style(userView label: UILabel, imageView: UIImageView) {
        label.textColor = .neutral(.shade70)

        label.font = .preferredFont(forTextStyle: UIFont.TextStyle.headline)
        imageView.backgroundColor = .placeholderImage
    }

    // MARK: - Tableview Styles

    static func style(view: UIView, tableView: UITableView) {
        view.backgroundColor = .basicBackground
        tableView.backgroundColor = .neutral(.shade0)
        tableView.separatorColor = .neutral(.shade10)
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

    static func style(centeredFooter footer: UITableViewHeaderFooterView) {
        footer.textLabel?.textColor = .textSubtle
        footer.textLabel?.textAlignment = .center
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
