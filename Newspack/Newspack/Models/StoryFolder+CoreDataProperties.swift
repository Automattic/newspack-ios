import Foundation
import CoreData


extension StoryFolder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryFolder> {
        return NSFetchRequest<StoryFolder>(entityName: "StoryFolder")
    }

    @NSManaged public var bookmark: Data!
    // postID is non-optional due to ObjC so we'll let its default be 0.
    // If postID is > 0 then there is a valid draft associated with the story.
    @NSManaged public var postID: Int64
    // Synced indicates the date last synced.
    @NSManaged public var synced: Date!
    // Modified indicate the date last modified. If synced > modified data is current.
    @NSManaged public var modified: Date!
    // The name of the folder cached for convenience. Used for the draft post title.
    @NSManaged public var name: String!
    @NSManaged public var assets: Set<StoryAsset>!
    @NSManaged public var site: Site!
    @NSManaged public var uuid: UUID!

}

// MARK: Generated accessors for assets
extension StoryFolder {

    @objc(addAssetsObject:)
    @NSManaged public func addToAssets(_ value: StoryAsset)

    @objc(removeAssetsObject:)
    @NSManaged public func removeFromAssets(_ value: StoryAsset)

    @objc(addAssets:)
    @NSManaged public func addToAssets(_ values: Set<StoryAsset>)

    @objc(removeAssets:)
    @NSManaged public func removeFromAssets(_ values: Set<StoryAsset>)

}
