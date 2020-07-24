import UIKit
import CoreData
import WordPressFlux

class AssetsViewController: UIViewController, UITableViewDelegate {

    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var folderLabel: UILabel!
    @IBOutlet var syncButton: UIBarButtonItem!
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!

    @IBOutlet var textNoteButton: UIBarButtonItem!
    @IBOutlet var photoButton: UIBarButtonItem!
    @IBOutlet var videoButton: UIBarButtonItem!
    @IBOutlet var audioNoteButton: UIBarButtonItem!

    var dataSource: AssetDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDataSource()
        configureSortControl()
    }

}

// MARK: - Actions

extension AssetsViewController {

    @IBAction func handleSortChanged(sender: Any) {
        let action = AssetAction.sortMode(index: sortControl.selectedSegmentIndex)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        tableView.isEditing = false
        // refresh data source.
        dataSource.refresh()
    }

    @IBAction func handleToggleEditing(sender: Any) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
        } else if StoreContainer.shared.assetStore.canSortAssets {
            tableView.setEditing(true, animated: true)
        }
    }

}

extension AssetsViewController {

    @IBAction func handleTextNoteButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

    @IBAction func handlePhotoButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

    @IBAction func handleVideoButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

    @IBAction func handleAudioNoteButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

}

// MARK: - TableViewDelegate methods
extension AssetsViewController {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        guard let asset = dataSource.object(at: indexPath) else {
            return
        }

        // HACK HACK HACK: Just for testing. Tap on a cell to change which section it should be sorted to.
        asset.order = (asset.order == -1) ? 1 : -1
        CoreDataManager.shared.saveContext(context: asset.managedObjectContext!)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return tableView.isEditing ? .none : .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing ? false : true
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        // No droppiing into the unsorted section, so just return the source indexpath.
        if proposedDestinationIndexPath.section == 1 {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
}

// MARK: - DataSource related methods
extension AssetsViewController {

    func configureSortControl() {
        let assetStore = StoreContainer.shared.assetStore

        sortControl.removeAllSegments()
        for (index, mode) in assetStore.sortOrganizer.modes.enumerated() {
            sortControl.insertSegment(withTitle: mode.title, at: index, animated: false)
        }

        sortControl.selectedSegmentIndex = assetStore.sortOrganizer.selectedIndex
    }

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

    /// A pass through method to get an entity from the backing results controller
    /// by the entities index path.
    ///
    /// - Parameter indexPath: The desired entity's index path.
    /// - Returns: A story asset instance or nil.
    ///
    func object(at indexPath: IndexPath) -> StoryAsset? {
        return resultsController.object(at: indexPath)
    }

    func refresh() {
        resultsController.delegate = nil
        resultsController = StoreContainer.shared.assetStore.getResultsController()
        resultsController.delegate = self
        try? resultsController.performFetch()
        update()
    }

    /// Updates the current datasource snapshot. Changes are animated only if
    /// the tableView has a window (and is presumed visible).
    ///
    func update() {

        guard let sections = resultsController.sections else {
            return
        }
        var snapshot = NSDiffableDataSourceSnapshot<Int, StoryAsset>()

        for (i, section) in sections.enumerated() {
            snapshot.appendSections([i])
            guard let items = section.objects as? [StoryAsset] else {
                continue
            }
            snapshot.appendItems(items, toSection: i)
        }

        // Note: When animating cells, for some reason individual cells are not
        // redrawn, nor are section titles. (i.e. cellForRow is not being called).
        // Needs further exploration to figure out why.
        // Also, when animating it makes reording look a little weird.
        // For these reasons we'll disable animating.
        apply(snapshot, animatingDifferences: false, completion: nil)
    }

    // MARK: - Overrides for cell deletion behaviors
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        let storyAsset = resultsController.object(at: indexPath)
        let action = AssetAction.deleteAsset(assetID: storyAsset.uuid)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = resultsController.sections?[section] else {
            return ""
        }
        let mode = StoreContainer.shared.assetStore.sortOrganizer.selectedMode
        return mode.title(for: sectionInfo)
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let mode = StoreContainer.shared.assetStore.sortOrganizer.selectedMode
        return mode.rules.first?.field == "sorted"
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Here are the rules:
        // 1. unsorted items can be moved to sorted items.
        // 2. sorted items can not be moved to unsorted items.
        // 3. unsorted items do not change order within unsorted items.
        // 4. Update the sort order of all sorted items for simplicity sake.
        guard destinationIndexPath.section == 0 else {
            return
        }

        guard let sortedAssets = resultsController.sections?[0].objects as? [StoryAsset] else {
            LogError(message: "Tried to move a row but no sorted section found.")
            return
        }

        var newOrder = [UUID: Int]()

        let movedAsset = resultsController.object(at: sourceIndexPath)
        newOrder[movedAsset.uuid] = destinationIndexPath.row

        // We need to update the sort order of Assets. We can do this by looping
        // over sortedAssets and setting their order property to the index of
        // the loop, taking into account whether the modified row was previously
        // unsorted, or moved up or down in the sorted list.
        // We can get the range of affected rows and then add a modifier of 1 or -1
        // as appropriate.
        var modifier = 1
        var range: Range<Int>
        if sourceIndexPath.section == 1 {
            // We're inserting from unsorted into sorted.
            range = Range(destinationIndexPath.row...sortedAssets.count)
        } else if sourceIndexPath.row > destinationIndexPath.row {
            // We're moving from vertically lower in the list, to higher in the list.
            range = Range(destinationIndexPath.row...sourceIndexPath.row)
        } else {
            // We're moving from vertically higher in the list to lower in the list.
            modifier = -1
            range = Range(sourceIndexPath.row...destinationIndexPath.row)
        }

        for (index, asset) in sortedAssets.enumerated() {
            if asset == movedAsset {
                continue
            }
            newOrder[asset.uuid] = range.contains(index) ? index + modifier : index
        }

        let action = AssetAction.applyOrder(order: newOrder)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }
}

// MARK: - Fetched Results Controller Delegate methods
extension AssetDataSource: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        update()
   }

}
