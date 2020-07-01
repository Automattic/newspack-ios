import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class ReconcilerTests: BaseTest {

    var account: Account!
    var site: Site!
    var folderStore: FolderStore!
    var siteStore: SiteStore!

    var epsilon: URL!
    var zeta: URL!

    override func setUp() {
        super.setUp()

        // Test account and site
        site = ModelFactory.getTestSite(context: CoreDataManager.shared.mainContext)

        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: site.url)
        site.account = account

        CoreDataManager.shared.saveContext(context: CoreDataManager.shared.mainContext)
        StoreContainer.shared.resetStores(dispatcher: testDispatcher, site: site)

        var expect = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            return true
        }
        wait(for: [expect], timeout: 1)

        // Wait after initializing each store so it can handle its initial work.
        siteStore = StoreContainer.shared.siteStore
        folderStore = StoreContainer.shared.folderStore

        // Create four more story folders.
        expect = expectation(description: "expect")
        let paths = ["alpha", "beta", "gamma", "delta"]
        folderStore.createStoryFoldersForPaths(paths: paths, addSuffix: false) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        let folderManager = SessionManager.shared.folderManager
        // Delete folders for Gamma and Delta
        let urls = folderManager.enumerateFolders(url: folderManager.currentFolder)
        _ = urls.map { url in
            if ["gamma", "delta"].contains(url.lastPathComponent) {
                folderManager.deleteFolder(at: url)
            }
        }

        // Create folders for epsilon and zeta
        epsilon = folderManager.createFolderAtPath(path: "epsilon")
        zeta = folderManager.createFolderAtPath(path: "zeta")
    }

    override func tearDown() {
        super.tearDown()

        account = nil
        site = nil
        folderStore = nil
        siteStore = nil
        epsilon = nil
        zeta = nil
    }

    func testHasInconsistencies() {

        let recon = Reconciler()
        XCTAssertTrue(recon.hasInconsistencies())
    }

    func testReconcile() {
        // Maybe wait?
        let startingFolders = folderStore.getStoryFolders()
        XCTAssertTrue(startingFolders.count > 1)

        let recon = Reconciler()
        recon.reconcile()

        let expect = expectation(forNotification: .NSManagedObjectContextObjectsDidChange, object: CoreDataManager.shared.mainContext) { (_) -> Bool in
            return true
        }
        wait(for: [expect], timeout: 1)

        let folders = folderStore.getStoryFolders()
        // gamma and delta should no longer exist
        let deletedFolders = folders.filter { (folder) -> Bool in
            return ["gamma", "delta"].contains(folder.name)
        }
        XCTAssertTrue(deletedFolders.count == 0)

        // There should be story folders for epsilon and zeta
        let newFolders = folders.filter { (folder) -> Bool in
            return ["epsilon", "zeta"].contains(folder.name)
        }
        XCTAssertTrue(newFolders.count == 2)
    }

}
