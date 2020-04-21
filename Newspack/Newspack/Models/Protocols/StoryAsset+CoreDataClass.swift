import Foundation
import CoreData

@objc(StoryAsset)
public class StoryAsset: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<StoryAsset> {
        return NSFetchRequest<StoryAsset>(entityName: "StoryAsset")
    }

}
