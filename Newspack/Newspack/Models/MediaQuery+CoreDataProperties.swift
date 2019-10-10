import Foundation
import CoreData


extension MediaQuery {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaQuery> {
        return NSFetchRequest<MediaQuery>(entityName: "MediaQuery")
    }

    @NSManaged public var title: String!
    @NSManaged public var hasMore: Bool
    @NSManaged public var lastSync: Date!
    @NSManaged public var uuid: UUID!
    @NSManaged public var filter: [String: AnyObject]!
    @NSManaged public var items: Set<MediaItem>!
    @NSManaged public var site: Site!

}

// MARK: Generated accessors for items
extension MediaQuery {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: MediaItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: MediaItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: Set<MediaItem>)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: Set<MediaItem>)

}
