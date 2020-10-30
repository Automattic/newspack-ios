import Foundation
import UIKit
import NewspackFramework

/// Responsible for resolving any differences between what is currently in the
/// file system with what is currently stored in core data.
///
class Reconciler {

    private var sessionReceipt: Any?
    private(set) var processing = false {
        didSet {
            if processing {
                NotificationCenter.default.post(name: .reconcilerDidStart, object: nil)
            } else {
                NotificationCenter.default.post(name: .reconcilerDidStop, object: nil)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init() {
        if Environment.isTesting() {
            return
        }
        listenForSessionChanges()
        listenForNotifications()
    }

    /// Tells the reconciler to check for inconsistencies between the file system
    /// and what is stored in core data.  If any are found they will be reconciled.
    ///
    func process() {
        processing = true
        guard hasInitializedSession() else {
            processing = false
            return
        }

        materializeShadows()

        guard hasInconsistencies() else {
            LogInfo(message: "No inconsistencies found.")
            processing = false
            return
        }

        reconcile()
    }

    /// Check for any shadow assets. If found, move the shared assets to the
    /// correct story folder.
    ///
    func materializeShadows() {
        let manager = ShadowManager()
        let assets = manager.retrieveShadowAssets()

        guard assets.count > 0 else {
            return
        }

        for asset in assets {
            materializeShadow(asset: asset)
        }

        /// Clean up group storage.
        manager.clearShadowAssets()
    }

    /// Attempt to copy the file referenced by the specified shadow asset to it's
    /// intended destination StoryFolder.
    ///
    /// - Parameter asset: A shadow asset
    ///
    func materializeShadow(asset: ShadowAsset) {
        let folderManager = SessionManager.shared.folderManager
        let store = StoreContainer.shared.folderStore

        guard
            let source = folderManager.urlFromBookmark(bookmark: asset.bookmarkData),
            let uuid = UUID(uuidString: asset.storyUUID),
            let story = store.getStoryFolderByID(uuid: uuid),
            let storyURL = folderManager.urlFromBookmark(bookmark: story.bookmark)
        else {
            return
        }

        let destination = FileManager.default.availableFileURL(for: source.lastPathComponent, isDirectory: false, relativeTo: storyURL)
        folderManager.moveItem(at: source, to: destination)
    }

    /// Checks for inconsistencies between the file system and what is stored in
    /// core data.
    ///
    /// - Returns: Returns true if any inconsistencies are found. False otherwise.
    ///
    func hasInconsistencies() -> Bool {
        // Check site
        let siteStore = StoreContainer.shared.siteStore
        if !siteStore.currentSiteFolderExists() {
            LogInfo(message: "Folder for current site is missing.")
            return true
        }

        // Check story folders
        if hasInconsistentStoryFolders() {
            LogInfo(message: "StoryFolders where missing, or new folders were found.")
            return true
        }

        let folderStore = StoreContainer.shared.folderStore
        let folders = folderStore.getStoryFolders()
        for folder in folders where hasInconsistentAssets(storyFolder: folder) {
            LogInfo(message: "StoryAssets where missing, or new assets were found for story: \(folder.name ?? "").")
            return true
        }

        return false
    }

    /// Reconciles any inconsistencies between the file system and what is stored
    /// in core data.
    ///
    func reconcile() {
        // reconcile site
        // if recreated we can bail
        let siteStore = StoreContainer.shared.siteStore
        if !siteStore.currentSiteFolderExists() {
            LogInfo(message: "Recreating folder for current site.")
            siteStore.createSiteFolderIfNeeded()
            processing = false
            return
        }

        // Manage the rest of the work with a dispatch group so we can notify when work is complete.
        let dispatchGroup = DispatchGroup()

        // Get story folder inconsistencies
        let (rawFolders, removedStories) = getInconsistentStoryFolders()
        let folderStore = StoreContainer.shared.folderStore
        if rawFolders.count > 0 {
            LogInfo(message: "Creating StoryFolders for \(rawFolders.count) discovered folders.")
            dispatchGroup.enter()
            folderStore.createStoryFoldersForURLs(urls: rawFolders, autoSyncAssets: false, onComplete: {
                dispatchGroup.leave()
            })
        }
        if removedStories.count > 0 {
            LogInfo(message: "Deleting StoryFolders for \(removedStories.count) missing folders.")
            dispatchGroup.enter()
            folderStore.deleteStoryFolders(folders: removedStories, onComplete: {
                dispatchGroup.leave()
            })
        }

        // Get asset inconsistencies.
        let folders = folderStore.getStoryFolders()
        for folder in folders {
            let (rawAssets, removedAssets) = getInconsistentAssets(storyFolder: folder)
            let assetStore = StoreContainer.shared.assetStore

            if rawAssets.count > 0 {
                LogInfo(message: "Creating StoryAssets for \(rawAssets.count) discovered items in story: \(folder.name ?? "").")
                dispatchGroup.enter()
                assetStore.createAssetsForURLs(urls: rawAssets, storyFolder: folder, onComplete: {
                    dispatchGroup.leave()
                })
            }
            if removedAssets.count > 0 {
                LogDebug(message: "Deleting StoryAssets for \(removedAssets.count) missing items in story: \(folder.name ?? "").")
                dispatchGroup.enter()
                assetStore.deleteAssets(assets: removedAssets, onComplete: {
                    dispatchGroup.leave()
                })
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.processing = false
        }
    }

    /// Check if there are any inconsistencies between the file system and
    /// story folders in core data.
    ///
    /// - Returns: true if there are inconsistencies, otherwise false.
    ///
    func hasInconsistentStoryFolders() -> Bool {
        let (rawFolders, removedStories) = getInconsistentStoryFolders()

        return rawFolders.count > 0 || removedStories.count > 0
    }

    /// Get any inconsistencies between the file system and story folders.
    ///
    /// - Returns: A tuple containing an array of file URLs that have no
    /// associated story, and an array of StoryFolders without a directory.
    ///
    func getInconsistentStoryFolders() -> ([URL], [StoryFolder]) {
        let store = StoreContainer.shared.folderStore
        let storyFolders = store.getStoryFolders()

        let siteStore = StoreContainer.shared.siteStore
        let siteFolderURL = siteStore.currentSiteFolderURL()!

        let folderManager = SessionManager.shared.folderManager
        var rawFolders = folderManager.enumerateFolders(url: siteFolderURL)

        var removedStories = [StoryFolder]()
        for story in storyFolders {
            var isStale = true
            guard let storyFolderURL = folderManager.urlFromBookmark(bookmark: story.bookmark, bookmarkIsStale: &isStale) else {
                removedStories.append(story)
                continue
            }
            if isStale || !folderManager.folder(siteFolderURL, isParentOf: storyFolderURL) {
                removedStories.append(story)
            }

            // Remove a good story folder's URL from the array of raw folders.
            // Whatever is left in raw folders will be URLs that need a story
            // folder created.
            rawFolders = rawFolders.filter { (url) -> Bool in
                guard
                    let urlRef = url.getFileReferenceURL(),
                    let storyRef = storyFolderURL.getFileReferenceURL()
                else {
                    // This probably shouldn't happen but keep the rawFolder URL
                    // if it does.
                    return true
                }
                // If the folders are equal we can filter out the raw folder.
                return !urlRef.isEqual(storyRef)
            }
        }

        return (rawFolders, removedStories)
    }

    /// Check if there are any inconsistencies with story assets.
    ///
    /// - Returns: True if there are inconsistencies, otherwise false.
    ///
    func hasInconsistentAssets(storyFolder: StoryFolder) -> Bool {
        let (rawAssets, removedAssets) = getInconsistentAssets(storyFolder: storyFolder)

        return rawAssets.count > 0 || removedAssets.count > 0
    }

    /// Get any inconsistencies between the file system and story assets for the
    /// specified story folder.
    ///
    /// - Returns: A tuple containing an array of file URLs that have no
    /// associated story, and an array of StoryAssets without a file system item.
    ///
    func getInconsistentAssets(storyFolder: StoryFolder) -> ([URL], [StoryAsset]) {
        var rawItems = [URL]()
        var removedAssets = [StoryAsset]()

        let store = StoreContainer.shared.assetStore
        let assets = store.getStoryAssets(storyFolder: storyFolder)

        let folderManager = SessionManager.shared.folderManager

        guard let storyFolderURL = folderManager.urlFromBookmark(bookmark: storyFolder.bookmark) else {
            return (rawItems, removedAssets)
        }

        rawItems = folderManager.enumerateFolderContents(url: storyFolderURL)

        // Filter out any items that are not supported types.
        rawItems = rawItems.filter({ (url) -> Bool in
            return store.isSupportedType(url: url)
        })

        for asset in assets {
            var isStale = false

            guard let bookmark = asset.bookmark else {
                // Some storyAsset's do not have bookmarks (e.g. TextNotes). In these
                // cases there is nothing to reconcile so just skip them.
                continue
            }

            guard let assetURL = folderManager.urlFromBookmark(bookmark: bookmark, bookmarkIsStale: &isStale) else {
                removedAssets.append(asset)
                continue
            }
            if isStale || !folderManager.folder(storyFolderURL, isParentOf: assetURL) {
                removedAssets.append(asset)
            }

            // Remove a good asset's URL from the array of raw items.
            // Whatever is left in raw items will be URLs that need an asset created.
            rawItems = rawItems.filter { (url) -> Bool in
                guard
                    let urlRef = url.getFileReferenceURL(),
                    let assetRef = assetURL.getFileReferenceURL()
                else {
                    // This probably shouldn't happen but keep the rawFolder URL
                    // if it does.
                    return true
                }
                // If the URLs are equal we can filter out the raw asset.
                return !urlRef.isEqual(assetRef)
            }
        }

        return (rawItems, removedAssets)
    }

}


// Notification related
//
extension Reconciler {

    /// Listen for system notifications that would tell us we might need to
    /// reconcile the file system and core data.
    /// Note that .didBecomeActiveNotification is dispatched more often than
    /// .willEnterForgroundNotification. If reconciliation is too frequent or
    /// aggressive we can try switching notifications.
    ///
    func listenForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc
    func handleDidBecomeActive(notification: Notification) {
        process()
    }

}


// Session related
//
extension Reconciler {

    func hasInitializedSession() -> Bool {
        let sessionState = SessionManager.shared.state
        return sessionState == .initialized
    }

    func listenForSessionChanges() {
        guard sessionReceipt == nil else {
            return
        }

        sessionReceipt = SessionManager.shared.onChange {
            self.handleSessionChange()
        }
    }

    func handleSessionChange() {
        process()
    }

}

extension Notification.Name {
    static let reconcilerDidStart = Notification.Name("ReconcilerDidStart")
    static let reconcilerDidStop = Notification.Name("ReconcilerDidStop")
}
