import UIKit
import WordPressFlux

class AssetsViewController: UITableViewController {

    var items = [URL]()
    var receipt: Any?

    override func viewDidLoad() {
        super.viewDidLoad()

        items = StoreContainer.shared.folderStore.listCurrentStoryFolderContents()

        receipt = StoreContainer.shared.folderStore.onChange { [weak self] in
            self?.items = StoreContainer.shared.folderStore.listCurrentStoryFolderContents()
            self?.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssetCell", for: indexPath)

        let url = items[indexPath.row]
        cell.textLabel?.text = url.lastPathComponent

        return cell
    }

}
