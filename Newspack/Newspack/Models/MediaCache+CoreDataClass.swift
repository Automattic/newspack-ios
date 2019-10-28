import Foundation
import CoreData

@objc(MediaCache)
public class MediaCache: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<MediaCache> {
        return NSFetchRequest<MediaCache>(entityName: "MediaCache")
    }

}
