import Foundation
import CoreData


extension Account {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

    @NSManaged public var uuid: UUID!
    @NSManaged public var networkUrl: String!
    @NSManaged public var sites: Set<Site>!
    @NSManaged public var details: AccountDetails?

}

// MARK: Generated accessors for sites
extension Account {

    @objc(addSitesObject:)
    @NSManaged public func addToSites(_ value: Site)

    @objc(removeSitesObject:)
    @NSManaged public func removeFromSites(_ value: Site)

    @objc(addSites:)
    @NSManaged public func addToSites(_ values: Set<Site>)

    @objc(removeSites:)
    @NSManaged public func removeFromSites(_ values: Set<Site>)

}
