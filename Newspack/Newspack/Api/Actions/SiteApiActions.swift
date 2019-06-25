import Foundation
import WordPressFlux

struct NetworkSitesFetchedApiAction: ApiAction {
    var payload: [RemoteSiteSettings]?
    var error: Error?
    var accountUUID: UUID
}

struct SiteFetchedApiAction: ApiAction {
    var payload: RemoteSiteSettings?
    var error: Error?
    var accountUUID: UUID
    var siteUUID: UUID?
}
