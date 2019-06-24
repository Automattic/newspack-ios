import Foundation

/// Sites endpoint wrangling
///
class SiteServiceRemote: ServiceRemoteCoreRest {

    /// Fetch all sites.
    /// There is not currently API to support a multisite install.
    /// This anticipates a time when there is.
    ///
    /// - Parameter onComplete: callback
    func fetchSitesForNetwork(onComplete: @escaping (([RemoteSiteSettings]?, NSError?) ->Void )) {
        // When multisite is supported, we'll sync all sites and thn filter
        // the ones that support Newspack.
        // For now, assume the network's URL is a single site and that it is a
        // Newspack site.
        // TODO: Check for the Newspack plugin.
        fetchSiteSettings(success: { (settings) in
            onComplete([settings], nil)
        }, failure: { (error) in
            onComplete(nil, error)
        })
    }

    /// Description
    ///
    /// - Parameters:
    ///   - success: success description
    ///   - failure: failure description
    ///
    func fetchSiteSettings(success: @escaping ((RemoteSiteSettings) -> Void), failure: @escaping ((NSError) -> Void)) {
        api.GET("settings", parameters: nil, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let settings = RemoteSiteSettings(dict: dict)
            success(settings)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            failure(error)
        })
    }

}
