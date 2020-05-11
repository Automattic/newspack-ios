import UIKit
import CoreData
import WordPressFlux

class FoldersViewController: UITableViewController {

    var dataSource: FolderDataSource!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDataSource()
    }
}

// MARK: - Actions and Handlers
extension FoldersViewController {

    @IBAction func handleAddTapped(sender: Any) {
        let action = FolderAction.createStoryFolder
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    func handleFolderNameChanged(indexPath: IndexPath, newName: String?) {
        guard let name = newName, let storyFolder = dataSource.resultsController.fetchedObjects?[indexPath.row] else {
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }

        let action = FolderAction.renameStoryFolder(folderID: storyFolder.uuid, name: name)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

}

// MARK: - TableViewDelegate methods
extension FoldersViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let storyFolder = dataSource.resultsController.fetchedObjects?[indexPath.row] else {
            return
        }

        let action = FolderAction.selectStoryFolder(folderID: storyFolder.uuid)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        let controller = MainStoryboard.instantiateViewController(withIdentifier: .assetsList)
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - DataSource related methods
extension FoldersViewController {

    func cellFor(tableView: UITableView, indexPath: IndexPath, storyFolder: StoryFolder) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FolderCell.reuseIdentifier, for: indexPath) as? FolderCell else {
            fatalError("Cannot create new cell")
        }

        cell.textField.text = storyFolder.name
        cell.textChangedHandler = { text in
            self.handleFolderNameChanged(indexPath: indexPath, newName: text)
        }
        cell.accessoryType = storyFolder.uuid == StoreContainer.shared.folderStore.currentStoryFolderID ? .detailDisclosureButton : .disclosureIndicator

        return cell
    }

    func configureDataSource() {
        dataSource = FolderDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, storyFolder) -> UITableViewCell? in
            return self?.cellFor(tableView: tableView, indexPath: indexPath, storyFolder: storyFolder)
        })
        dataSource.update()
    }

}

// MARK: - Folder Cell
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

// MARK: - FolderDataSource
class FolderDataSource: UITableViewDiffableDataSource<FolderDataSource.Section, StoryFolder> {

    enum Section: CaseIterable {
        case main
    }

    // Receipt so we can respond to any emitted changes in the FolderStore.
    var receipt: Any?

    // A results controller instance used to fetch StoryFolders.
    // The StoryFolderDataSource is its delegate so it can call update whenever
    // the results controller's content is changed.
    lazy var resultsController: NSFetchedResultsController<StoryFolder> = {
        return StoreContainer.shared.folderStore.getResultsController()
    }()

    // Hang on to a reference to the tableView. We'll use it to know when to
    // animate changes.
    weak var tableView: UITableView?

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<FolderDataSource.Section, StoryFolder>.CellProvider) {
        self.tableView = tableView
        super.init(tableView: tableView, cellProvider: cellProvider)

        resultsController.delegate = self

        receipt = StoreContainer.shared.folderStore.onChange { [weak self] in
            self?.tableView?.reloadData()
        }

        try? resultsController.performFetch()
    }

    /// Updates the current datasource snapshot. Changes are animated only if
    /// the tableView has a window (and is presumed visible).
    ///
    func update() {
        guard let items = resultsController.fetchedObjects else {
            return
        }
        var snapshot = NSDiffableDataSourceSnapshot<FolderDataSource.Section, StoryFolder>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        let shouldAnimate = tableView?.window != nil
        apply(snapshot, animatingDifferences: shouldAnimate, completion: nil)
    }

    // MARK: - Overrides for cell deletion behaviors
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let storyFolder = resultsController.fetchedObjects?[indexPath.row] else {
            return
        }
        if editingStyle == .delete {
            let action = FolderAction.deleteStoryFolder(folderID: storyFolder.uuid)
            SessionManager.shared.sessionDispatcher.dispatch(action)
        }
    }

}

// MARK: - Fetched Results Controller Delegate methods
extension FolderDataSource: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        update()
   }

}
