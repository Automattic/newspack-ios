import Foundation
import CoreData


extension Site {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Site> {
        return NSFetchRequest<Site>(entityName: "Site")
    }

    @NSManaged public var url: String!
    @NSManaged public var title: String!
    @NSManaged public var summary: String!
    @NSManaged public var timezone: String!
    @NSManaged public var dateFormat: String!
    @NSManaged public var timeFormat: String!
    @NSManaged public var startOfWeek: String!
    @NSManaged public var language: String!
    @NSManaged public var useSmilies: Bool
    @NSManaged public var defaultCategory: Int64
    @NSManaged public var defaultPostFormat: Int64
    @NSManaged public var postsPerPage: Int64
    @NSManaged public var defaultPingStatus: String!
    @NSManaged public var defaultCommentStatus: String!

    @NSManaged public var account: Account!
    @NSManaged public var capabilities: AccountCapabilities?
    @NSManaged public var posts: Set<Post>!
}



// MARK: Generated accessors for posts
extension Site {

    @objc(addPostsObject:)
    @NSManaged public func addToPosts(_ value: Post)

    @objc(removePostsObject:)
    @NSManaged public func removeFromPosts(_ value: Post)

    @objc(addPosts:)
    @NSManaged public func addToPosts(_ values: NSSet)

    @objc(removePosts:)
    @NSManaged public func removeFromPosts(_ values: NSSet)

}

