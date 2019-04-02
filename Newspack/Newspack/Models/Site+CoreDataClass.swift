import Foundation
import CoreData

@objc(Site)
public class Site: NSManagedObject {

    @nonobjc public class func siteFetchRequest() -> NSFetchRequest<Site> {
        return NSFetchRequest<Site>(entityName: "Site")
    }

}
