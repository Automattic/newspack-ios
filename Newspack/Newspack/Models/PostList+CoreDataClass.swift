import Foundation
import CoreData

@objc(PostList)
public class PostList: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<PostList> {
        return NSFetchRequest<PostList>(entityName: "PostList")
    }

}
