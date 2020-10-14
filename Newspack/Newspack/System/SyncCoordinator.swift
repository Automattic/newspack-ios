import Foundation
import NewspackFramework

/// An enum that defines the steps involved in syncing content, and the order in
/// which they should be performed.
///
enum SyncSteps {
    case syncRemoteStories
    case createRemoteStories
    case pushStoryUpdates
    case syncRemoteAssets
    case pushAssetUpdates
    case createRemoteAssets

    static func getSteps() -> [SyncSteps] {
        return [
        .syncRemoteStories,
        .createRemoteStories,
        .pushStoryUpdates,
        .syncRemoteAssets,
        .createRemoteAssets,
        .pushAssetUpdates
        ]
    }
}

class SyncCoordinator {

    private(set) var processing = false {
        didSet {
            if processing {
                LogInfo(message: "SyncCoordinator started processing.")
            } else {
                LogInfo(message: "SyncCoordinator ended processing.")
            }
        }
    }
    private var steps = SyncSteps.getSteps()
    private(set) var progressDictionary = [String: Any]()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init() {
        if Environment.isTesting() {
            return
        }
        listenForNotifications()
    }

    func process() {
        guard
            hasInitializedSession(),
            !processing
        else {
            return
        }
        guard !AppDelegate.shared.reconciler.processing else {
            return
        }

        processing = true

        steps = SyncSteps.getSteps()
        performNextStep()
    }

    private func performNextStep() {
        guard steps.count > 0 else {
            processing = false
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
            case .syncRemoteAssets:
                syncRemoteAssets()
            case .pushAssetUpdates:
                pushAssetUpdatesIfNeeded()
            case .createRemoteAssets:
                createNewAssetsIfNeeded()
        }
    }

    private func handleError(error: Error?) -> Bool {
        if let error = error {
            return handleErrors(errors: [error])
        }

        return false
    }

    private func handleErrors(errors: [Error]) -> Bool {
        guard errors.count > 0 else {
            return false
        }
        for error in errors {
            LogError(message: "\(error)")
        }
        return true
    }
}

// MARK: - Steps Methods

extension SyncCoordinator {

    /// Step 1: Sync the remote post backing stories.
    /// This will clean up any posts that need to be removed or whose title has
    /// changed. If successful it calls the next step.
    ///
    func syncAndProcessRemoteStories() {
        /// Get a list of post IDs from our stories.
        let store = StoreContainer.shared.folderStore
        store.syncAndProcessRemoteDrafts { [weak self] (error) in
            guard self?.handleError(error: error) == false else {
                self?.processing = false
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
                self?.processing = false
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
                self?.processing = false
                return
            }
            self?.performNextStep()
        }
    }

    /// Step 4: For each story, sync it's remote assets and check for any that have
    /// been modified (data not file).
    /// If an asset was deleted on the server, flag it locally to not sync but do not delete.
    /// Let the user manually delete, or manually upload again.
    ///
    func syncRemoteAssets() {
        let store = StoreContainer.shared.assetStore
        store.syncRemoteAssets { [weak self] (error) in
            guard self?.handleError(error: error) == false else {
                self?.processing = false
                return
            }
            self?.performNextStep()
        }
    }

    /// Step 5: For each story, check for assets that have local changes that need to be pushed.
    ///
    func pushAssetUpdatesIfNeeded() {
        let store = StoreContainer.shared.assetStore
        store.pushUpdatesToRemote { [weak self] (errors) in
            guard self?.handleErrors(errors: errors) == false else {
                self?.processing = false
                return
            }
            self?.performNextStep()
        }
    }

    /// Step 6: For each story, check for assets that need to be uploaded.
    ///
    func createNewAssetsIfNeeded() {
        let store = StoreContainer.shared.assetStore
        let batchSize = 3
        store.batchCreateRemoteMedia(batchSize: batchSize) { [weak self] (count, errors) in
            // Bail on any errors.
            guard self?.handleErrors(errors: errors) == false else {
                self?.processing = false
                return
            }

            if count < batchSize {
                self?.performNextStep()
                return
            }

            // Keep going until there are none left.
            self?.createNewAssetsIfNeeded()
        }
    }

}

// MARK: - Notification related

extension SyncCoordinator {

    /// Listen for system notifications that would tell us we might need to
    /// reconcile the file system and core data.
    /// Note that .didBecomeActiveNotification is dispatched more often than
    /// .willEnterForgroundNotification. If reconciliation is too frequent or
    /// aggressive we can try switching notifications.
    ///
    func listenForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleReconcilerStopped(notification:)), name: Reconciler.reconcilerDidStop, object: nil)
    }

    @objc
    func handleReconcilerStopped(notification: Notification) {
        process()
    }

}

// MARK: - Session related

extension SyncCoordinator {

    func hasInitializedSession() -> Bool {
        let sessionState = SessionManager.shared.state
        return sessionState == .initialized
    }

}
