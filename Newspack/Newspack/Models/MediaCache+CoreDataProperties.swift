import Foundation
import CoreData


extension MediaCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaCache> {
        return NSFetchRequest<MediaCache>(entityName: "MediaCache")
    }

    @NSManaged public var sourceURL: String!
    @NSManaged public var data: Data!
    @NSManaged public var dateCached: Date!
    @NSManaged public var item: MediaItem?

}
