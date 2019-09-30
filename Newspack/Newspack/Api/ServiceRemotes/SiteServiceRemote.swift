import Foundation

/// Sites endpoint wrangling
///
class SiteServiceRemote: ServiceRemoteCoreRest {

    /// Fetch all sites.
    /// There is not currently API to support a multisite install.
    /// This anticipates a time when there is.
    ///
    func fetchSitesForNetwork(_ onComplete: @escaping ([RemoteSiteSettings]? , Error?) -> Void) {
        // When multisite is supported, we'll sync all sites and then filter
        // the ones that support Newspack.
        // For now, assume the network's URL is a single site and that it is a
        // Newspack site, i.e. we'll just fetch the current site.
        // TODO: Check for the Newspack plugin.
        fetchSettings { (settings, error) in
            var sites: [RemoteSiteSettings]?
            if let site = settings {
                sites = [site]
            }
            onComplete(sites, error)
        }
    }

    /// Fetches settings for the current account's current site.
    ///
    func fetchSiteSettings(_ onComplete: @escaping (RemoteSiteSettings? , Error?) -> Void) {
        fetchSettings { (settings, error) in
            onComplete(settings, error)
        }
    }

}

extension SiteServiceRemote {

    /// Internal API call. Does not dispatch.
    /// Fetches settings for the current account's current site.
    ///
    /// - Parameter onComplete: Callback
    ///
    private func fetchSettings(onComplete: @escaping ((RemoteSiteSettings? , Error?) -> Void)) {
        api.GET("settings", parameters: nil, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let settings = RemoteSiteSettings(dict: dict)
            onComplete(settings, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            onComplete(nil, error)
        })
    }

}
