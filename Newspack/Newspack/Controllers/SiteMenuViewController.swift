import UIKit
import WordPressFlux

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
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PostListViewController")
            presenter.navigationController?.pushViewController(controller, animated: true)
        }

        let mediaRow = SiteMenuRow(title: "Media") {
            print( "TODO:")
        }

        let logoutRow = SiteMenuRow(title: "Log out") {
            guard let account = StoreContainer.shared.accountStore.currentAccount else {
                //TODO: Handle no account.
                return
            }
            let action = AccountAction.removeAccount(uuid: account.uuid)
            ActionDispatcher.global.dispatch(action)
        }

        let rows = [
            postRow,
            mediaRow,
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


class SiteMenuViewController: UITableViewController {

    lazy var viewModel: SiteMenuViewModel = {
        return SiteMenuViewModel(presenter: self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = false
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}