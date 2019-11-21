import Foundation
import CoreData


extension StagedMedia {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StagedMedia> {
        return NSFetchRequest<StagedMedia>(entityName: "StagedMedia")
    }

    @NSManaged public var uuid: UUID!
    @NSManaged public var localFilePath: String?
    @NSManaged public var assetIdentifier: String?
    @NSManaged public var mediaType: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var title: String?
    @NSManaged public var altText: String?
    @NSManaged public var caption: String?
    @NSManaged public var originalFileName: String?
    @NSManaged public var site: Site!

}
