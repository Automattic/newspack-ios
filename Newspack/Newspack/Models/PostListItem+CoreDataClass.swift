import Foundation
import CoreData

@objc(PostListItem)
public class PostListItem: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<PostListItem> {
        return NSFetchRequest<PostListItem>(entityName: "PostListItem")
    }

}
