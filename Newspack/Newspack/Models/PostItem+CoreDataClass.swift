import Foundation
import CoreData

@objc(PostItem)
public class PostItem: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<PostItem> {
        return NSFetchRequest<PostItem>(entityName: "PostItem")
    }

    public override func willSave() {
        /// Prevent orphaned entities. If we ever save without a relationship
        /// to a site just delete.
        if postQueries.count == 0 && !isDeleted {
            managedObjectContext?.delete(self)
        }
    }


    /// Checks if the associated posts is out of date.
    ///
    /// - Returns: True if the associated post is stale / out of date.
    ///
    func isStale() -> Bool {
        guard let p = post else {
            return true
        }
        return (revisionCount != p.revisionCount) || (modifiedGMT.compare(p.modifiedGMT) != .orderedSame)
    }

}
