import Foundation
import CoreData

@objc(AccountDetails)
public class AccountDetails: NSManagedObject {

    /// Get the URL to use for the account's avatar image.
    ///
    var avatarURL: URL? {
        guard let key = (avatarUrls.keys.max { (a, b) -> Bool in
            guard let aInt = Int(a), let bInt = Int(b) else {
                return false
            }
            return aInt < bInt
        }) else {
            return nil
        }

        guard
            let value = avatarUrls[key],
            let url = URL(string: value)
        else {
            return nil
        }
        return url
    }

    public override func willSave() {
        /// Prevent orphaned entities. If we ever save without a relationship
        /// to an account just delete.
        if account == nil && !isDeleted {
            managedObjectContext?.delete(self)
        }
    }
}
