import Foundation
import CoreData

@objc(Post)
public class Post: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Post> {
        return NSFetchRequest<Post>(entityName: "Post")
    }

}
