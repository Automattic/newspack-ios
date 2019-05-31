import Foundation
import CoreData

@objc(AccountDetails)
public class AccountDetails: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<AccountDetails> {
        return NSFetchRequest<AccountDetails>(entityName: "AccountDetails")
    }

}
