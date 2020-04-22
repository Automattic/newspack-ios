import Foundation
import CoreData

@objc(StoryFolder)
public class StoryFolder: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<StoryFolder> {
        return NSFetchRequest<StoryFolder>(entityName: "StoryFolder")
    }

}
