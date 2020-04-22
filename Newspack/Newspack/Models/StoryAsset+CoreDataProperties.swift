import Foundation
import CoreData


extension StoryAsset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryAsset> {
        return NSFetchRequest<StoryAsset>(entityName: "StoryAsset")
    }

    @NSManaged public var bookmark: Data!
    @NSManaged public var removed: Bool
    @NSManaged public var assetType: String!
    @NSManaged public var folder: StoryFolder!

}
