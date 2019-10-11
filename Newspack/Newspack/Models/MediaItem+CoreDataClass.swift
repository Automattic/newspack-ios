import Foundation
import CoreData

@objc(MediaItem)
public class MediaItem: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<MediaItem> {
        return NSFetchRequest<MediaItem>(entityName: "MediaItem")
    }

}
