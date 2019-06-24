import Foundation
import WordPressFlux

enum SiteApiAction: Action {
    case networkSitesFetched(sites: [RemoteSiteSettings]?, error: Error?)
    case siteFetched(site: RemoteSiteSettings?, error: Error?)
}
