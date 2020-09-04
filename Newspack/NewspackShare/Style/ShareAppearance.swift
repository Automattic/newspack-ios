import Foundation
import UIKit
import NewspackFramework

/// Contains appearance methos for the share extension. There is some duplication
/// with Appearance.swift used by the main app, but this is preferred over importing
/// that class into a framework (or here) along with its Gridicons dependency.
///
class ShareAppearance {

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
        cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
        cell.textLabel?.sizeToFit()

        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .callout)
        cell.detailTextLabel?.sizeToFit()
        // we only set the text subtle color, so that system colors are used otherwise
        cell.detailTextLabel?.textColor = .textSubtle
    }

    static func style(collectionHeader: CollectionHeaderView) {
        collectionHeader.backgroundColor = .neutral(.shade0)
        collectionHeader.textLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        collectionHeader.textLabel.textColor = .sectionLableTextColor
    }

}
