import UIKit
import CoreData
import Gridicons
import WordPressFlux

class FoldersViewController: ToolbarViewController, UITableViewDelegate {

    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var directionButton: UIButton!
    @IBOutlet var tableView: UITableView!

    private var dataSource: FolderDataSource!
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
        tableView.register(UINib(nibName: "StoryTableViewCell", bundle: nil), forCellReuseIdentifier: StoryTableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefreshControl(sender:)), for: .valueChanged)
    }

    func configureDataSource() {
        dataSource = FolderDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, _) -> UITableViewCell? in
            return self?.cellFor(tableView: tableView, indexPath: indexPath)
        })
    }

    func configureSortControl() {
//        guard let rule = StoreContainer.shared.folderStore.sortMode.rules.first else {
//            return
//        }
//        let rules = StoreContainer.shared.folderStore.sortRules
//
//        var selectedIndex = 0
//        for (index, item) in rules.enumerated() {
//            sortControl.setTitle(item.displayName, forSegmentAt: index)
//            if item.field == rule.field {
//                selectedIndex = index
//            }
//        }
//
//        sortControl.selectedSegmentIndex = selectedIndex
//
//        configureDirectionButton(ascending: rule.ascending)
        let store = StoreContainer.shared.folderStore
        guard let rule = store.sortOrganizer.selectedMode.rules.first else {
            return
        }

        sortControl.removeAllSegments()
        for (index, mode) in store.sortOrganizer.modes.enumerated() {
            sortControl.insertSegment(withTitle: mode.title, at: index, animated: false)
        }

        sortControl.selectedSegmentIndex = store.sortOrganizer.selectedIndex

        configureDirectionButton(ascending: rule.ascending)
    }

    func configureNavbar() {
        navigationItem.title = NSLocalizedString("Stories", comment: "Noun. The title of the list of stories the reporter is working on.")
        navigationItem.leftBarButtonItem?.image = .gridicon(.menu)
        navigationItem.rightBarButtonItem?.image = .gridicon(.plus)
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

// MARK: - Actions and Handlers

extension FoldersViewController {

    @IBAction func handleMenuButtonTapped(sender: UIBarButtonItem) {
        NotificationCenter.default.post(name: SidebarContainerViewController.toggleSidebarNotification, object: nil)
    }

    @IBAction func handleSortChanged(sender: UISegmentedControl) {
        let action = FolderAction.sortMode(index: sortControl.selectedSegmentIndex)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        // refresh data source.
        dataSource.refresh()

//        guard let rule = StoreContainer.shared.folderStore.sortMode.rules.first else {
//            return
//        }
//        let ascending = rule.ascending
//        let rules = StoreContainer.shared.folderStore.sortRules
//        let field = rules[sender.selectedSegmentIndex].field
//        dataSource.sortBy(field: field, ascending: ascending)
    }

    @IBAction func handleDirectionButtonTapped(sender: UIButton) {
//        guard let rule = StoreContainer.shared.folderStore.sortMode.rules.first else {
//            return
//        }
//
//        dataSource.sortBy(field: rule.field, ascending: !rule.ascending)
//        configureDirectionButton(ascending: !rule.ascending)
        let store = StoreContainer.shared.folderStore
        guard let rule = store.sortOrganizer.selectedMode.rules.first else {
            return
        }
        dataSource.updateSort(ascending: !rule.ascending)
        configureDirectionButton(ascending: !rule.ascending)
    }

    @IBAction func handleAddTapped(sender: UIBarButtonItem) {
        presentFolderScreen(for: nil)
    }

    func editActionHandler(indexPath: IndexPath) {
        let storyFolder = dataSource.resultsController.object(at: indexPath)
        presentFolderScreen(for: storyFolder.uuid)
    }

    func deleteActionHandler(indexPath: IndexPath) {
        let storyFolder = dataSource.resultsController.object(at: indexPath)
        let action = FolderAction.deleteStoryFolder(folderID: storyFolder.uuid)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    func presentFolderScreen(for storyUUID: UUID?) {
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .folder) as! FolderViewController
        controller.storyUUID = storyUUID

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        self.present(navController, animated: true, completion: nil)
    }

    @objc func handleRefreshControl(sender: UIRefreshControl) {
        let action = SyncAction.syncStories
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    func handleSyncStateChange() {
        if !SyncCoordinator.shared.syncingStories {
            refreshControl.endRefreshing()
        }
    }

}

// MARK: - TableViewDelegate methods

extension FoldersViewController {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let storyFolder = dataSource.resultsController.fetchedObjects?[indexPath.row] else {
            return
        }

        let action = FolderAction.selectStoryFolder(folderID: storyFolder.uuid)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        let controller = MainStoryboard.instantiateViewController(withIdentifier: .assetsList)
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let editAction = UIContextualAction(style: .normal,
                                            title: NSLocalizedString("Edit", comment: "Verb. Name of a control to edit an object."),
                                            handler: { (action, view, completion) in
                                                self.editActionHandler(indexPath: indexPath)
                                                completion(true)
        })

        let deleteAction = UIContextualAction(style: .destructive,
                                            title: NSLocalizedString("Delete", comment: "Verb. Name of a control to delete an object."),
                                            handler: { (action, view, completion) in
                                                self.deleteActionHandler(indexPath: indexPath)
                                                completion(true)
        })

        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }

}

// MARK: - DataSource related methods

extension FoldersViewController {

    func cellFor(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StoryTableViewCell.reuseIdentifier, for: indexPath) as? StoryTableViewCell else {
            fatalError("Cannot create new cell")
        }

        let storyFolder = dataSource.object(at: indexPath)
        let current = storyFolder.uuid == StoreContainer.shared.folderStore.currentStoryFolderID
        cell.configure(story: storyFolder, current: current)

        return cell
    }

}

// MARK: - FolderDataSource

class FolderDataSource: UITableViewDiffableDataSource<String, NSManagedObjectID> {

    enum Section: CaseIterable {
        case main
    }

    // Receipt so we can respond to any emitted changes in the FolderStore.
    private var receipt: Any?

    // A results controller instance used to fetch StoryFolders.
    // The StoryFolderDataSource is its delegate so it can call update whenever
    // the results controller's content is changed.
    lazy var resultsController: NSFetchedResultsController<StoryFolder> = {
        return StoreContainer.shared.folderStore.getResultsController()
    }()

    // Hang on to a reference to the tableView. We'll use it to know when to
    // animate changes.
    weak var tableView: UITableView?

    private var sorting = false

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<Int, NSManagedObjectID>.CellProvider) {
        self.tableView = tableView
        super.init(tableView: tableView, cellProvider: cellProvider)

        resultsController.delegate = self

        receipt = StoreContainer.shared.folderStore.onChange { [weak self] in
            self?.tableView?.reloadData()
        }

        try? resultsController.performFetch()
    }

    /// A pass through method to get an entity from the backing results controller
    /// by the entities index path.
    ///
    /// - Parameter indexPath: The desired entity's index path.
    /// - Returns: A story folder instance.
    ///
    func object(at indexPath: IndexPath) -> StoryFolder {
        return resultsController.object(at: indexPath)
    }

    func refresh() {
        resultsController.delegate = nil
        resultsController = StoreContainer.shared.folderStore.getResultsController()
        resultsController.delegate = self
        try? resultsController.performFetch()
    }

    func updateSort(ascending: Bool) {
        let action = FolderAction.sortDirection(ascending: ascending)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        // Set the sorting flag so we animate any changes.
        sorting = true

        resultsController.fetchRequest.sortDescriptors = StoreContainer.shared.folderStore.sortOrganizer.selectedMode.descriptors
        try? resultsController.performFetch()
    }

    /// Updates the current datasource snapshot. Changes are animated only if
    /// the tableView has a window (and is presumed visible).
    ///
    func update(snapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>) {
        apply(snapshot, animatingDifferences: sorting, completion: nil)
        // Clear the sorting flag now that we're done.
        sorting = false
    }

    // MARK: - Overrides for cell deletion behaviors
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

}

// MARK: - Fetched Results Controller Delegate methods

extension FolderDataSource: NSFetchedResultsControllerDelegate {

      func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
         update(snapshot: snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>)
     }

}
