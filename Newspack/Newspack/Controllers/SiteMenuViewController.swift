import UIKit
import WordPressFlux
import WPMediaPicker

struct SiteMenuRow {
    let title: String
    let callback: () -> Void
}

struct SiteMenuSection {
    let rows: [SiteMenuRow]
}

struct SiteMenuViewModel {
    let sections: [SiteMenuSection]
    init(presenter: UIViewController) {
        let postRow = SiteMenuRow(title: "Posts") {
            let controller = MainStoryboard.instantiateViewController(withIdentifier: .postList)
            presenter.navigationController?.pushViewController(controller, animated: true)
        }

        let mediaRow = SiteMenuRow(title: "Media") {
            let controller = MediaViewController()
            presenter.navigationController?.pushViewController(controller, animated: true)
        }

        let logoutRow = SiteMenuRow(title: "Log out") {
            guard let account = StoreContainer.shared.accountStore.currentAccount else {
                LogError(message: "SiteMenu: Attempted to log out but found no account.")
                //TODO: Handle no account.
                return
            }
            let action = AccountAction.removeAccount(uuid: account.uuid)
            SessionManager.shared.sessionDispatcher.dispatch(action)
        }

        let folderRow = SiteMenuRow(title: "New Story Folder") {
            let action = FolderAction.createFolder(path: "New Folder", addSuffix: true)
            SessionManager.shared.sessionDispatcher.dispatch(action)
        }

        let rows = [
            postRow,
            mediaRow,
            folderRow,
            logoutRow
        ]

        let section = SiteMenuSection(rows: rows)
        sections = [section]
    }

    func section(indexPath: IndexPath) -> SiteMenuSection? {
        return sections[indexPath.section]
    }

    func row(indexPath: IndexPath) -> SiteMenuRow? {
        return sections[indexPath.section].rows[indexPath.row]
    }
}


/// Provides a simple menu for interacting with the current site.
///
class SiteMenuViewController: UITableViewController {

    lazy var viewModel: SiteMenuViewModel = {
        return SiteMenuViewModel(presenter: self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SiteMenuCell", for: indexPath)

        if let row = viewModel.row(indexPath: indexPath) {
            cell.textLabel?.text = row.title
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = viewModel.row(indexPath: indexPath) else {
            return
        }
        row.callback()
    }

}
