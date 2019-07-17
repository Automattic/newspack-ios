import Foundation
import CoreData

@objc(PostListItem)
public class PostListItem: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<PostListItem> {
        return NSFetchRequest<PostListItem>(entityName: "PostListItem")
    }

    public override func willSave() {
        /// Prevent orphaned entities. If we ever save without a relationship
        /// to a site just delete.
        if postLists.count == 0 && !isDeleted {
            managedObjectContext?.delete(self)
        }
    }
}
