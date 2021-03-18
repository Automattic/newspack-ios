import UIKit
import CoreData
import WordPressFlux
import NewspackFramework

class AssetsViewController: ToolbarViewController, UITableViewDelegate {

    struct Constants {
        static let edit = NSLocalizedString("Edit", comment: "Verb. Title of a control to enable editing.")
        static let done = NSLocalizedString("Done", comment: "Verb (past participle). Title of a control to disable editing when finished.")
    }

    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var directionButton: UIButton!
    @IBOutlet var tableView: UITableView!

    private var dataSource: AssetDataSource!
    private let refreshControl = UIRefreshControl()
    private var syncReceipt: Any?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDataSource()
        configureSortControl()
        configureNavbar()
        configureStyle()
        configureTableView()
        configureSyncListener()
    }

    func configureTableView() {
        tableView.register(UINib(nibName: "TextNoteTableViewCell", bundle: nil), forCellReuseIdentifier: TextNoteTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: PhotoTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "VideoTableViewCell", bundle: nil), forCellReuseIdentifier: VideoTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "AudioTableViewCell", bundle: nil), forCellReuseIdentifier: AudioTableViewCell.reuseIdentifier)

        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefreshControl(sender:)), for: .valueChanged)
    }

    func configureDataSource() {
        dataSource = AssetDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, objectID) -> UITableViewCell? in
            return self?.cellFor(tableView: tableView, indexPath: indexPath)
        })
    }

    func configureSortControl() {
        let assetStore = StoreContainer.shared.assetStore
        guard let rule = assetStore.sortOrganizer.selectedMode.rules.first else {
            return
        }

        sortControl.removeAllSegments()
        for (index, mode) in assetStore.sortOrganizer.modes.enumerated() {
            sortControl.insertSegment(withTitle: mode.title, at: index, animated: false)
        }

        sortControl.selectedSegmentIndex = assetStore.sortOrganizer.selectedIndex

        configureDirectionButton(ascending: rule.ascending)
    }

    func configureNavbar() {
        guard let currentStory = StoreContainer.shared.folderStore.currentStoryFolder else {
            return
        }
        navigationItem.title = currentStory.name
    }

    func configureStyle() {
        Appearance.style(view: view, tableView: tableView)
    }

    func configureDirectionButton(ascending: Bool) {
        let image: UIImage = ascending ? .gridicon(.chevronUp) : .gridicon(.chevronDown)
        directionButton.setImage(image, for: .normal)
    }

    func configureSyncListener() {
        syncReceipt = SyncCoordinator.shared.onChange { [weak self] in
            self?.handleSyncStateChange()
        }
    }

}

// MARK: - Actions

extension AssetsViewController {

    @IBAction func handleSortChanged(sender: UISegmentedControl) {
        let action = AssetAction.sortMode(index: sortControl.selectedSegmentIndex)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        tableView.isEditing = false

        // refresh data source.
        dataSource.refresh()
    }

    @IBAction func handleDirectionButtonTapped(sender: UIButton) {
        let assetStore = StoreContainer.shared.assetStore
        guard let rule = assetStore.sortOrganizer.selectedMode.rules.first else {
            return
        }
        dataSource.updateSort(ascending: !rule.ascending)
        configureDirectionButton(ascending: !rule.ascending)
    }

    @objc func handleRefreshControl(sender: UIRefreshControl) {
        let action = SyncAction.syncAssets
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    func handleSyncStateChange() {
        if !SyncCoordinator.shared.syncingAssets {
            refreshControl.endRefreshing()
        }
    }

    func handleCellSyncAction(uuid: UUID) {
        let action = AssetAction.flagToUpload(assetID: uuid)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

}

// MARK: - Cell Actions

extension AssetsViewController {

    func showMediaDetail(asset: StoryAsset) {
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .mediaDetails) as! MediaDetailViewController
        controller.asset = asset
        navigationController?.pushViewController(controller, animated: true)
    }

    func showTextNoteDetail(asset: StoryAsset) {
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .textNote) as! TextNoteViewController
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
        case .image, .video:
            showMediaDetail(asset: asset)
            return
        case .textNote:
            showTextNoteDetail(asset: asset)
        default:
            break
        }
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
        cell.configure(photo: storyAsset, image: image, callback: { [weak self] uuid in
            self?.handleCellSyncAction(uuid: uuid)
        })
        return cell
    }

    func configureVideoCell(tableView: UITableView, indexPath: IndexPath, storyAsset: StoryAsset) -> VideoTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: VideoTableViewCell.self, for: indexPath)

        let image = thumbnail(from: storyAsset, size: VideoTableViewCell.imageSize)
        cell.configure(video: storyAsset, image: image, callback: { [weak self] uuid in
            self?.handleCellSyncAction(uuid: uuid)
        })
        return cell
    }

    func configureAudioCell(tableView: UITableView, indexPath: IndexPath, storyAsset: StoryAsset) -> AudioTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: AudioTableViewCell.self, for: indexPath)

        cell.configure(audio: storyAsset, callback: { [weak self] uuid in
            self?.handleCellSyncAction(uuid: uuid)
        })
        return cell
    }

    func thumbnail(from asset: StoryAsset, size: CGSize) -> UIImage? {
        guard let bookmark = asset.bookmark else {
            return nil
        }

        if asset.assetType == .image {
            return ImageMaker.imageFromImageFile(at: bookmark, size: size, identifier: asset.uuid.uuidString)

        } else if asset.assetType == .video {
            return ImageMaker.imageFromVideoFile(at: bookmark, size: size, identifier: asset.uuid.uuidString)
        }

        return nil
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

    // Hang on to a reference to the tableView. We'll use it to know when to
    // animate changes.
    weak var tableView: UITableView?

    private var sorting = false

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<String, NSManagedObjectID>.CellProvider) {
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
    /// - Returns: A story asset instance.
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

    func updateSort(ascending: Bool) {
        let action = AssetAction.sortDirection(ascending: ascending)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        // Set the sorting flag so we animate any changes.
        sorting = true

        resultsController.fetchRequest.sortDescriptors = StoreContainer.shared.assetStore.sortOrganizer.selectedMode.descriptors
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
        apply(snapshot, animatingDifferences: sorting, completion: nil)
        sorting = false
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

}

// MARK: - Fetched Results Controller Delegate methods

extension AssetDataSource: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        update(snapshot: snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>)
    }

}
