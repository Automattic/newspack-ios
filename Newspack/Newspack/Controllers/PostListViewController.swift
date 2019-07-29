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
            fetchRequest.predicate = NSPredicate(format: "list == %@", postList)
        }

        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: context,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

//        resultsController.delegate = self
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCellIdentifier", for: indexPath)

        let listItem = resultsController.object(at: indexPath)
        if let post = listItem.post {
            cell.textLabel?.text = post.titleRendered
        } else {
            // TODO show skeleton/ghost cell
            cell.textLabel?.text = "loading... \(indexPath.row)"
        }

        return cell
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


