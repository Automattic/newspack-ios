import Foundation
import CoreData

@objc(AccountCapabilities)
public class AccountCapabilities: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<AccountCapabilities> {
        return NSFetchRequest<AccountCapabilities>(entityName: "AccountCapabilities")
    }

}
