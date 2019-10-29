import Foundation
import CoreData


extension Media {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Media> {
        return NSFetchRequest<Media>(entityName: "Media")
    }

    @NSManaged public var altText: String!
    @NSManaged public var authorID: Int64
    @NSManaged public var caption: String!
    @NSManaged public var captionRendered: String!
    @NSManaged public var commentStatus: String!
    @NSManaged public var date: String!
    @NSManaged public var dateGMT: Date!
    @NSManaged public var descript: String!
    @NSManaged public var descriptionRendered: String!
    @NSManaged public var details: [String: AnyObject]!
    @NSManaged public var generatedSlug: String!
    @NSManaged public var guid: String!
    @NSManaged public var guidRendered: String!
    @NSManaged public var link: String!
    @NSManaged public var mediaID: Int64
    @NSManaged public var mediaType: String!
    @NSManaged public var mimeType: String!
    @NSManaged public var modified: String!
    @NSManaged public var modifiedGMT: Date!
    @NSManaged public var permalinkTemplate: String!
    @NSManaged public var pingStatus: String!
    @NSManaged public var postID: Int64
    @NSManaged public var slug: String!
    @NSManaged public var source: String!
    @NSManaged public var status: String!
    @NSManaged public var template: String!
    @NSManaged public var title: String!
    @NSManaged public var titleRendered: String!
    @NSManaged public var type: String!

    @NSManaged public var site: Site!
    @NSManaged public var item: MediaItem!
    @NSManaged public var cached: MediaCache?

}
