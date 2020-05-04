import Foundation
import CoreData

@objc(AccountDetails)
public class AccountDetails: NSManagedObject {

    public override func willSave() {
        /// Prevent orphaned entities. If we ever save without a relationship
        /// to an account just delete.
        if account == nil && !isDeleted {
            managedObjectContext?.delete(self)
        }
    }
}
