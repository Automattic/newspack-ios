import UIKit
import Gridicons

/// Presents information about the app.
///
class AboutViewController: UITableViewController {

    @IBOutlet var closeButton: UIBarButtonItem!
    @IBOutlet var headerView: UIStackView!

    private var sections = [AboutSection]()
    private let headerHeight = CGFloat(132)

    override func viewDidLoad() {
        super.viewDidLoad()

        configureButtons()
        configureHeader()
        buildSections()
        configureStyle()
    }

    func configureButtons() {
        closeButton.image = UIImage.gridicon(.cross)
    }

    func configureHeader() {
        headerView.frame.size.height = headerHeight
        tableView.tableHeaderView = headerView
    }

    func configureStyle() {
        Appearance.style(view: view, tableView: tableView)
    }
}

// MARK: - Actions

extension AboutViewController {

    @IBAction func handleCloseButton(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - Table view data source

extension AboutViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SimpleTableViewCell.reuseIdentifier, for: indexPath)
        Appearance.style(cell: cell)

        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]

        cell.textLabel?.text = row.title

        if indexPath.section == 0 {
            cell.accessoryType = .none
            cell.selectionStyle = .none
        } else {
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == sections.count - 1 else {
            return nil
        }

        let year = Calendar.current.component(.year, from: Date())
        let localizedTitleText = NSLocalizedString("© %ld Automattic, Inc.", comment: "About View's Footer Text. The variable is the current year")
        return String(format: localizedTitleText, year)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]
        row.callback?()
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == sections.count - 1, let footer = view as? UITableViewHeaderFooterView else {
            return
        }
        Appearance.style(centeredFooter: footer)
    }

}

// MARK: - Setup our data model.

extension AboutViewController {

    func buildSections() {
        sections.removeAll()

        // Section 1 : Version
        var rows = [AboutRow]()

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let format = NSLocalizedString("Version %@", comment: "The version of the app.  The %@ symbole is a placeholder for the version number.")
        let versionString = String(format: format, version)
        rows.append(AboutRow(title: versionString, callback: nil))

        sections.append(AboutSection(rows: rows))

        // Section 2 : Links

        rows = [AboutRow]()

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

        sections.append(AboutSection(rows: rows))
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

struct AboutSection {
    let rows: [AboutRow]
}

struct AboutRow {
    let title: String
    let callback: (() -> Void)?
}
