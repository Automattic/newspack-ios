import Foundation
import UIKit

/// Responsible for resolving any differences between what is currently in the
/// file system with what is currently stored in core data.
///
class Reconciler {

    private var sessionReceipt: Any?

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
        guard hasInitializedSession() else {
            return
        }

        guard hasInconsistencies() else {
            return
        }

        reconcile()
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
            LogDebug(message: "Folder for current site is missing.")
            return true
        }

        // Check story folders
        if hasInconsistentStoryFolders() {
            LogDebug(message: "StoryFolders where missing, or new folders were found.")
            return true
        }

        // TODO: check story folder contents

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
            LogDebug(message: "Recreating folder for current site.")
            siteStore.createSiteFolderIfNeeded()
            return
        }

        // Get story folder inconsistencies
        let (rawFolders, removedStories) = getInconsistentStoryFolders()
        let folderStore = StoreContainer.shared.folderStore
        LogDebug(message: "Creating StoryFolders for discovered folders.")
        folderStore.createStoryFoldersForURLs(urls: rawFolders)
        LogDebug(message: "Deleting StoryFolders for missing folders.")
        folderStore.deleteStoryFolders(folders: removedStories)

        // TODO: check folder contents
    }

    /// Check if there are any inconsistencies between the file system and
    /// story folders in core data.
    /// - Returns: true if there are inconsistencies, otherwise false.
    ///
    func hasInconsistentStoryFolders() -> Bool {
        let (rawFolders, removedStories) = getInconsistentStoryFolders()

        return rawFolders.count > 0 || removedStories.count > 0
    }

    /// Get any inconsistencies between the file system and story folders.
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
