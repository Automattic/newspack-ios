import Foundation
import CoreData

@objc(Tag)
public class Tag: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

}
