import Foundation
import CoreData

@objc(Page)
public class Page: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Page> {
        return NSFetchRequest<Page>(entityName: "Page")
    }

}
