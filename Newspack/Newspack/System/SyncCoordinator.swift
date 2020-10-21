import Foundation
import NewspackFramework
import WordPressFlux

/// An enum that defines the steps involved in syncing content, and the order in
/// which they should be performed.
///
enum SyncSteps: Hashable {
    case syncRemoteStories
    case createRemoteStories
    case pushStoryUpdates
    case syncRemoteAssets
    case pushAssetUpdates
    case createRemoteAssets

    static func getSteps() -> [SyncSteps] {
        var steps = [SyncSteps]()
        steps.append(contentsOf: storySteps())
        steps.append(contentsOf: assetSteps())
        return steps
    }

    static func storySteps() -> [SyncSteps] {
        return [
        .syncRemoteStories,
        .createRemoteStories,
        .pushStoryUpdates
        ]
    }

    static func assetSteps() -> [SyncSteps] {
        return [
        .syncRemoteAssets,
        .createRemoteAssets,
        .pushAssetUpdates
        ]
    }

}

enum SyncCoordinatorState {
    case idle
    case processing
}

class SyncCoordinator: StatefulStore<SyncCoordinatorState> {

    static let shared = SyncCoordinator()
    static private let syncTaskIdentifier = "syncTaskIdentifier"

    var syncingStories: Bool {
        return Set(stepQueue).intersection(SyncSteps.storySteps()).count > 0
    }

    var syncingAssets: Bool {
        return Set(stepQueue).intersection(SyncSteps.assetSteps()).count > 0
    }

    private var stepQueue = [SyncSteps]() {
        didSet {
            if oldValue.count == 0 && stepQueue.count > 0 {
                LogInfo(message: "SyncCoordinator started processing.")
                configureBackgroundTask()
            }
            if oldValue.count > 0 && stepQueue.count == 0 {
                LogInfo(message: "SyncCoordinator stopped processing.")
                clearBackgroundTask()
            }
            state = stepQueue.count > 0 ? .processing : .idle
        }
    }

    private(set) var progressDictionary = [String: Any]()
    private var sessionReceipt: Any?
    private var dispatcherReceipt: Any?
    private var backgroundTaskID = UIBackgroundTaskIdentifier.invalid

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init() {
        super.init(initialState: .idle)

        if Environment.isTesting() {
            return
        }

        listenForNotifications()
        listenToSession()
    }

    private func listenToSession() {
        // Stop processing sync steps whenever the session changes.
        // Register for the new session dispatcher.
        sessionReceipt = SessionManager.shared.onChange {
            self.stepQueue = []
            self.refreshSessionListener()
        }
        refreshSessionListener()
    }

    private func refreshSessionListener() {
        dispatcherReceipt = SessionManager.shared.sessionDispatcher.register { action in
            self.handleAction(action: action)
        }
    }

    private func handleAction(action: Action) {
        guard let action = action as? SyncAction else {
            return
        }
        switch action {
        case .syncAll:
            process()
        case .syncStories:
            process(steps: SyncSteps.storySteps())
        case .syncAssets:
            process(steps: SyncSteps.assetSteps())
        }
    }

    func process(steps: [SyncSteps] = SyncSteps.getSteps()) {
        guard
            hasInitializedSession(),
            !AppDelegate.shared.reconciler.processing
        else {
            return
        }

        // Assign steps to the stepqueue to trigger onChanged event if needed.
        let enqueue = stepQueue + steps
        stepQueue = enqueue.uniqued()

        performNextStep()
    }

    private func performNextStep() {
        assert(Thread.isMainThread)
        guard stepQueue.count > 0 else {
            return
        }

        guard let step = stepQueue.first else {
            stepQueue = [] // Assign empty just in case.
            return
        }

        // Update the queue.
        stepQueue = Array(stepQueue.dropFirst())

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
    private func syncAndProcessRemoteStories() {
        /// Get a list of post IDs from our stories.
        let store = StoreContainer.shared.folderStore
        store.syncAndProcessRemoteDrafts { [unowned self] (error) in
            guard self.handleError(error: error) == false else {
                self.stepQueue = []
                return
            }
            self.performNextStep()
        }
    }

    /// Step 2: Create remote drafts for any stories that need one.
    /// Create remote drafts for any stories who are ready for a remote.
    ///
    private func createRemoteStoriesIfNeeded() {
        let store = StoreContainer.shared.folderStore
        store.createRemoteDraftsIfNeeded { [unowned self] (error) in
            guard self.handleError(error: error) == false else {
                self.stepQueue = []
                return
            }
            self.performNextStep()
        }
    }

    /// Step 3: Push changes to StoryFolders to the remote site.
    ///
    private func pushStoriesIfNeeded() {
        let store = StoreContainer.shared.folderStore
        store.pushUpdatesToRemote { [unowned self] (error) in
            guard self.handleError(error: error) == false else {
                self.stepQueue = []
                return
            }
            self.performNextStep()
        }
    }

    /// Step 4: For each story, sync it's remote assets and check for any that have
    /// been modified (data not file).
    /// If an asset was deleted on the server, flag it locally to not sync but do not delete.
    /// Let the user manually delete, or manually upload again.
    ///
    private func syncRemoteAssets() {
        let store = StoreContainer.shared.assetStore
        store.syncRemoteAssets { [unowned self] (error) in
            guard self.handleError(error: error) == false else {
                self.stepQueue = []
                return
            }
            self.performNextStep()
        }
    }

    /// Step 5: For each story, check for assets that have local changes that need to be pushed.
    ///
    private func pushAssetUpdatesIfNeeded() {
        let store = StoreContainer.shared.assetStore
        store.pushUpdatesToRemote { [unowned self] (errors) in
            guard self.handleErrors(errors: errors) == false else {
                self.stepQueue = []
                return
            }
            self.performNextStep()
        }
    }

    /// Step 6: For each story, check for assets that need to be uploaded.
    ///
    private func createNewAssetsIfNeeded() {
        let store = StoreContainer.shared.assetStore
        let batchSize = 3
        store.batchCreateRemoteMedia(batchSize: batchSize) { [unowned self] (count, errors) in
            // Bail on any errors.
            guard self.handleErrors(errors: errors) == false else {
                self.stepQueue = []
                return
            }

            if count < batchSize {
                self.performNextStep()
                return
            }

            // Keep going until there are none left.
            self.createNewAssetsIfNeeded()
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
    private func listenForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleReconcilerStopped(notification:)), name: Reconciler.reconcilerDidStop, object: nil)
    }

    @objc
    func handleReconcilerStopped(notification: Notification) {
        process()
    }

}

// MARK: - Session related

extension SyncCoordinator {

    private func hasInitializedSession() -> Bool {
        let sessionState = SessionManager.shared.state
        return sessionState == .initialized
    }

}

// MARK: - Long running task related

extension SyncCoordinator {

    /// Configures a long running task with the application.
    /// This should be called when staring to process sync steps. The companion
    /// clearBackgroundTasks method should be called when all steps are complete.
    /// This should let long media uploads have a better chance of completing if
    /// the app is backgrounded while an upload is underway.
    ///
    func configureBackgroundTask() {
        guard backgroundTaskID == .invalid else {
            // THere is already a long running task cnofigured. No need to configure another.
            return
        }

        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: SyncCoordinator.syncTaskIdentifier, expirationHandler: {
            self.clearBackgroundTask()
        })
    }

    func clearBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }

}
