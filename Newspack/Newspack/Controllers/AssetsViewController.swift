import UIKit
import CoreData
import WordPressFlux

class AssetsViewController: UITableViewController {

    var dataSource: AssetDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDataSource()
    }

}

// MARK: - Actions

extension AssetsViewController {

    @IBAction func handleAddTapped(sender: Any) {
        let action = AssetAction.createAssetFor(text: "New Text Note")
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

}

// MARK: - TableViewDelegate methods
extension AssetsViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

// MARK: - DataSource related methods
extension AssetsViewController {

    func cellFor(tableView: UITableView, indexPath: IndexPath, storyAsset: StoryAsset) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssetCell", for: indexPath)
        cell.textLabel?.text = storyAsset.name
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func configureDataSource() {
        dataSource = AssetDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, storyAsset) -> UITableViewCell? in
            return self?.cellFor(tableView: tableView, indexPath: indexPath, storyAsset: storyAsset)
        })
        dataSource.update()
    }

}

// MARK: - AssetDataSource
class AssetDataSource: UITableViewDiffableDataSource<AssetDataSource.Section, StoryAsset> {

    enum Section: CaseIterable {
        case main
    }

    // Receipt so we can respond to any emitted changes in the AssetStore.
    var receipt: Any?

    // A results controller instance used to fetch StoryAssets.
    // The AssetDataSource is its delegate so it can call update whenever
    // the results controller's content is changed.
    lazy var resultsController: NSFetchedResultsController<StoryAsset> = {
        return StoreContainer.shared.assetStore.getResultsController()
    }()

    // Hang on to a reference to the tableView. We'll use it to know when to
    // animate changes.
    weak var tableView: UITableView?

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<AssetDataSource.Section, StoryAsset>.CellProvider) {
        self.tableView = tableView
        super.init(tableView: tableView, cellProvider: cellProvider)

        resultsController.delegate = self

        receipt = StoreContainer.shared.assetStore.onChange { [weak self] in
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
        var snapshot = NSDiffableDataSourceSnapshot<AssetDataSource.Section, StoryAsset>()
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
        guard let storyAsset = resultsController.fetchedObjects?[indexPath.row] else {
            return
        }
        if editingStyle == .delete {
            let action = AssetAction.deleteAsset(assetID: storyAsset.uuid)
            SessionManager.shared.sessionDispatcher.dispatch(action)
        }
    }

}

// MARK: - Fetched Results Controller Delegate methods
extension AssetDataSource: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        update()
   }

}

