import Foundation
import CoreData

class StartupHelper {


    /// Resets flags related to syncing on the PostList and PostListItem models.
    ///
    static func resetSyncFlags() {
        let listRequest = NSBatchUpdateRequest(entityName: "PostList")
        listRequest.propertiesToUpdate = ["syncing": false, "hasMore": true]

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
