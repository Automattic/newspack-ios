import UIKit
import CoreData
import WordPressFlux
import WordPressUI

/// Displays a list of posts for the current PostList.
/// State is divided between the PostListStore which is responsible for syncing,
/// and identifying the current post list being worked on, and CoreData via an
/// NSFetchedResultsControllerDelegate which is responsible for detecting and
/// responding to changes in the data model.
///
class PostListViewController: UITableViewController {

    let cellIdentifier = "PostCellIdentifier"
    let sortField = "postID"

    // PostListStore receipt.
    var postListReceipt: Receipt?

    lazy var resultsController: NSFetchedResultsController<PostListItem> = {
        let fetchRequest = PostListItem.defaultFetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortField, ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataManager.shared.mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        resultsController.delegate = self
        postListReceipt = StoreContainer.shared.postListStore.onStateChange({ [weak self] state in
            self?.handlePostListStateChanged(oldState: state.0, newState: state.1)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureResultsController()
        syncIfNeeded()
    }

    func configureResultsController() {
        if let postList = StoreContainer.shared.postListStore.currentList {
            resultsController.fetchRequest.predicate = NSPredicate(format: "%@ in postLists", postList)
        }
        try? resultsController.performFetch()

        if resultsController.fetchedObjects?.count == 0 {
            let options = GhostOptions(reuseIdentifier: cellIdentifier, rowsPerSection: [3])
            tableView.displayGhostContent(options: options)
        }
        tableView.reloadData()
    }

    @IBAction func handleCreatePostButtonTapped() {
        guard let site = StoreContainer.shared.postListStore.currentList?.site else {
            return
        }
        let coordinator = EditCoordinator(postItem: nil, dispatcher: SessionManager.shared.sessionDispatcher, siteID: site.uuid)
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .editor) as! EditorViewController
        controller.coordinator = coordinator
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - Sync related methods.
extension PostListViewController {

    @objc func handleRefreshControl() {
        //TODO: Dispatch action rather than calling sync directly.
        StoreContainer.shared.postListStore.sync(force: true)
    }

    func syncIfNeeded() {
        //TODO: Dispatch action rather than calling sync directly.
        StoreContainer.shared.postListStore.sync()
    }
}

// MARK: - PostList State Related methods
extension PostListViewController {

    func handlePostListStateChanged(oldState: PostListState, newState: PostListState) {
        if oldState == .syncing {
            refreshControl?.endRefreshing()
            tableView.removeGhostContent()

        } else if oldState == .changingCurrentList {
            configureResultsController()
        }
    }
}

// MARK: - Table view data source
extension PostListViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return resultsController.fetchedObjects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let listItem = resultsController.object(at: indexPath)
        StoreContainer.shared.postStore.syncPostIfNecessary(postID: listItem.postID)

        let count = resultsController.fetchedObjects?.count ?? 0
        if count > 0 && indexPath.row > (count - 5)  {
            StoreContainer.shared.postListStore.syncNextPage()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let listItem = resultsController.object(at: indexPath)

        cell.accessoryView = nil
        cell.accessoryType = .disclosureIndicator

        if let post = listItem.post {
            cell.stopGhostAnimation()
            cell.isGhostableDisabled = true

            cell.textLabel?.text = post.titleRendered
            if listItem.syncing {
                cell.accessoryView = UIActivityIndicatorView(style: .gray)
            }
        } else {
            cell.isGhostableDisabled = false
            (cell as? PostCell)?.ghostAnimationWillStart()
            cell.startGhostAnimation()

            cell.textLabel?.text = ""
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listItem = resultsController.object(at: indexPath)
        let coordinator = EditCoordinator.init(postItem: listItem, dispatcher: SessionManager.shared.sessionDispatcher, siteID: listItem.site.uuid)
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .editor) as! EditorViewController
        controller.coordinator = coordinator
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - NSFetchedResultsController Methods
extension PostListViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet.init(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet.init(integer: sectionIndex), with: .automatic)
        default:
            break;
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // Seriously, Apple?
        // https://developer.apple.com/library/archive/releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/index.html
        //
        let fixedType: NSFetchedResultsChangeType = {
            guard type == .update && newIndexPath != nil && newIndexPath != indexPath else {
                return type
            }
            return .move
        }()

        let animation = UITableView.RowAnimation.none

        switch fixedType {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: animation)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: animation)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: animation)
            tableView.insertRows(at: [newIndexPath!], with: animation)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: animation)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
