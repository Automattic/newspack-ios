import Foundation
import CoreData


extension StoryAsset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryAsset> {
        return NSFetchRequest<StoryAsset>(entityName: "StoryAsset")
    }

    var assetType: StoryAssetType {
        get {
            return StoryAssetType(rawValue: type)!
        }
        set {
            type = newValue.rawValue
        }
    }

    @NSManaged private var type: String!
    @NSManaged public var bookmark: Data? // Text notes do not have local files. RemoteMedia may not have local files.
    @NSManaged public var name: String!
    @NSManaged public var uuid: UUID!
    @NSManaged public var flagToUpload: Bool
    @NSManaged public var date: Date! // The creation date.
    // Synced indicates the date last synced.
    @NSManaged public var synced: Date!
    // Modified indicate the date last modified. If synced > modified data is current.
    @NSManaged public var modified: Date!
    @NSManaged public var text: String!
    @NSManaged public var altText: String!
    @NSManaged public var caption: String!
    @NSManaged public var remoteID: Int64
    @NSManaged public var sourceURL: String!
    @NSManaged public var link: String!
    @NSManaged public var mimeType: String! // Default is application/octet-stream
    @NSManaged public var folder: StoryFolder!
}
