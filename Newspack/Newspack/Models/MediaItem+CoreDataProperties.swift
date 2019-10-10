import Foundation
import CoreData


extension MediaItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaItem> {
        return NSFetchRequest<MediaItem>(entityName: "MediaItem")
    }

    @NSManaged public var mediaID: Int64
    @NSManaged public var dateGMT: Date!
    @NSManaged public var modifiedGMT: Date!
    @NSManaged public var details: [String: AnyObject]
    @NSManaged public var sourceURL: String!
    @NSManaged public var syncing: Bool
    @NSManaged public var queries: Set<MediaQuery>!
    @NSManaged public var site: Site!
    @NSManaged public var media: Media!

}

// MARK: Generated accessors for queries
extension MediaItem {

    @objc(addQueriesObject:)
    @NSManaged public func addToQueries(_ value: MediaQuery)

    @objc(removeQueriesObject:)
    @NSManaged public func removeFromQueries(_ value: MediaQuery)

    @objc(addQueries:)
    @NSManaged public func addToQueries(_ values: Set<MediaQuery>)

    @objc(removeQueries:)
    @NSManaged public func removeFromQueries(_ values: Set<MediaQuery>)

}
