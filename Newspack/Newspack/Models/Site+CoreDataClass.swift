import Foundation
import CoreData

@objc(Site)
public class Site: NSManagedObject {

    /// Check for the specified capability.
    ///
    /// - Parameter string: The name of the capability to look for.
    /// - Returns: Returns true if the account has the specified capability.
    func hasCapability(string: String) -> Bool {
        if let cap = capabilities?.capabilities[string.lowercased()] {
            return cap
        }
        return false
    }


    /// Check if the specified role is included.
    ///
    /// - Parameter string: The role to look for.
    /// - Returns: True if the role was found, false otherwise.
    func hasRole(string: String) -> Bool {
        if let capabilities = capabilities {
            return capabilities.roles.contains(string.lowercased())
        }
        return false
    }
}
