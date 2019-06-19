import Foundation

enum AccountSetupErrors: Error {
    case noValidSitesFound
}

class AccountSetupHelper {

    typealias CompletionHandler = ((NSError?) -> Void)

    private var completionHandler: CompletionHandler?
    private var validSites = [RemoteSiteSettings]()
    private let token: String
    private let network: String

    deinit {
        // TODO: remove this after confirming de initialization when finished.
        print("Network Service Remote: deinit")
    }

    init(token: String, network: String) {
        self.token = token
        self.network = network
    }

    /// Currently the core WordPress REST API is lacking a way to detect a multisite
    /// installation, but we anticipate a time when such an API exists.
    ///
    /// Until then we assume networks are single sites.
    ///
    /// - Parameter onComplete: callback
    func configure(onComplete: @escaping CompletionHandler) {
        completionHandler = onComplete

        let api = WordPressCoreRestApi(oAuthToken: token, userAgent: UserAgent.defaultUserAgent, site: network)
        let remote = SiteServiceRemote(wordPressComRestApi: api)
        remote.fetchSiteSettings(success: { (settings) in

            self.validateNewspackSites([settings])

        }, failure: { (error) in
            // TODO: Custom errors?  Regardless, need to log the ones from the network.
            self.completionHandler?(error)
        })
    }

    /// Check sites to see if they are newspack sites.
    ///
    /// - Parameters:
    ///   - sites: An array of RemoteSiteSettings objects.
    ///   - onComplete: Completion handler.
    func validateNewspackSites(_ sites: [RemoteSiteSettings]) {
        // TODO: Log validating sites
        // Assume we will have an API request to make for each site.
        let asyncGroup = DispatchGroup()
        for site in sites {
            asyncGroup.enter()
            validateNewspackSite(site) { (theSite, valid) in
                if valid {
                    self.validSites.append(site)
                }
                asyncGroup.leave()
            }
        }

        // Call completion when finished.
        asyncGroup.notify(queue: DispatchQueue.main) {
            self.validationComplete(sites: self.validSites)
        }
    }

    /// Check for a Newspack site.
    ///
    /// - Parameters:
    ///   - settings: An instance of RemoteSiteSettings
    ///   - onComplete: Completion callback. Returns the settings object and whether it is a newspack site.
    ///
    func validateNewspackSite(_ settings: RemoteSiteSettings, onComplete: @escaping (RemoteSiteSettings, Bool)->Void ) {
        // TODO: Log validating site.
        // Assumes there is an API request to check. For now just assume true.
        onComplete(settings, true)
    }

    /// When finished validating, setup the account and sites (if no error) and
    /// call the stored completion block.
    ///
    /// - Parameters:
    ///   - sites:
    ///   - error:
    func validationComplete(sites: [RemoteSiteSettings]) {
        // TODO: Log validation complete.

        guard sites.count > 0 else {
            let error = AccountSetupErrors.noValidSitesFound as NSError
            completionHandler?(error)
            return
        }

        let accountStore = StoreContainer.shared.accountStore
        let account = accountStore.createAccount(authToken: token, forNetworkAt: network)

        let siteStore = StoreContainer.shared.siteStore
        for site in sites {
            // TODO: URL should come from settings when we have actual multisite support.
            // For now just use network.
            siteStore.createSite(url: network, settings: site, accountID: account.uuid)
        }
        accountStore.setCurrentAccount(account: account)

        completionHandler?(nil)
    }

}
