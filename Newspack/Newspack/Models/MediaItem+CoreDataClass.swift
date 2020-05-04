import Foundation
import CoreData

@objc(MediaItem)
public class MediaItem: NSManagedObject, MediaTypeDiscerner {

    /// Checks if the associated media is out of date.
    ///
    /// - Returns: True if the associated media is stale / out of date.
    ///
    func isStale() -> Bool {
        guard
            let m = media,
            let _ = media.cached
        else {
            return true
        }
        return modifiedGMT.compare(m.modifiedGMT) != .orderedSame
    }
}
