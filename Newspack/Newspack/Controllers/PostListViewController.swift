import UIKit
import CoreData
import WordPressFlux
import WordPressUI

/// Displays a list of posts for the current PostQuery.
/// State is divided between the PostItemStore which is responsible for syncing,
/// and identifying the current post list being worked on, and CoreData via an
/// NSFetchedResultsControllerDelegate which is responsible for detecting and
/// responding to changes in the data model.
///
class PostListViewController: UITableViewController {

    let cellIdentifier = "PostCellIdentifier"
    var dataSource: PostListDataSource!

    // PostItemStore receipt.
    var postItemReceipt: Receipt?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        postItemReceipt = StoreContainer.shared.postItemStore.onStateChange({ [weak self] state in
            self?.handlePostItemStoreStateChanged(oldState: state.0, newState: state.1)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)

        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncIfNeeded()
    }

    @IBAction func handleCreatePostButtonTapped() {
        guard let uuid = StoreContainer.shared.postItemStore.currentSiteID else {
            return
        }
        let coordinator = EditCoordinator(postItem: nil, dispatcher: SessionManager.shared.sessionDispatcher, siteID: uuid)
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .editor) as! EditorViewController
        controller.coordinator = coordinator
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - Sync related methods.
extension PostListViewController {

    @objc func handleRefreshControl() {
        let dispatcher = SessionManager.shared.sessionDispatcher
        dispatcher.dispatch(PostAction.syncItems(force: true))
    }

    func syncIfNeeded() {
        let dispatcher = SessionManager.shared.sessionDispatcher
        dispatcher.dispatch(PostAction.syncItems(force: false))
    }
}

// MARK: - PostList State Related methods
extension PostListViewController {

    func handlePostItemStoreStateChanged(oldState: PostItemStoreState, newState: PostItemStoreState) {
        if oldState == .syncing {
            refreshControl?.endRefreshing()

        } else if oldState == .changingCurrentQuery {
            dataSource.configureResultsController()
        }
    }
}

// MARK: - Table view delegate methods
extension PostListViewController {

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let listItem = dataSource.object(at: indexPath)
        let dispatcher = SessionManager.shared.sessionDispatcher
        dispatcher.dispatch(PostAction.syncPost(postID: listItem.postID))

        let count = dataSource.count()
        if count > 0 && indexPath.row > (count - 5)  {
            dispatcher.dispatch(PostAction.syncNextPage)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listItem = dataSource.object(at: indexPath)
        let coordinator = EditCoordinator.init(postItem: listItem, dispatcher: SessionManager.shared.sessionDispatcher, siteID: listItem.siteUUID)
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .editor) as! EditorViewController
        controller.coordinator = coordinator
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - Datasource related
extension PostListViewController {

    func cellFor(tableView: UITableView, indexPath: IndexPath, listItem: PostItem) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .disclosureIndicator

        if let post = listItem.post {
            cell.textLabel?.text = post.titleRendered
            if listItem.syncing {
                cell.accessoryView = UIActivityIndicatorView(style: .medium)
            }
        } else {
            cell.textLabel?.text = ""
        }

        return cell
    }

    func configureDataSource() {
        dataSource = PostListDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, listItem) -> UITableViewCell? in
            return self?.cellFor(tableView: tableView, indexPath: indexPath, listItem: listItem)
        })
        dataSource.update()
    }

}

// MARK: - PostListDataSource
class PostListDataSource: UITableViewDiffableDataSource<PostListDataSource.Section, PostItem> {

    enum Section: CaseIterable {
        case main
    }

    var updatedItems = [PostItem]()

    // A results controller instance used to fetch StoryFolders.
    // The StoryFolderDataSource is its delegate so it can call update whenever
    // the results controller's content is changed.
    lazy var resultsController: NSFetchedResultsController<PostItem> = {
        let sortField = "postID"
        let fetchRequest = PostItem.defaultFetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortField, ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    // Hang on to a reference to the tableView. We'll use it to know when to
    // animate changes.
    weak var tableView: UITableView?

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<PostListDataSource.Section, PostItem>.CellProvider) {
        self.tableView = tableView
        super.init(tableView: tableView, cellProvider: cellProvider)

        resultsController.delegate = self

        configureResultsController()

        try? resultsController.performFetch()
    }

    func configureResultsController() {
        if let postQuery = StoreContainer.shared.postItemStore.currentQuery {
            resultsController.fetchRequest.predicate = NSPredicate(format: "%@ in postQueries", postQuery)
        }
    }

    /// Updates the current datasource snapshot. Changes are animated only if
    /// the tableView has a window (and is presumed visible).
    ///
    func update() {
        guard let items = resultsController.fetchedObjects else {
            return
        }
        var snapshot = NSDiffableDataSourceSnapshot<PostListDataSource.Section, PostItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        if updatedItems.count > 0 {
            snapshot.reloadItems(updatedItems)
        }
        updatedItems.removeAll()

        let shouldAnimate = tableView?.window != nil
        apply(snapshot, animatingDifferences: shouldAnimate, completion: nil)
    }

    func count() -> Int {
        return resultsController.fetchedObjects?.count ?? 0
    }

    func object(at indexPath: IndexPath) -> PostItem {
        return resultsController.object(at: indexPath)
    }
}

// MARK: - Fetched Results Controller Delegate methods
extension PostListDataSource: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        if type == .update {
            if let item = anObject as? PostItem {
                updatedItems.append(item)
            }
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        update()
   }

}
