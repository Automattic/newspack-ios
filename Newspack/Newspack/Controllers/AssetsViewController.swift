import UIKit
import CoreData
import WordPressFlux

class AssetsViewController: UITableViewController {

    @IBOutlet var sortControl: UISegmentedControl!

    var dataSource: AssetDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDataSource()

        // Temporary measure. The UI will change so right now this doesn't need to be pretty.
        let headerView = tableView.tableHeaderView!
        var frame = headerView.frame
        frame.size.height = 44.0
        headerView.frame = frame
        tableView.tableHeaderView = headerView
    }

}

// MARK: - Actions

extension AssetsViewController {

    @IBAction func handleAddTapped(sender: Any) {
        let action = AssetAction.createAssetFor(text: "New Text Note")
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    @IBAction func handleSortChanged(sender: Any) {
        print("changed")
    }

}

// MARK: - TableViewDelegate methods
extension AssetsViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        guard let asset = dataSource.object(at: indexPath) else {
            return
        }

        // HACK HACK HACK: Just for testing. Tap on a cell to change which section it should be sorted to.
        asset.order = (asset.order == -1) ? 1 : -1
        CoreDataManager.shared.saveContext(context: asset.managedObjectContext!)
    }
}

// MARK: - DataSource related methods
extension AssetsViewController {

    func cellFor(tableView: UITableView, indexPath: IndexPath, storyAsset: StoryAsset) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssetCell", for: indexPath)
        cell.textLabel?.text = storyAsset.name + " " + String(storyAsset.order)
        cell.detailTextLabel?.text = storyAsset.uuid.uuidString
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
class AssetDataSource: UITableViewDiffableDataSource<Int, StoryAsset> {

    // Receipt so we can respond to any emitted changes in the AssetStore.
    private var receipt: Any?

    // A results controller instance used to fetch StoryAssets.
    // The AssetDataSource is its delegate so it can call update whenever
    // the results controller's content is changed.
    lazy var resultsController: NSFetchedResultsController<StoryAsset> = {
        return StoreContainer.shared.assetStore.getResultsController()
    }()

    // Hang on to a reference to the tableView. We'll use it to know when to
    // animate changes.
    weak var tableView: UITableView?

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<Int, StoryAsset>.CellProvider) {
        self.tableView = tableView
        super.init(tableView: tableView, cellProvider: cellProvider)

        resultsController.delegate = self

        receipt = StoreContainer.shared.assetStore.onChange { [weak self] in
            self?.tableView?.reloadData()
        }

        try? resultsController.performFetch()
    }

    func object(at indexPath: IndexPath) -> StoryAsset? {
        return resultsController.object(at: indexPath)
    }

    /// Updates the current datasource snapshot. Changes are animated only if
    /// the tableView has a window (and is presumed visible).
    ///
    func update() {

        guard let sections = resultsController.sections else {
            return
        }
        var snapshot = NSDiffableDataSourceSnapshot<Int, StoryAsset>()

        for (i , section) in sections.enumerated() {
            snapshot.appendSections([i])
            guard let items = section.objects as? [StoryAsset] else {
                continue
            }
            snapshot.appendItems(items, toSection: i)
        }

        let shouldAnimate = false// tableView?.window != nil
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


    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Assets" : "Unsorted Assets"
    }
}

// MARK: - Fetched Results Controller Delegate methods
extension AssetDataSource: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        update()
   }

}
