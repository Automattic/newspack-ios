import Foundation
import CoreData


extension PostQuery {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostQuery> {
        return NSFetchRequest<PostQuery>(entityName: "PostQuery")
    }

    @NSManaged public var uuid: UUID!
    @NSManaged public var name: String!
    @NSManaged public var hasMore: Bool
    @NSManaged public var lastSync: Date!
    @NSManaged public var filter: [String: AnyObject]!

    @NSManaged public var items: Set<PostItem>!
    @NSManaged public var site: Site!

}


// MARK: Generated accessors for items
extension PostQuery {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: PostItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: PostItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: Set<PostItem>)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: Set<PostItem>)

}
