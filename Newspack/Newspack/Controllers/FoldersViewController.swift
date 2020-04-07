import UIKit
import WordPressFlux

class FoldersViewController: UITableViewController {



    @IBAction func handleAddTapped(sender: Any) {
        let action = FolderAction.createFolder(path: "New Folder", addSuffix: true)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }
}
