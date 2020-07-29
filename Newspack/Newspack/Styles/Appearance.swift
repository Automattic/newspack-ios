import Foundation
import UIKit

class Appearance {

    /// Configure global UI appearance settings via the appearane API.
    ///
    static func configureGlobalAppearance() {
        let view = UIView()
        view.backgroundColor = .cellBackgroundSelected
        UITableViewCell.appearance().selectedBackgroundView = view
    }

    // MARK: - UserView styles

    static func style(userView label: UILabel, imageView: UIImageView) {
        label.textColor = .neutral(.shade70)
        label.backgroundColor = .neutral(.shade0)

        label.font = .preferredFont(forTextStyle: .headline)

        imageView.backgroundColor = .placeholderImage
    }

    // MARK: - Tableview Styles

    static func style(view: UIView, tableView: UITableView) {
        view.backgroundColor = .basicBackground
        tableView.backgroundColor = .neutral(.shade0)
        tableView.separatorColor = .neutral(.shade10)
    }

    static func style(cell: UITableViewCell) {
        cell.backgroundColor = .cellBackground // semantic pass-thru to basicBackground.

        cell.textLabel?.textColor = .text
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
        footer.textLabel?.backgroundColor = .neutral(.shade0)
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
