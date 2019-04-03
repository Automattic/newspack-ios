import Foundation
import CoreData

@objc(Account)
public class Account: NSManagedObject {

    @nonobjc public class func accountFetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

    /// Get the current site for the account. Defaults to first site if
    /// a current site has not previously been set.  If there are no sites
    /// it returns nil.
    ///
    /// - Returns: A site or nil
    ///
    func currentSite() -> Site? {
        if let domain = UserDefaults.standard.string(forKey: currentSiteKey) {
            let filteredSites = sites.filter { (site) -> Bool in
                return site.domain == domain
            }

            if let site = filteredSites.first {
                return site
            }
        }

        if let site = sites.first {
            setCurrentSite(site)
        }

        return sites.first
    }

    /// Set the current site.
    ///
    /// - Parameter site: The site.
    ///
    func setCurrentSite(_ site: Site) {
        guard sites.contains(site) else {
            return
        }
        UserDefaults.standard.set(site.domain, forKey: currentSiteKey)
    }

    /// Returns the key used for the current site in UserDefaults
    ///
    private var currentSiteKey: String {
        return "CurrentSite-" + uuid.uuidString
    }

    /// Clean up before deleting the Account
    ///
    public override func prepareForDeletion() {
        UserDefaults.standard.removeObject(forKey: currentSiteKey)
    }

}
