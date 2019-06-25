import Foundation

/// Sites endpoint wrangling
///
class SiteServiceRemote: ServiceRemoteCoreRest {

    /// Fetch all sites.
    /// There is not currently API to support a multisite install.
    /// This anticipates a time when there is.
    ///
    func fetchSitesForNetwork(accountUUID: UUID) {
        // When multisite is supported, we'll sync all sites and then filter
        // the ones that support Newspack.
        // For now, assume the network's URL is a single site and that it is a
        // Newspack site, i.e. we'll just fetch the current site.
        // TODO: Check for the Newspack plugin.
        fetchSiteSettings { (settings, error) in
            var sites: [RemoteSiteSettings]?
            if let site = settings {
                sites = [site]
            }
            self.dispatch(action: NetworkSitesFetchedApiAction(payload: sites, error: error, accountUUID: accountUUID))
        }
    }

    /// Fetches settings for the current account's current site.
    ///
    /// - Parameters:
    ///   - success: success description
    ///   - failure: failure description
    ///
    func fetchSiteSettings(accountUUID: UUID, siteUUID: UUID?) {
        fetchSiteSettings { (settings, error) in
            self.dispatch(action: SiteFetchedApiAction(payload: settings, error: error, accountUUID: accountUUID, siteUUID: siteUUID))
        }
    }

}

extension SiteServiceRemote {

    /// Internal API call. Does not dispatch.
    /// Fetches settings for the current account's current site.
    ///
    /// - Parameters:
    ///   - success: success description
    ///   - failure: failure description
    ///
    func fetchSiteSettings(onComplete: @escaping ((RemoteSiteSettings? , Error?) -> Void)) {
        api.GET("settings", parameters: nil, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let settings = RemoteSiteSettings(dict: dict)
            onComplete(settings, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            onComplete(nil, error)
        })
    }

}
