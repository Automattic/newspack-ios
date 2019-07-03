import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var categoryID: Int64
    @NSManaged public var count: Int64
    @NSManaged public var descript: String!
    @NSManaged public var link: String!
    @NSManaged public var name: String!
    @NSManaged public var parentID: Int64
    @NSManaged public var slug: String!
    @NSManaged public var taxonomy: String!

    @NSManaged public var site: Site!

}
