import Foundation
import UIKit
import CoreData

@objc(MediaCache)
public class MediaCache: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<MediaCache> {
        return NSFetchRequest<MediaCache>(entityName: "MediaCache")
    }

    func image() -> UIImage? {
        guard let data = self.data else {
            return nil
        }
        return UIImage(data: data)
    }

}
