import Foundation
import CoreData

@objc(PostQuery)
public class PostQuery: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<PostQuery> {
        return NSFetchRequest<PostQuery>(entityName: "PostQuery")
    }

}
