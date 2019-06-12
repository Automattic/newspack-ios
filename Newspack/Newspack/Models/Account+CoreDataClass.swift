import Foundation
import CoreData

@objc(Account)
public class Account: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

    /// Clean up before deleting the Account
    ///
    public override func prepareForDeletion() {
        UserDefaults.standard.removeObject(forKey: currentSiteKey)
    }

    /// Get or set the current site for the account. Defaults to first site if
    /// a current site has not previously been set.  If there are no sites
    /// it returns nil.
    ///
    /// - Returns: A site or nil
    ///
    var currentSite: Site? {
        get {
            if let url = UserDefaults.standard.string(forKey: currentSiteKey) {
                let filteredSites = sites.filter { site -> Bool in
                    return site.url == url
                }

                if let site = filteredSites.first {
                    return site
                }
            }

            if let site = sites.first {
                self.currentSite = site
            }

            return sites.first
        }
        set {
            guard let site = newValue else {
                UserDefaults.standard.removeObject(forKey: currentSiteKey)
                return
            }
            guard sites.contains(site) else {
                assertionFailure("The specified site does not belong to the account.")
                return
            }
            UserDefaults.standard.set(site.url, forKey: currentSiteKey)
        }
    }

    /// Returns the key used for the current site in UserDefaults
    ///
    private var currentSiteKey: String {
        return "CurrentSite-" + uuid.uuidString
    }

}
