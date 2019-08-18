import Foundation
import CoreData

@objc(StagedEdits)
public class StagedEdits: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<StagedEdits> {
        return NSFetchRequest<StagedEdits>(entityName: "StagedEdits")
    }

}
