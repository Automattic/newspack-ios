import UIKit
import WordPressShared

class UserView: UIStackView {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var usernameLable: UILabel!
    @IBOutlet var spacer: UIView!

    func configure(with name: String, username: String, gravatar: URL?) {
        nameLabel.text = name
        usernameLable.text = username

        if let url = gravatar, let photonURL = PhotonImageURLHelper.photonURL(with: imageView.frame.size, forImageURL: url) {
            imageView.downloadImage(from: photonURL)
        }
    }
}

class MenuViewController: UITableViewController {

    var receipt: Any?

    @IBOutlet var userView: UserView!

    lazy var menuDataSource: MenuDataSource = {
        return MenuDataSource(presenter: self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView = userView

        receipt = StoreContainer.shared.accountDetailsStore.onChange {
            self.configureHeader()
        }

        configureHeader()
    }

    func configureHeader() {
        guard let details = StoreContainer.shared.accountStore.currentAccount?.details else {
            return
        }

        userView.configure(with: details.name, username: details.username, gravatar: details.avatarURL)
    }

}

extension MenuViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return menuDataSource.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuDataSource.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)

        if let row = menuDataSource.row(indexPath: indexPath) {
            cell.textLabel?.text = row.title
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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menuDataSource.sections[section].title
    }
}

struct MenuRow {
    let title: String
    let callback: () -> Void
}

struct MenuSection {
    let rows: [MenuRow]
    let title: String?
}

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
            buildAppSection(),
            buildSessionSection()
        ]
    }

    private func buildSitesSection() -> MenuSection {
        var rows = [MenuRow]()

        let store = StoreContainer.shared.siteStore
        let sites = store.getSites()
        for site in sites {
            let row = MenuRow(title: site.title) {
                self.selectSite(uuid: site.uuid)
            }
            rows.append(row)
        }

        return MenuSection(rows: rows, title: nil)
    }

    private func buildAppSection()  -> MenuSection {
        var rows = [MenuRow]()

        var row = MenuRow(title: NSLocalizedString("About", comment: "About the app.")) {
            self.showAbout()
        }
        rows.append(row)

        row = MenuRow(title: NSLocalizedString("Terms", comment: "Refers to Terms of Use"), callback: {
            self.showTerms()
        })
        rows.append(row)

        row = MenuRow(title: NSLocalizedString("Privacy", comment: "Refers to Privacy Policy"), callback: {
            self.showPrivacy()
        })

        return MenuSection(rows: rows, title: NSLocalizedString("App", comment: "Noun. Abbrieviation of application. Refers to the app itself."))
    }

    private func buildSessionSection() -> MenuSection {
        let row = MenuRow(title: NSLocalizedString("Log Out", comment: "Action. Log out of the app.")) {
            self.logout()
        }
        return MenuSection(rows: [row], title: nil)
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
        LogInfo(message: "Show About")
    }

    func showTerms() {
        LogInfo(message: "Show Terms")
    }

    func showPrivacy() {
        LogInfo(message: "Show Privacy")
    }

    func selectSite(uuid: UUID) {
        LogInfo(message: "Select Site")
    }
}
