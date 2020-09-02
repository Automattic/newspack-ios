import UIKit
import NewspackFramework

class ShareMediaViewController: UIViewController {

    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!

    let shadowManager = ShadowManager()
    var shadowSites: [ShadowSite]?
    var targetStory: ShadowStory?

    lazy var extracter: ShareExtractor = {
        guard let tmpDir = FolderManager.createTemporaryDirectory() else {
            // This should not happen.
            fatalError()
        }
        return ShareExtractor(extensionContext: self.extensionContext!, tempDirectory: tmpDir)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureStyle()
        configureNav()
        setupDataSource()

        extracter.loadShare { (extracted) in
            self.handleSharedItems(items: extracted)
        }
    }

    func configureStyle() {
        ShareAppearance.style(view: view, tableView: tableView)
    }

    func configureNav() {
        navigationItem.title = NSLocalizedString("Share", comment: "Verb. Title of the screen shown when sharing from another app to Newspack.")
    }

    func setupDataSource() {
        shadowSites = shadowManager.retrieveShadowSites()

        guard
            let currentSiteIdentifer = UserDefaults.shared.string(forKey: AppConstants.currentSiteIDKey),
            let currentStoryIdentifier = UserDefaults.shared.string(forKey: AppConstants.lastSelectedStoryFolderKey + currentSiteIdentifer)
        else {
                return
        }
        for site in shadowSites! {
            for story in site.stories {
                if story.uuid == currentStoryIdentifier {
                    targetStory = story
                    return
                }
            }
        }
    }

    func handleSharedItems(items: ExtractedShare) {
        print(items)
    }

    func processSharedItems() {

    }
}

// MARK: - Actions

extension ShareMediaViewController {

    @IBAction func handleSaveTapped(sender: UIBarButtonItem) {
        processSharedItems()
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    @IBAction func handleCancelTapped(sender: UIBarButtonItem) {
        let error = NSError(domain: "com.auttomattic.newspack.share", code: 0, userInfo: nil)
        extensionContext?.cancelRequest(withError: error)
    }

}

// MARK: - Table View Related

extension ShareMediaViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TargetSiteCellIdentifier", for: indexPath)

        ShareAppearance.style(cell: cell)

        cell.textLabel?.text = targetStory?.title
        cell.detailTextLabel?.text = NSLocalizedString("Change", comment: "Verb. An action. Indicates that a selection can be changed via an interaction.")
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tapped cell")

        guard let controller = UIStoryboard.init(name: "MainInterface", bundle: nil).instantiateViewController(withIdentifier: "StorySelectorViewController") as? StorySelectorViewController else {
            return
        }

        controller.delegate = self
        controller.shadowSites = shadowSites
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Share to:", comment: "A title. What follows is the destination of where things will be shared.")
    }

}

// MARK: - Story Selector Delegate

extension ShareMediaViewController: StorySelectorViewControllerDelegate {

    func didSelectStory(story: ShadowStory) {
        targetStory = story
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }

}
