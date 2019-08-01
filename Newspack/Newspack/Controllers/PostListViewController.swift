import UIKit
import CoreData
import WordPressFlux

class PostListViewController: UITableViewController {

    var receipt:Receipt?

    lazy var resultsController: NSFetchedResultsController<PostListItem> = {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = PostListItem.defaultFetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "postID", ascending: false)]

        // TODO: See if there is a way to make this not an optional.  In practice it should never be one (unless logged out).
        // Maybe log if its not found?
        if let postList = StoreContainer.shared.postListStore.currentList {
            fetchRequest.predicate = NSPredicate(format: "%@ in postLists", postList)
        }

        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: context,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        resultsController.delegate = self
        receipt = StoreContainer.shared.postListStore.onChange {
            self.handlePostListItemChanged()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = false
    }

    override func viewWillAppear(_ animated: Bool) {
        // Sync if needed.
        StoreContainer.shared.postListStore.syncItems()
        try? resultsController.performFetch()
        tableView.reloadData()
    }

    // MARK: - Table view data source

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
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCellIdentifier", for: indexPath)

        configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let listItem = resultsController.object(at: indexPath)
        if let post = listItem.post {
            cell.textLabel?.text = post.titleRendered
        } else {
            // TODO show skeleton/ghost cell
            cell.textLabel?.text = "loading... \(indexPath.row)"
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func handlePostListItemChanged() {
        if let postList = StoreContainer.shared.postListStore.currentList {
            resultsController.fetchRequest.predicate = NSPredicate(format: "%@ in postLists", postList)
        }
        try? resultsController.performFetch()
        tableView.reloadData()
    }
}

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
