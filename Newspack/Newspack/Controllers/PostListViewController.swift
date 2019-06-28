import UIKit
import CoreData
import WordPressFlux

class PostListViewController: UITableViewController {

    var receipt:Receipt?

    lazy var resultsController: NSFetchedResultsController<Post> = {
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = Post.defaultFetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "postID", ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: context,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        receipt = StoreContainer.shared.postStore.onChange {
            self.handlePostsChanged()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = false
    }

    override func viewWillAppear(_ animated: Bool) {
        // Sync if needed.
        StoreContainer.shared.postStore.syncPosts()
        handlePostsChanged()
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

        let post = resultsController.object(at: indexPath)
        cell.textLabel?.text = post.titleRendered

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


    func handlePostsChanged() {
        try? resultsController.performFetch()
        tableView.reloadData()
    }
}


