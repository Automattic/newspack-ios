import Foundation
import CoreData

@objc(MediaItem)
public class MediaItem: NSManagedObject, MediaTypeDiscerner {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<MediaItem> {
        return NSFetchRequest<MediaItem>(entityName: "MediaItem")
    }

    /// Checks if the associated media is out of date.
    ///
    /// - Returns: True if the associated media is stale / out of date.
    ///
    func isStale() -> Bool {
        guard let m = media else {
            return true
        }
        return modifiedGMT.compare(m.modifiedGMT) != .orderedSame
    }
}
