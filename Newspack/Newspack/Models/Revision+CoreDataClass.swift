import Foundation
import CoreData

@objc(Revision)
public class Revision: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Revision> {
        return NSFetchRequest<Revision>(entityName: "Revision")
    }

}
