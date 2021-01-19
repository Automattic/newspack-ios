import Foundation
import UIKit

class MainStoryboard {

    enum Identifier: String {
        typealias RawValue = String
        case initial = "InitialViewController"
        case siteMenu = "SiteMenuViewController"
        case storyNav = "StoryNavigationController"
        case folderList = "FoldersViewController"
        case assetsList = "AssetsViewController"
        case menu = "MenuViewController"
        case about = "AboutViewController"
        case web = "WebViewController"
        case folder = "FolderViewController"
        case imageView = "ImageViewController"
        case mediaDetails = "MediaDetailViewController"
        case textField = "TextFieldViewController"
        case textNote = "TextNoteViewController"
    }

    static func instantiateViewController(withIdentifier identifier: Identifier) -> UIViewController {
        return UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier.rawValue)
    }
}
