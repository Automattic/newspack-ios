import UIKit
import CoreData
import WordPressFlux

class AssetsViewController: ToolbarViewController, UITableViewDelegate {

    struct Constants {
        static let edit = NSLocalizedString("Edit", comment: "Verb. Title of a control to enable editing.")
        static let done = NSLocalizedString("Done", comment: "Verb (past participle). Title of a control to disable editing when finished.")
    }

    @IBOutlet var editButton: UIButton!
    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var syncButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!

    private var dataSource: AssetDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCells()
        configureDataSource()
        configureSortControl()
        configureNavbar()
        configureStyle()
        configureEditButton()
        tableView.tableFooterView = UIView()
    }

    func configureCells() {
        tableView.register(UINib(nibName: "TextNoteTableViewCell", bundle: nil), forCellReuseIdentifier: TextNoteTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: PhotoTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "VideoTableViewCell", bundle: nil), forCellReuseIdentifier: VideoTableViewCell.reuseIdentifier)
    }

    func configureDataSource() {
        dataSource = AssetDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, objectID) -> UITableViewCell? in
            return self?.cellFor(tableView: tableView, indexPath: indexPath)
        })
    }

    func configureSortControl() {
        let assetStore = StoreContainer.shared.assetStore

        sortControl.removeAllSegments()
        for (index, mode) in assetStore.sortOrganizer.modes.enumerated() {
            sortControl.insertSegment(withTitle: mode.title, at: index, animated: false)
        }

        sortControl.selectedSegmentIndex = assetStore.sortOrganizer.selectedIndex
    }

    func configureNavbar() {
        guard let currentStory = StoreContainer.shared.folderStore.currentStoryFolder else {
            return
        }
        navigationItem.title = currentStory.name
        syncButton.image = .gridicon(.cloudUpload)
    }

    func configureStyle() {
        Appearance.style(view: view, tableView: tableView)
    }

    func configureEditButton() {
        let title = tableView.isEditing ? Constants.done : Constants.edit
        editButton.setTitle(title, for: .normal)
        editButton.isHidden = !dataSource.isSortable
    }

}

// MARK: - Actions

extension AssetsViewController {

    @IBAction func handleSortChanged(sender: UISegmentedControl) {
        let action = AssetAction.sortMode(index: sortControl.selectedSegmentIndex)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        tableView.isEditing = false
        configureEditButton()

        // refresh data source.
        dataSource.refresh()
    }

    @IBAction func handleToggleEditing(sender: UIButton) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
        } else if StoreContainer.shared.assetStore.canSortAssets {
            tableView.setEditing(true, animated: true)
        }
        configureEditButton()
    }

    @IBAction func handleSyncTapped(sender: UIBarButtonItem) {
        LogDebug(message: "tapped sync")
    }

}

// MARK: - Cell Actions

extension AssetsViewController {

    func showImageDetail(asset: StoryAsset) {
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .photoDetails) as! PhotoDetailViewController
        controller.asset = asset
        navigationController?.pushViewController(controller, animated: true)
    }

}

// MARK: - TableViewDelegate methods

extension AssetsViewController {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        let asset = dataSource.object(at: indexPath)

        switch asset.assetType {
        case .image:
            showImageDetail(asset: asset)
            return
        default:
            break
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

    func cellFor(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let asset = dataSource.object(at: indexPath)
        switch asset.assetType {
        case .textNote:
            return configureTextCell(tableView: tableView, indexPath: indexPath, storyAsset: asset)
        case .image:
            return configurePhotoCell(tableView: tableView, indexPath: indexPath, storyAsset: asset)
        case .video:
            return configureVideoCell(tableView: tableView, indexPath: indexPath, storyAsset: asset)
        case .audioNote:
            return configureAudioCell(tableView: tableView, indexPath: indexPath, storyAsset: asset)
        }
    }

    func configureTextCell(tableView: UITableView, indexPath: IndexPath, storyAsset: StoryAsset) -> TextNoteTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: TextNoteTableViewCell.self, for: indexPath)
        cell.configure(note: storyAsset)
        return cell
    }

    func configurePhotoCell(tableView: UITableView, indexPath: IndexPath, storyAsset: StoryAsset) -> PhotoTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: PhotoTableViewCell.self, for: indexPath)

        let image = thumbnail(from: storyAsset, size: PhotoTableViewCell.imageSize)
        cell.configure(photo: storyAsset, image: image)
        return cell
    }

    func configureVideoCell(tableView: UITableView, indexPath: IndexPath, storyAsset: StoryAsset) -> VideoTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: VideoTableViewCell.self, for: indexPath)

        let image = thumbnail(from: storyAsset, size: VideoTableViewCell.imageSize)
        cell.configure(video: storyAsset, image: image)
        return cell
    }

    func configureAudioCell(tableView: UITableView, indexPath: IndexPath, storyAsset: StoryAsset) -> AudioTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: AudioTableViewCell.self, for: indexPath)

        cell.configure(audio: storyAsset)
        return cell
    }

    func thumbnail(from asset: StoryAsset, size: CGSize) -> UIImage? {
        guard asset.assetType == .image else {
            return nil
        }

        if let thumb = ImageResizer.shared.resizedImage(identifier: asset.uuid.uuidString, size: size) {
            return thumb
        }

        let folderManager = SessionManager.shared.folderManager
        guard
            let bookmark = asset.bookmark,
            let url = folderManager.urlFromBookmark(bookmark: bookmark),
            let image = UIImage(contentsOfFile: url.path)
        else {
            return nil
        }

        return ImageResizer.shared.resizeImage(image: image, identifier: asset.uuid.uuidString, fillingSize: size)
    }
}

// MARK: - AssetDataSource

class AssetDataSource: UITableViewDiffableDataSource<String, NSManagedObjectID> {

    // Receipt so we can respond to any emitted changes in the AssetStore.
    private var receipt: Any?

    // A results controller instance used to fetch StoryAssets.
    // The AssetDataSource is its delegate so it can call update whenever
    // the results controller's content is changed.
    lazy var resultsController: NSFetchedResultsController<StoryAsset> = {
        return StoreContainer.shared.assetStore.getResultsController()
    }()

    var isSortable: Bool {
        return StoreContainer.shared.assetStore.canSortAssets
    }

    // Hang on to a reference to the tableView. We'll use it to know when to
    // animate changes.
    weak var tableView: UITableView?

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<Int, NSManagedObjectID>.CellProvider) {
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
    func object(at indexPath: IndexPath) -> StoryAsset {
        return resultsController.object(at: indexPath)
    }

    func refresh() {
        resultsController.delegate = nil
        resultsController = StoreContainer.shared.assetStore.getResultsController()
        resultsController.delegate = self
        try? resultsController.performFetch()
    }

    /// Updates the current datasource snapshot. Changes are animated only if
    /// the tableView has a window (and is presumed visible).
    ///
    func update(snapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>) {
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
        return isSortable
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

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        update(snapshot: snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>)
    }

}
