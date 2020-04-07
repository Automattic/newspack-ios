import UIKit
import WordPressFlux

class FoldersViewController: UITableViewController {

    var folders = [URL]()
    var receipt: Any?

    override func viewDidLoad() {
        super.viewDidLoad()

        folders = StoreContainer.shared.folderStore.listFolders()

        receipt = StoreContainer.shared.folderStore.onChange { [weak self] in
            self?.folders = StoreContainer.shared.folderStore.listFolders()
            self?.tableView.reloadData()
        }
    }

    @IBAction func handleAddTapped(sender: Any) {
        let action = FolderAction.createFolder(path: "New Folder", addSuffix: true)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)

        let url = folders[indexPath.row]
        cell.textLabel?.text = url.lastPathComponent

        return cell
    }

}
