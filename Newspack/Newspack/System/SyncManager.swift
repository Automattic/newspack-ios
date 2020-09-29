import Foundation
import NewspackFramework

/// An enum that defines the steps involved in syncing content, and the order in
/// which they should be performed.
///
enum SyncSteps {
    case syncRemoteStories
    case createRemoteStories
    case pushStoryUpdates

    static func getSteps() -> [SyncSteps] {
        return [
        .syncRemoteStories,
        .createRemoteStories,
        .pushStoryUpdates
        ]
    }
}

/// TODO: Rename to SyncCoordinator and document.
class SyncManager {

    private(set) var isRunning = false
    private var steps = SyncSteps.getSteps()
    private(set) var progressDictionary = [String: Any]()

    func process() {
        guard
            SessionManager.shared.state == .initialized,
            !isRunning
        else {
            return
        }
        isRunning = true

        performNextStep()
    }

    private func performNextStep() {
        guard steps.count > 0 else {
            return
        }

        let step = steps.removeFirst()
        switch step {
            case .syncRemoteStories:
                syncAndProcessRemoteStories()
            case .createRemoteStories:
                createRemoteStoriesIfNeeded()
            case .pushStoryUpdates:
                pushStoriesIfNeeded()
        }
    }

    private func handleError(error: Error?) -> Bool {
        if let error = error {
            isRunning = false
            LogError(message: "\(error)")
            return true
        }
        return false
    }
}

// MARK: - Steps Methods

extension SyncManager {

    /// Step 1: Sync the remote post backing stories.
    /// This will clean up any posts that need to be removed or whose title has
    /// changed. If successful it calls the next step.
    ///
    func syncAndProcessRemoteStories() {
        /// Get a list of post IDs from our stories.
        let store = StoreContainer.shared.folderStore
        store.syncAndProcessRemoteDrafts { [weak self] (error) in
            guard self?.handleError(error: error) == false else {
                return
            }
            self?.performNextStep()
        }
    }

    /// Step 2: Create remote drafts for any stories that need one.
    /// Create remote drafts for any stories who are ready for a remote.
    ///
    func createRemoteStoriesIfNeeded() {
        let store = StoreContainer.shared.folderStore
        store.createRemoteDraftsIfNeeded { [weak self] (error) in
            guard self?.handleError(error: error) == false else {
                return
            }
            self?.performNextStep()
        }
    }

    /// Step 3: Push changes to StoryFolders to the remote site.
    ///
    func pushStoriesIfNeeded() {
        let store = StoreContainer.shared.folderStore
        store.pushUpdatesToRemote { [weak self] (error) in
            guard self?.handleError(error: error) == false else {
                return
            }
            self?.performNextStep()
        }
    }


    // sync remote asset info
    func syncRemoteAssets() {
        // TODO
        // for each story, sync it's remote assets
        // check for any that have been modified where we might need to reconcile the remote file
        // if an asset was deleted on the server, flag it locally to not sync but don't delete it.  Let the user manually delete or manually upload again. (move it into do not upload list)
    }

    // Upload assets that are stale or need to be uploaded.
    func pushAssetsIfNeeded() {
        // TODO
        // get assets that need uploading
        // record progress object in dictionary
        // upload individually
        // record IDs when finished
        // remove progress object from dictionary.  (maybe dispatch notification?)
    }

}
