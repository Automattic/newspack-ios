import Foundation
import CoreData


extension Page {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Page> {
        return NSFetchRequest<Page>(entityName: "Page")
    }

    @NSManaged public var authorID: Int64
    @NSManaged public var commentStatus: String!
    @NSManaged public var content: String!
    @NSManaged public var contentRendered: String!
    @NSManaged public var date: String!
    @NSManaged public var dateGMT: String!
    @NSManaged public var excerpt: String!
    @NSManaged public var excerptRendered: String!
    @NSManaged public var featuredMedia: Int64
    @NSManaged public var generatedSlug: String!
    @NSManaged public var guid: String!
    @NSManaged public var guidRendered: String!
    @NSManaged public var link: String!
    @NSManaged public var menuOrder: Int64
    @NSManaged public var modified: String!
    @NSManaged public var modifiedGMT: String!
    @NSManaged public var pageID: Int64
    @NSManaged public var parentID: Int64
    @NSManaged public var password: String!
    @NSManaged public var permalinkTemplate: String!
    @NSManaged public var pingStatus: String!
    @NSManaged public var slug: String!
    @NSManaged public var status: String!
    @NSManaged public var template: String!
    @NSManaged public var title: String!
    @NSManaged public var titleRendered: String!
    @NSManaged public var type: String!

    @NSManaged public var site: Site!

}
