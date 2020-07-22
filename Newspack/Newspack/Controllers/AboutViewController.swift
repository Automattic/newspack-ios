import UIKit
import SafariServices

class AboutViewController: UITableViewController {

    @IBOutlet var headerView: UIStackView!

    var rows = [AboutRow]()

    override func viewDidLoad() {
        super.viewDidLoad()

        buildRows()
        tableView.tableHeaderView = headerView
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SimpleTableViewCell.reuseIdentifier, for: indexPath)

        let row = rows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.accessoryType = row.accessoryType

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let year = Calendar.current.component(.year, from: Date())
        let localizedTitleText = NSLocalizedString("© %ld Automattic, Inc.", comment: "About View's Footer Text. The variable is the current year")
        return String(format: localizedTitleText, year)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = rows[indexPath.row]
        row.callback?()
    }

}

extension AboutViewController {

    func buildRows() {
        rows.removeAll()

        // Version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let format = NSLocalizedString("Version %@", comment: "The version of the app.  The %@ symbole is a placeholder for the version number.")
        let versionString = String(format: format, version)
        rows.append(AboutRow(title: versionString, callback: nil))

        // Newspack
        rows.append(AboutRow(title: NSLocalizedString("Newspack", comment: "Noun. A link to Newspack's web page."), callback: { [weak self] in
            self?.showNewspack()
        }))

        // Privacy
        rows.append(AboutRow(title: NSLocalizedString("Privacy", comment: "Noun. A link to a privacy policy."), callback: { [weak self] in
            self?.showPrivacy()
        }))

        // Terms
        rows.append(AboutRow(title: NSLocalizedString("Terms", comment: "Noun. A link to terms of use."), callback: { [weak self] in
            self?.showTerms()
        }))

        // Source
        rows.append(AboutRow(title: NSLocalizedString("Source Code", comment: "Noun. A link to the app's source code."), callback: { [weak self] in
            self?.showSource()
        }))

        // Acknowledgement
        rows.append(AboutRow(title: NSLocalizedString("Acknowledgements", comment: "Noun. A link that displays acknowledgements."), callback: { [weak self] in
            self?.showAcknowledgements()
        }))
    }

    func showNewspack() {
        displayWebPage(url: URL(string: "https://newspack.pub/"))
    }

    func showPrivacy() {
        displayWebPage(url: URL(string: "https://automattic.com/privacy/"))
    }

    func showTerms() {
        displayWebPage(url: URL(string: "https://wordpress.com/tos/"))
    }

    func showSource() {
        displayWebPage(url: URL(string: "https://github.com/Automattic/newspack-ios"))
    }

    func showAcknowledgements() {
        let url = Bundle.main.url(forResource: "acknowledgements", withExtension: "htm")
        displayWebPage(url: url)
    }

    func displayWebPage(url: URL?) {
        guard
            let url = url,
            let controller = MainStoryboard.instantiateViewController(withIdentifier: .web) as? WebViewController
        else {
            return
        }

        controller.load(url: url)
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true, completion: nil)
    }
}

struct AboutRow {
    let title: String
    let callback: (() -> Void)?
    var accessoryType: UITableViewCell.AccessoryType {
        return callback == nil ? .none : .disclosureIndicator
    }
}
