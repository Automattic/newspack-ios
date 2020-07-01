import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class FolderStoreTests: BaseTest {

    var account: Account!
    var site: Site!
    var folderStore: FolderStore!
    var siteStore: SiteStore!

    override func setUp() {
        super.setUp()

        // Test account and site
        site = ModelFactory.getTestSite(context: CoreDataManager.shared.mainContext)

        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: site.url)
        site.account = account

        CoreDataManager.shared.saveContext(context: CoreDataManager.shared.mainContext)

        siteStore = SiteStore(dispatcher: testDispatcher, siteID: site.uuid)

        folderStore = FolderStore(dispatcher: testDispatcher, siteID: site.uuid)
    }

    override func tearDown() {
        super.tearDown()

        account = nil
        site = nil
    }

    func testCreateStoryFoldersForPaths() {
        // Create 10 story folders.
        let paths = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", "iota", "kappa"]

        let expect = expectation(description: "expect")
        folderStore.createStoryFoldersForPaths(paths: paths, onComplete: {
            CoreDataManager.shared.mainContext.refresh(self.site, mergeChanges: true)
            // One story folder was created by default, so account for it in the total.
            XCTAssertTrue(self.site.storyFolders.count == 11)
            expect.fulfill()
        })

        wait(for: [expect], timeout: 1)
    }

    func testSelectStoryOtherThan() {
        // Create 10 story folders.
        let paths = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", "iota", "kappa"]

        let expect = expectation(description: "expect")
        folderStore.createStoryFoldersForPaths(paths: paths, onComplete: {
            CoreDataManager.shared.mainContext.refresh(self.site, mergeChanges: true)
            // One story folder was created by default, so account for it in the total.
            XCTAssertTrue(self.site.storyFolders.count == 11)
            expect.fulfill()
        })

        wait(for: [expect], timeout: 1)

        let folders = folderStore.getStoryFolders()
        let delta = folders[4]
        folderStore.selectStoryFolder(folder: delta)
        XCTAssertTrue(folderStore.currentStoryFolderID == delta.uuid)

        // UUIDs for gamma, delta, epsilon
        let otherThanFolderUUIDs = folders[3...5].map { (folder) -> UUID in
            return folder.uuid
        }
        folderStore.selectStoryOtherThan(uuids: otherThanFolderUUIDs)

        let beta = folders[2]
        XCTAssertTrue(folderStore.currentStoryFolderID == beta.uuid)
    }

    func testDeleteStoryFolders() {
        // Create 10 story folders.
        let paths = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", "iota", "kappa"]

        let expect = expectation(description: "expect")
        folderStore.createStoryFoldersForPaths(paths: paths, onComplete: {
            CoreDataManager.shared.mainContext.refresh(self.site, mergeChanges: true)
            // One story folder was created by default, so account for it in the total.
            XCTAssertTrue(self.site.storyFolders.count == 11)
            expect.fulfill()
        })

        wait(for: [expect], timeout: 1)

        let folders = folderStore.getStoryFolders()

        // Get an array from an array slice
        let foldersToDelete = Array(folders[3...5])

        let expect1 = expectation(description: "expect1")
        folderStore.deleteStoryFolders(folders: foldersToDelete, onComplete: {
            CoreDataManager.shared.mainContext.refresh(self.site, mergeChanges: true)
            // One story folder was created by default, so account for it in the total.
            XCTAssertTrue(self.site.storyFolders.count == 8)

            for folder in foldersToDelete {
                XCTAssertTrue(folder.isDeleted)
            }

            expect1.fulfill()
        })
        wait(for: [expect1], timeout: 1)
    }
}
