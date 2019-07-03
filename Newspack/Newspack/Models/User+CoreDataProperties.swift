import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var avatarUrls: [String: String]!
    @NSManaged public var descript: String!
    @NSManaged public var link: String!
    @NSManaged public var name: String!
    @NSManaged public var slug: String!
    @NSManaged public var url: String!
    @NSManaged public var userID: Int64

    @NSManaged public var site: Site!

}
