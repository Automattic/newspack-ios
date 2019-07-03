import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

}
