import Foundation
import CoreData


extension Status {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Status> {
        return NSFetchRequest<Status>(entityName: "Status")
    }

    @NSManaged public var name: String!
    @NSManaged public var isPrivate: Bool
    @NSManaged public var isProtected: Bool
    @NSManaged public var isPublic: Bool
    @NSManaged public var isQueryable: Bool
    @NSManaged public var show: Bool
    @NSManaged public var slug: String!

    @NSManaged public var site: Site!

}
