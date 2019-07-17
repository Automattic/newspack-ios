import Foundation
import CoreData

@objc(Post)
public class Post: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Post> {
        return NSFetchRequest<Post>(entityName: "Post")
    }

    public override func willSave() {
        /// Prevent orphaned entities. If we ever save without a relationship
        /// to a PostListItem just delete.
        if items.count == 0 && !isDeleted {
            managedObjectContext?.delete(self)
        }
    }
}
