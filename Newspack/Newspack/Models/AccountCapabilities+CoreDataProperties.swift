import Foundation
import CoreData


extension AccountCapabilities {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccountCapabilities> {
        return NSFetchRequest<AccountCapabilities>(entityName: "AccountCapabilities")
    }

    @NSManaged public var capabilities: [String: Bool]!
    @NSManaged public var roles: [String]!
    @NSManaged public var site: Site!

}
