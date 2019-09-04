import Foundation
import CoreData


extension StagedEdits {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StagedEdits> {
        return NSFetchRequest<StagedEdits>(entityName: "StagedEdits")
    }

    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var excerpt: String?
    @NSManaged public var lastModified: Date
    @NSManaged public var postListItem: PostListItem?

}
