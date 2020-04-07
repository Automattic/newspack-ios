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
        let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderCell

        let url = folders[indexPath.row]
        cell.textField.text = url.lastPathComponent
        cell.textChangedHandler = { text in
            self.handleFolderNameChanged(indexPath: indexPath, newName: text)
        }

        return cell
    }

    func handleFolderNameChanged(indexPath: IndexPath, newName: String?) {
        guard let name = newName else {
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }
        let folder = folders[indexPath.row]
        let action = FolderAction.renameFolder(folder: folder, name: name)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

}

class FolderCell: UITableViewCell {
    @IBOutlet var textField: UITextField!
    var textChangedHandler: ((String?) -> Void)?
}

extension FolderCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textChangedHandler?(textField.text)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
