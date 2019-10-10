import Foundation
import CoreData

@objc(MediaQuery)
public class MediaQuery: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<MediaQuery> {
        return NSFetchRequest<Media>(entityName: "MediaQuery")
    }

}
