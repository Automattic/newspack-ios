import Foundation
import CoreData

@objc(StagedMedia)
public class StagedMedia: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<StagedMedia> {
        return NSFetchRequest<StagedMedia>(entityName: "StagedMedia")
    }

}
