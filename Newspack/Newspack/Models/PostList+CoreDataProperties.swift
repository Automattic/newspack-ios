import Foundation
import CoreData


extension PostList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostList> {
        return NSFetchRequest<PostList>(entityName: "PostList")
    }

    @NSManaged public var uuid: UUID!
    @NSManaged public var name: String!
    @NSManaged public var hasMore: Bool
    @NSManaged public var syncing: Bool
    @NSManaged public var lastSync: Date!
    @NSManaged public var filter: [String: AnyObject]!

    @NSManaged public var items: Set<PostListItem>!
    @NSManaged public var site: Site!

}


// MARK: Generated accessors for items
extension PostList {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: PostListItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: PostListItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: Set<PostListItem>)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: Set<PostListItem>)

}
