import Foundation
import CoreData


extension AccountDetails {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccountDetails> {
        return NSFetchRequest<AccountDetails>(entityName: "AccountDetails")
    }

    @NSManaged public var userID: Int64
    @NSManaged public var name: String!
    @NSManaged public var firstName: String!
    @NSManaged public var lastName: String!
    @NSManaged public var nickname: String!
    @NSManaged public var email: String!
    @NSManaged public var avatarUrls: [String: String]!
    @NSManaged public var link: String!
    @NSManaged public var locale: String!
    @NSManaged public var slug: String!
    @NSManaged public var summary: String!
    @NSManaged public var url: String!
    @NSManaged public var username: String!
    @NSManaged public var registeredDate: String!
    @NSManaged public var account: Account!

}
