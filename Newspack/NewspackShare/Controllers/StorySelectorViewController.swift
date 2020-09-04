import UIKit
import NewspackFramework

protocol StorySelectorViewControllerDelegate: UIViewController {
    func didSelectStory(story: ShadowStory)
}

class StorySelectorViewController: UITableViewController {

    var shadowSites: [ShadowSite]!
    var currentStory: ShadowStory!
    weak var delegate: StorySelectorViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureStyle()
    }

    func configureStyle() {
        ShareAppearance.style(view: view, tableView: tableView)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return shadowSites.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shadowSites[section].stories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCellIdentifier", for: indexPath)
        let story = shadowSites[indexPath.section].stories[indexPath.row]

        ShareAppearance.style(cell: cell)

        cell.textLabel?.text = story.title
        cell.accessoryType = story.uuid == currentStory.uuid ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return shadowSites[section].title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let story = shadowSites[indexPath.section].stories[indexPath.row]
        delegate?.didSelectStory(story: story)
    }

}
