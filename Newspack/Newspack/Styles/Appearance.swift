import Foundation
import UIKit

class Appearance {

    /// Configure global UI appearance settings via the appearane API.
    ///
    static func configureGlobalAppearance() {
        let view = CellBackgroundView()
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

    static func style(view: UIView) {
        view.backgroundColor = .basicBackground
    }

    static func style(tableView: UITableView) {
        tableView.backgroundColor = .neutral(.shade0)
        tableView.separatorColor = .neutral(.shade10)
    }

    static func style(view: UIView, tableView: UITableView) {
        style(view: view)
        style(tableView: tableView)
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

// MARK: - Custom Views

// Apparently views used for a cell's background do not have their traits updated
// correctly. So we'll use this class to inspect the parent's traits to see if
// we're in light or dark mode.
class CellBackgroundView: UIView {

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let superView = newSuperview else {
            return
        }
        if superView.traitCollection.userInterfaceStyle == .dark {
            backgroundColor = .withColorStudio(.newspackBlue, shade: .shade80)
        } else {
            backgroundColor = .withColorStudio(.newspackBlue, shade: .shade20)
        }
    }

}
