import UIKit
import Gridicons

class MenuViewController: UITableViewController {

    @IBOutlet var userView: UserView!

    var receipt: Any?

    lazy var menuDataSource: MenuDataSource = {
        return MenuDataSource(presenter: self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        receipt = StoreContainer.shared.accountDetailsStore.onChange {
            self.configureHeader()
        }

        configureInsets()
        configureHeader()
    }

    func configureHeader() {
        guard let details = StoreContainer.shared.accountStore.currentAccount?.details else {
            return
        }
        userView.configure(with: details.name, username: details.username, gravatar: details.avatarURL)
    }

    func configureInsets() {
        var insets = tableView.contentInset
        insets.top = 44.0
        tableView.contentInset = insets
        tableView.tableHeaderView = userView
    }
}

// MARK: - TableView Methods
extension MenuViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return menuDataSource.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuDataSource.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SimpleTableViewCell.reuseIdentifier, for: indexPath)

        if let row = menuDataSource.row(indexPath: indexPath) {
            cell.textLabel?.text = row.title
            cell.accessoryType = row.accessoryType
            cell.imageView?.image = row.icon
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = menuDataSource.row(indexPath: indexPath) else {
            return
        }
        row.callback()
    }
}

// MARK: - Data Source Related

struct MenuRow {
    let title: String
    let uuid: UUID?
    let callback: () -> Void

    var accessoryType: UITableViewCell.AccessoryType {
        // Site rows have UUIDs and should show disclosure icons.
        return uuid == nil ? .none : .disclosureIndicator
    }

    var icon: UIImage? {
        return uuid == nil ? nil : UIImage.gridicon(.globe, size: CGSize(width: 32, height: 32))
    }

    init(title: String, callback: (@escaping () -> Void)) {
        self.title = title
        self.callback = callback
        self.uuid = nil
    }

    init(title: String, uuid: UUID, callback: (@escaping () -> Void)) {
        self.title = title
        self.callback = callback
        self.uuid = uuid
    }

}

struct MenuSection {
    let rows: [MenuRow]
}

/// Acts as the data source for the menu.
///
class MenuDataSource {

    var sections = [MenuSection]()
    weak var presenter: UIViewController?

    init(presenter: UIViewController) {
        self.presenter = presenter

        updateSections()
    }

    func updateSections() {
        sections = [
            buildSitesSection(),
            buildSessionSection(),
            buildAboutSection()
        ]
    }

    private func buildSitesSection() -> MenuSection {
        var rows = [MenuRow]()

        let store = StoreContainer.shared.siteStore
        let sites = store.getSites()
        for site in sites {
            let row = MenuRow(title: site.title, uuid: site.uuid) {
                self.selectSite(uuid: site.uuid)
            }
            rows.append(row)
        }

        return MenuSection(rows: rows)
    }

    private func buildSessionSection() -> MenuSection {
        let row = MenuRow(title: NSLocalizedString("Log Out", comment: "Action. Log out of the app.")) {
            self.logout()
        }
        return MenuSection(rows: [row])
    }

    private func buildAboutSection()  -> MenuSection {
        let row = MenuRow(title: NSLocalizedString("About", comment: "About the app.")) { [weak self] in
            self?.showAbout()
        }
        return MenuSection(rows: [row])
    }

    func section(indexPath: IndexPath) -> MenuSection? {
        return sections[indexPath.section]
    }

    func row(indexPath: IndexPath) -> MenuRow? {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

extension MenuDataSource {

    func logout() {
        guard let account = StoreContainer.shared.accountStore.currentAccount else {
            LogError(message: "Attempted to log out but found no account.")
            return
        }
        let action = AccountAction.removeAccount(uuid: account.uuid)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    func showAbout() {
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .about)
        let navController = UINavigationController(rootViewController: controller)
        presenter?.present(navController, animated: true, completion: nil)
    }

    func selectSite(uuid: UUID) {
        LogInfo(message: "Select Site")
    }
}
