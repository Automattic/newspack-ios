import Foundation
import CoreData


extension AttachmentInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AttachmentInfo> {
        return NSFetchRequest<AttachmentInfo>(entityName: "AttachmentInfo")
    }

    @NSManaged public var attachmentID: Int64
    @NSManaged public var caption: String!
    @NSManaged public var altText: String!
    @NSManaged public var pageURL: URL?
    @NSManaged public var srcURL: URL?
    @NSManaged public var asset: StoryAsset!

}
