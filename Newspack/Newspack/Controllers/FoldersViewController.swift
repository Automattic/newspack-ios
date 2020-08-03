import UIKit
import CoreData
import Gridicons
import WordPressFlux

class FoldersViewController: UIViewController, UITableViewDelegate {

    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var directionButton: UIButton!
    @IBOutlet var tableView: UITableView!

    @IBOutlet var textNoteButton: UIBarButtonItem!
    @IBOutlet var photoButton: UIBarButtonItem!
    @IBOutlet var cameraButton: UIBarButtonItem!
    @IBOutlet var audioNoteButton: UIBarButtonItem!

    private var dataSource: FolderDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDataSource()
        configureSortControls()
        configureNavbar()
        configureToolbar()
        configureStyle()
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setToolbarHidden(false, animated: false)
    }

    func configureDataSource() {
        dataSource = FolderDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, storyFolder) -> UITableViewCell? in
            return self?.cellFor(tableView: tableView, indexPath: indexPath, storyFolder: storyFolder)
        })
        dataSource.update()
    }

    func configureSortControls() {
        guard let rule = StoreContainer.shared.folderStore.sortMode.rules.first else {
            return
        }
        let rules = StoreContainer.shared.folderStore.sortRules

        var selectedIndex = 0
        for (index, item) in rules.enumerated() {
            sortControl.setTitle(item.displayName, forSegmentAt: index)
            if item.field == rule.field {
                selectedIndex = index
            }
        }

        sortControl.selectedSegmentIndex = selectedIndex

        configureDirectionButton(ascending: rule.ascending)
    }

    func configureNavbar() {
        navigationItem.title = NSLocalizedString("Stories", comment: "Noun. The title of the list of stories the reporter is working on.")
        navigationItem.leftBarButtonItem?.image = .gridicon(.menu)
        navigationItem.rightBarButtonItem?.image = .gridicon(.plus)
    }

    func configureToolbar() {
        textNoteButton.image = .gridicon(.posts)
        photoButton.image = .gridicon(.imageMultiple)
        cameraButton.image = .gridicon(.camera)
        audioNoteButton.image = .gridicon(.microphone)
    }

    func configureStyle() {
        Appearance.style(view: view, tableView: tableView)
    }

    func configureDirectionButton(ascending: Bool) {
        let image: UIImage = ascending ? .gridicon(.chevronUp) : .gridicon(.chevronDown)
        directionButton.setImage(image, for: .normal)
    }

}

// MARK: - Actions and Handlers

extension FoldersViewController {

    @IBAction func handleMenuButtonTapped(sender: UIBarButtonItem) {
        NotificationCenter.default.post(name: SidebarContainerViewController.toggleSidebarNotification, object: nil)
    }

    @IBAction func handleSortChanged(sender: UISegmentedControl) {
        guard let rule = StoreContainer.shared.folderStore.sortMode.rules.first else {
            return
        }
        let ascending = rule.ascending
        let rules = StoreContainer.shared.folderStore.sortRules
        let field = rules[sender.selectedSegmentIndex].field
        dataSource.sortBy(field: field, ascending: ascending)
    }

    @IBAction func handleDirectionButtonTapped(sender: UIButton) {
        guard let rule = StoreContainer.shared.folderStore.sortMode.rules.first else {
            return
        }

        dataSource.sortBy(field: rule.field, ascending: !rule.ascending)
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

}

extension FoldersViewController {

    @IBAction func handleTextNoteButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

    @IBAction func handlePhotoButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

    @IBAction func handleCameraButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

    @IBAction func handleAudioNoteButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
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

    func cellFor(tableView: UITableView, indexPath: IndexPath, storyFolder: StoryFolder) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FolderCell.reuseIdentifier, for: indexPath) as? FolderCell else {
            fatalError("Cannot create new cell")
        }
        Appearance.style(cell: cell)

        cell.textLabel?.text = storyFolder.name
        cell.accessoryType = .disclosureIndicator
        cell.selectedStory = storyFolder.uuid == StoreContainer.shared.folderStore.currentStoryFolderID

        return cell
    }

}

// MARK: - Folder Cell

class FolderCell: UITableViewCell {

    var selectedStory: Bool = false {
        didSet {
            textLabel?.textColor = selectedStory ? .textLink : .text
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        selectedStory = false
    }

}

// MARK: - FolderDataSource

class FolderDataSource: UITableViewDiffableDataSource<FolderDataSource.Section, StoryFolder> {

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

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<FolderDataSource.Section, StoryFolder>.CellProvider) {
        self.tableView = tableView
        super.init(tableView: tableView, cellProvider: cellProvider)

        resultsController.delegate = self

        receipt = StoreContainer.shared.folderStore.onChange { [weak self] in
            self?.tableView?.reloadData()
        }

        try? resultsController.performFetch()
    }

    func sortBy(field: String, ascending: Bool) {
        let action = FolderAction.sortBy(field: field, ascending: ascending)
        SessionManager.shared.sessionDispatcher.dispatch(action)

        resultsController.fetchRequest.sortDescriptors = StoreContainer.shared.folderStore.sortMode.descriptors
        try? resultsController.performFetch()

        sorting = true
        update()
        sorting = false
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

        apply(snapshot, animatingDifferences: sorting, completion: nil)
    }

    // MARK: - Overrides for cell deletion behaviors
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

}

// MARK: - Fetched Results Controller Delegate methods

extension FolderDataSource: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        update()
   }

}
