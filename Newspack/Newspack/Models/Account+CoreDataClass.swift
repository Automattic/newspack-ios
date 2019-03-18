import Foundation
import CoreData

@objc(Account)
public class Account: NSManagedObject {

    @nonobjc public class func accountFetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

}
