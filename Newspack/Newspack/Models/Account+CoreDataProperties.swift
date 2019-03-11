import Foundation
import CoreData


extension Account {

    @NSManaged public var username: String?
    @NSManaged public var displayName: String?
    @NSManaged public var userID: Int64
    @NSManaged public var email: String?

}
