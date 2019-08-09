import Foundation
import CoreData

@objc(Account)
public class Account: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

}
