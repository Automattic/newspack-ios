import Foundation
import CoreData

@objc(Status)
public class Status: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Status> {
        return NSFetchRequest<Status>(entityName: "Status")
    }

}
