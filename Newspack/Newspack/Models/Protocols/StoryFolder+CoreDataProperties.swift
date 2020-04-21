import Foundation
import CoreData


extension StoryFolder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryFolder> {
        return NSFetchRequest<StoryFolder>(entityName: "StoryFolder")
    }

    @NSManaged public var bookmark: Data?
    @NSManaged public var removed: Bool
    @NSManaged public var site: Site?
    @NSManaged public var assets: NSSet?

}

// MARK: Generated accessors for assets
extension StoryFolder {

    @objc(addAssetsObject:)
    @NSManaged public func addToAssets(_ value: StoryAsset)

    @objc(removeAssetsObject:)
    @NSManaged public func removeFromAssets(_ value: StoryAsset)

    @objc(addAssets:)
    @NSManaged public func addToAssets(_ values: NSSet)

    @objc(removeAssets:)
    @NSManaged public func removeFromAssets(_ values: NSSet)

}
