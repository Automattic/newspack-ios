import Foundation
import CoreData


extension Revision {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Revision> {
        return NSFetchRequest<Revision>(entityName: "Revision")
    }

    @NSManaged public var authorID: Int64
    @NSManaged public var content: String!
    @NSManaged public var contentRendered: String!
    @NSManaged public var date: String!
    @NSManaged public var dateGMT: Date!
    @NSManaged public var excerpt: String!
    @NSManaged public var excerptRendered: String!
    @NSManaged public var modified: String!
    @NSManaged public var modifiedGMT: Date!
    @NSManaged public var parentID: Int64
    @NSManaged public var revisionID: Int64
    @NSManaged public var slug: String!
    @NSManaged public var title: String!
    @NSManaged public var titleRendered: String!

    @NSManaged public var post: Post!

}
