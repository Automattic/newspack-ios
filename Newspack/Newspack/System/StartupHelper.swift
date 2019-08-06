import Foundation
import CoreData

/// A helper class for wrangling tasks that should happen whenever the app is
/// launched or a new session is started.
///
class StartupHelper {

    /// Resets flags related to syncing on the PostList and PostListItem models.
    ///
    static func resetSyncFlags() {
        let listRequest = NSBatchUpdateRequest(entityName: "PostList")
        listRequest.propertiesToUpdate = ["hasMore": true]

        let itemRequest = NSBatchUpdateRequest(entityName: "PostListItem")
        itemRequest.propertiesToUpdate = ["syncing": false]
        do {
            try CoreDataManager.shared.mainContext.execute(listRequest)
            try CoreDataManager.shared.mainContext.execute(itemRequest)
        } catch {
            // TODO: Log error
        }
    }

}
