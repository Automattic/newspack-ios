import Foundation
import CoreData


extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var count: Int64
    @NSManaged public var descript: String!
    @NSManaged public var link: String!
    @NSManaged public var name: String!
    @NSManaged public var slug: String!
    @NSManaged public var tagID: Int64
    @NSManaged public var taxonomy: String!

    @NSManaged public var site: Site!

}
