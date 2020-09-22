import Foundation

// This is a WIP Stub for syncing logic and may go away/evolve into something new as the functionality is refined.
class SyncManager {

    var isRunning = false

    var progressDictionary = [String: Any]()

    func process() {
        guard
            SessionManager.shared.state == .initialized,
            !isRunning
        else {
            return
        }
        isRunning = true

        // get stories that need drafts

        // get


    }

    // Sync the remote post backing stories.
    func syncRemoteStories() {
        /// Get a list of post IDs from our stories.  Sync the posts for these POST IDs.
        /// Fetch just the info/fields that we need.
        /// For any story whose post is published, scheduled, or trashed (missing) nuke/clean up the story.  This should allow for custom statuses in publish flows.

        let store = StoreContainer.shared.folderStore
        let postIDs = store.getStoryFolderPostIDs()

    }

    // Create remote drafts for any stories who are ready for a remote.
    func createRemoteStoriesIfNeeded() {
        /// retrieve stories that have at least one uploadable asset.
        /// create drafts for each and associate their post ID.
    }

    // Push changes to the story to the server.  This might be the title or a draft stub (if we support that)
    func pushStoriesIfNeeded() {
        ///
    }

    // sync remote asset info
    func syncRemoteAssets() {
        // for each story, sync it's remote assets
        // check for any that have been modified where we might need to reconcile the remote file
        // if an asset was deleted on the server, flag it locally to not sync but don't delete it.  Let the user manually delete or manually upload again. (move it into do not upload list)
    }

    // Upload assets that are stale or need to be uploaded.
    func pushAssetsIfNeeded() {
        // get assets that need uploading
        // record progress object in dictionary
        // upload individually
        // record IDs when finished
        // remove progress object from dictionary.  (maybe dispatch notification?)
    }


}
