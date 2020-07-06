import Foundation
import CoreData


extension StoryAsset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryAsset> {
        return NSFetchRequest<StoryAsset>(entityName: "StoryAsset")
    }

    @NSManaged public var assetType: String!
    @NSManaged public var bookmark: Data? // Text notes do not have local files. RemoteMedia may not have local files.
    @NSManaged public var name: String!
    @NSManaged public var uuid: UUID!
    @NSManaged public var order: Int16 // Default is 0
    @NSManaged public var date: Date!
    @NSManaged public var lastSync: Date?
    @NSManaged public var modified: Date?
    @NSManaged public var text: String?
    @NSManaged public var folder: StoryFolder!

}
