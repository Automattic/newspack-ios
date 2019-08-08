import Foundation
import WordPressFlux

struct NetworkSitesFetchedApiAction: ApiAction {
    var payload: [RemoteSiteSettings]?
    var error: Error?
}

struct SiteFetchedApiAction: ApiAction {
    var payload: RemoteSiteSettings?
    var error: Error?
}
