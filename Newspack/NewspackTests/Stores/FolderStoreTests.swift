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

    func createThreeFoldersForTesting() {
        // There should be 1 default folder.  Create three more.
        let paths = ["alpha", "beta", "gamma"]

        let expect = expectation(description: "expect")
        folderStore.createStoryFoldersForPaths(paths: paths, onComplete: {
            CoreDataManager.shared.mainContext.refresh(self.site, mergeChanges: true)
            expect.fulfill()
        })
        wait(for: [expect], timeout: 1)
    }

    func testGetStoryFolderCount() {
        createThreeFoldersForTesting()
        // There should be four due to there always being one default.
        XCTAssertTrue(folderStore.getStoryFolderCount() == 4)
    }

    func testGetStoryFolderByID() {
        createThreeFoldersForTesting()
        let folder = folderStore.getStoryFolders().last!
        let uuid = folder.uuid!

        let maybeFolder = folderStore.getStoryFolderByID(uuid: uuid)!
        XCTAssertTrue(folder.uuid == maybeFolder.uuid)
        XCTAssertTrue(folder.objectID == maybeFolder.objectID)
    }

    func testGetStoryFolderPostIDs() {
        createThreeFoldersForTesting()

        let folders = folderStore.getStoryFolders()
        for folder in folders {
            if folder.name == "alpha" {
                let expect = expectation(description: "expect")
                folderStore.assignPostIDAfterCreatingDraft(postID: 2, to: folder.uuid!, onComplete: {
                    expect.fulfill()
                })
                wait(for: [expect], timeout: 1)
            } else if folder.name == "gamma" {
                let expect = expectation(description: "expect")
                folderStore.assignPostIDAfterCreatingDraft(postID: 4, to: folder.uuid!, onComplete: {
                    expect.fulfill()
                })
                wait(for: [expect], timeout: 1)
            }
        }

        let postIDs = folderStore.getStoryFolderPostIDs()
        XCTAssertTrue(postIDs.contains(2))
        XCTAssertTrue(postIDs.contains(4))
        XCTAssertFalse(postIDs.contains(1))
        XCTAssertFalse(postIDs.contains(0))
    }

    func testGetStoryFolderByPostID() {
        createThreeFoldersForTesting()

        let folders = folderStore.getStoryFolders()
        for folder in folders {
            if folder.name == "alpha" {
                let expect = expectation(description: "expect")
                folderStore.assignPostIDAfterCreatingDraft(postID: 2, to: folder.uuid!, onComplete: {
                    expect.fulfill()
                })
                wait(for: [expect], timeout: 1)
            } else if folder.name == "gamma" {
                let expect = expectation(description: "expect")
                folderStore.assignPostIDAfterCreatingDraft(postID: 4, to: folder.uuid!, onComplete: {
                    expect.fulfill()
                })
                wait(for: [expect], timeout: 1)
            }
        }

        let alpha = folderStore.getStoryFolder(for: 2)!
        XCTAssertTrue(alpha.name == "alpha")

        let gamma = folderStore.getStoryFolder(for: 4)!
        XCTAssertTrue(gamma.name == "gamma")

        XCTAssertNil(folderStore.getStoryFolder(for: 1))
    }

    func testGetStoryFoldersNeedingRemote() {
        createThreeFoldersForTesting()
        // Stories with no postID and at least one asset need a remote.
        let assetStore = AssetStore(dispatcher: testDispatcher)
        let folders = folderStore.getStoryFolders()
        for folder in folders {
            let context = folder.managedObjectContext!
            if folder.name == "alpha" {
                let _ = assetStore.createAsset(type: .image, name: "alphaImage", mimeType: "image/png", url: nil, storyFolder: folder, in: context)
                try? context.save()

            } else if folder.name == "gamma" {
                let _ = assetStore.createAsset(type: .image, name: "gammaImage", mimeType: "image/png", url: nil, storyFolder: folder, in: context)
                try? context.save()
                let expect = expectation(description: "expect")
                folderStore.assignPostIDAfterCreatingDraft(postID: 4, to: folder.uuid!, onComplete: {
                    expect.fulfill()
                })
                wait(for: [expect], timeout: 1)
            }
        }

        let needsRemote = folderStore.getStoryFoldersNeedingRemote()
        XCTAssertTrue(needsRemote.count == 1)
        XCTAssertTrue(needsRemote.first!.name == "alpha")
    }

    func testGetStoryFoldersWithChanges() {
        createThreeFoldersForTesting()
        let folders = folderStore.getStoryFolders()
        for folder in folders {
            if folder.name == "alpha" {
                let expect = expectation(description: "expect")
                folderStore.updateStoryFolderName(uuid: folder.uuid, to: "delta", onComplete: {
                    expect.fulfill()
                })
                wait(for: [expect], timeout: 1)

            } else if folder.name == "gamma" {
                let expect = expectation(description: "expect")
                let uuid = folder.uuid!
                folderStore.assignPostIDAfterCreatingDraft(postID: 4, to: uuid, onComplete: {
                    self.folderStore.updateStoryFolderName(uuid: uuid, to: "zeta", onComplete: {
                        expect.fulfill()
                    })
                })
                wait(for: [expect], timeout: 1)
            }
        }

        // Delta should not be returned because there is no backing post ergo no remote changes.
        let withChanges = folderStore.getStoryFoldersWithChanges()
        XCTAssertTrue(withChanges.count == 1)
        XCTAssertTrue(withChanges.first!.name == "zeta")
    }

    func testUpdateSyncDate() {
        createThreeFoldersForTesting()

        let uuid = folderStore.getStoryFolders().first!.uuid!
        let expect1 = expectation(description: "expect")
        folderStore.updateSyncedDate(for: uuid, onComplete: {
            expect1.fulfill()
        })
        wait(for: [expect1], timeout: 1)

        var folder = folderStore.getStoryFolderByID(uuid: uuid)!
        let firstDate = folder.synced!

        let expect2 = expectation(description: "expect")
        folderStore.updateSyncedDate(for: uuid, onComplete: {
            expect2.fulfill()
        })
        wait(for: [expect2], timeout: 1)

        folder = folderStore.getStoryFolderByID(uuid: uuid)!
        let secondDate = folder.synced!

        XCTAssertTrue(secondDate > firstDate)

    }

    func testProcessRemoteDrafts() {
        createThreeFoldersForTesting()

        // Prep the folderse so there are post IDs for each.
        let folders = folderStore.getStoryFolders()
        let context = folders.first!.managedObjectContext!
        var alphaID: UUID?
        var betaID: UUID?
        var gammaID: UUID?
        var deltaID: UUID?
        var deltaName = ""

        for folder in folders {
            switch folder.name {
            case "alpha":
                folder.postID = 1
                alphaID = folder.uuid
            case "beta":
                folder.postID = 2
                betaID = folder.uuid
            case "gamma":
                folder.postID = 3
                gammaID = folder.uuid
            default:
                folder.postID = 4
                deltaID = folder.uuid
                deltaName = folder.name
            }
        }
        try? context.save()

        let stubs = [
            RemotePostStub(postID: 1, dateGMT: Date(), link: "alpha", modifiedGMT: Date(), status: "publish", title: "alpha", titleRendered: "alpha"),
            RemotePostStub(postID: 2, dateGMT: Date(), link: "beta", modifiedGMT: Date(), status: "draft", title: "beta", titleRendered: "beta"),
            RemotePostStub(postID: 3, dateGMT: Date(), link: "gamma", modifiedGMT: Date(), status: "trash", title: "gamma", titleRendered: "gamma"),
            RemotePostStub(postID: 4, dateGMT: Date(), link: "delta", modifiedGMT: Date(), status: "draft", title: "delta", titleRendered: "delta"),
        ]

        let expect = expectation(description: "expect")
        folderStore.processRemoteDrafts(postStubs: stubs) { (error) in
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        // Alpha and gamma should be deleted. (published or trashed)
        XCTAssertNil(folderStore.getStoryFolderByID(uuid: alphaID!))
        XCTAssertNil(folderStore.getStoryFolderByID(uuid: gammaID!))

        // Beta should still exist.
        XCTAssertNotNil(folderStore.getStoryFolderByID(uuid: betaID!))

        // Delta, the starting default folder, should have a new name.
        let folder = folderStore.getStoryFolderByID(uuid: deltaID!)!
        XCTAssertTrue(folder.name == "delta")
        XCTAssertTrue(folder.name != deltaName)
    }

}
