import Foundation
import CoreData


extension PostItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostItem> {
        return NSFetchRequest<PostItem>(entityName: "PostItem")
    }

    @NSManaged public var postID: Int64
    @NSManaged public var dateGMT: Date!
    @NSManaged public var modifiedGMT: Date!
    @NSManaged public var revisionCount: Int16
    @NSManaged public var siteUUID: UUID!
    @NSManaged public var syncing: Bool

    @NSManaged public var post: Post!
    @NSManaged public var postQueries: Set<PostQuery>!
    @NSManaged public var stagedEdits: StagedEdits?

}

// MARK: Generated accessors for postList
extension PostItem {

    @objc(addPostQueriesObject:)
    @NSManaged public func addToPostQueries(_ value: PostQuery)

    @objc(removePostQueriesObject:)
    @NSManaged public func removeFromPostQueries(_ value: PostQuery)

    @objc(addPostQueries:)
    @NSManaged public func addToPostQueries(_ values: Set<PostQuery>)

    @objc(removePostQueries:)
    @NSManaged public func removeFromPostQueries(_ values: Set<PostQuery>)

}
