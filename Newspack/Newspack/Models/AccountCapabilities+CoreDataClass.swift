import Foundation
import CoreData

@objc(AccountCapabilities)
public class AccountCapabilities: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<AccountCapabilities> {
        return NSFetchRequest<AccountCapabilities>(entityName: "AccountCapabilities")
    }

    public override func willSave() {
        /// Prevent orphaned entities. If we ever save without a relationship
        /// to a site just delete.
        if site == nil && !isDeleted {
            managedObjectContext?.delete(self)
        }
    }
}
